import time
import logging
import asyncio
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy import select, delete

from core.connection import manager
from core.database import AsyncSessionLocal
from core.game_engine import engine
from models.room import Room, RoomStatus
from models.user import User
from models.title import Title

router = APIRouter(prefix="/game", tags=["Game"])
logger = logging.getLogger(__name__)

# ─── Broadcast helpers ────────────────────────────────────────────────────────

async def broadcast_state(room_id: str):
    state = engine.get_state(room_id)
    await manager.broadcast_to_room(room_id, {
        "event": "STATE_UPDATE",
        "state": state,
    })

async def broadcast_players(room_id: str):
    async with AsyncSessionLocal() as db:
        users_res = await db.execute(select(User).where(User.room_id == room_id))
        users = users_res.scalars().all()
        players_data = [
            {"id": str(u.id), "name": u.name, "color": u.color,
             "is_connected": u.is_connected, "score": u.score}
            for u in users
        ]
        # Only connected users count as active game players
        connected_ids = [str(u.id) for u in users if u.is_connected]

    engine.update_players(room_id, connected_ids)

    await manager.broadcast_to_room(room_id, {
        "event": "PLAYERS_UPDATED",
        "players": players_data,
    })

# ─── BUG-1: Guarded voting timer ──────────────────────────────────────────────

async def start_voting_timer(room_id: str, voting_id: str, timer_duration: int):
    """
    BUG-1 fix: the timer carries a snapshot of `voting_id`.
    When it wakes up it checks whether the game is still on that exact vote.
    If a new round started, voting_id will have changed and this timer exits silently.
    """
    async def _timer():
        await asyncio.sleep(timer_duration)
        current_state = engine.get_state(room_id)
        if not current_state:
            return
        if current_state.get("voting_id") != voting_id:
            logger.debug(f"Zombie voting timer expired for old voting_id in room {room_id}. Ignored.")
            return
        if current_state.get("phase") != "VOTING":
            return
        logger.info(f"Voting timer expired for room {room_id}. Forcing results.")
        engine.force_finish_voting(room_id)
        await broadcast_state(room_id)
        await process_round_results(room_id)

    asyncio.create_task(_timer())

# ─── BUG-15: Guarded selection timer (AFK assigner) ──────────────────────────

async def start_selection_timer(room_id: str):
    """
    BUG-15 fix: 60-second idle timer for TITLE_SELECTION phase.
    If the assigner goes AFK, auto-pick a random title and continue.
    Uses selection_timer_id to avoid acting on stale timers.
    """
    state = engine.get_state(room_id)
    if not state:
        return

    selection_timer_id = state.get("selection_timer_id")
    if not selection_timer_id:
        return

    async def _timer():
        await asyncio.sleep(30)
        current_state = engine.get_state(room_id)
        if not current_state:
            return
        if current_state.get("selection_timer_id") != selection_timer_id:
            return  # Timer was superseded (new assigner picked, or player disconnected)
        if current_state.get("phase") != "TITLE_SELECTION":
            return

        assigner_id = current_state.get("assigner_id", "")
        logger.info(f"Assigner {assigner_id} went AFK in room {room_id}. Auto-picking title.")

        chosen_title = engine.auto_select_title(room_id)
        if not chosen_title:
            logger.error(f"No titles available to auto-pick in room {room_id}")
            return

        await manager.broadcast_to_room(room_id, {
            "event": "PLAYER_SKIPPED",
            "user_id": assigner_id,
            "message": "Took too long — a random title was picked!",
        })

        timer_duration = current_state.get("timer", 30)
        voting_id = engine.select_title(room_id, chosen_title)
        engine.games[room_id]["voting_ends_at"] = time.time() + timer_duration

        await broadcast_state(room_id)
        await start_voting_timer(room_id, voting_id, timer_duration)

    asyncio.create_task(_timer())

# ─── Round results + auto-advance ─────────────────────────────────────────────

async def process_round_results(room_id: str):
    results = engine.calculate_results(room_id)
    target_id       = results.get("target_id")
    assigner_id     = results.get("assigner_id")
    missed_voters   = results.get("missed_voters", [])
    missed_penalty  = results.get("missed_penalty", 0)

    async with AsyncSessionLocal() as db:
        users_res = await db.execute(select(User).where(User.room_id == room_id))
        users = users_res.scalars().all()
        for u in users:
            uid = str(u.id)
            if uid == target_id:
                u.score = (u.score or 0) + results.get("target_points", 0)
            if uid == assigner_id:
                u.score = (u.score or 0) + results.get("assigner_points", 0)
            if uid in missed_voters:
                u.score = (u.score or 0) + missed_penalty
        await db.commit()

    await broadcast_players(room_id)
    # NEW: Broadcast the state IMMEDIATELY so the frontend gets the new last_results
    await broadcast_state(room_id)

    # MISSING-3: Send full results payload so frontend can show turn summary
    await manager.broadcast_to_room(room_id, {
        "event": "ROUND_RESULTS_COMPLETED",
        "results": results,
    })

    # Auto-advance to next turn after 8s
    async def _next_round_task():
        await asyncio.sleep(8)
        has_next = engine.next_round(room_id)
        await broadcast_state(room_id)

        if has_next:
            await asyncio.sleep(3)
            assigner = engine.select_assigner(room_id)
            await broadcast_state(room_id)

            if assigner is None:
                logger.error(f"No assigner available after next_round in room {room_id}")
                return

            await asyncio.sleep(3)
            engine.select_target(room_id)
            await broadcast_state(room_id)

            await start_selection_timer(room_id)

    asyncio.create_task(_next_round_task())

# ─── Shared utility: advance from TITLE_SELECTION to next assigner or end ─────

async def _advance_from_title_selection(room_id: str):
    """
    Used after assigner disconnect (BUG-3) or after all assigners done.
    Checks if there are more assigners left in this round; if yes, picks next.
    If no, calls next_round.
    """
    current_state = engine.get_state(room_id)
    if not current_state:
        return

    players  = current_state.get("players", [])
    assigned = current_state.get("assigned_this_round", [])
    has_more = any(p not in assigned for p in players)

    if has_more:
        engine.games[room_id]["phase"] = "SELECTING_ASSIGNER"
        await broadcast_state(room_id)
        await asyncio.sleep(3)
        engine.select_assigner(room_id)
        await broadcast_state(room_id)
        await asyncio.sleep(3)
        engine.select_target(room_id)
        await broadcast_state(room_id)
        await start_selection_timer(room_id)
    else:
        # Treat as if voting finished with no votes
        engine.force_finish_voting(room_id)
        await broadcast_state(room_id)
        await process_round_results(room_id)

# ─── Action handlers ──────────────────────────────────────────────────────────

async def handle_submit_title(data: dict, room_id: str, user_id: str):
    title_text = data.get("title", "").strip()
    if not title_text:
        return

    result = engine.submit_title(room_id, user_id, title_text)

    if not result.get("success"):
        # Send error only to the sender
        conns = manager.active_connections.get(room_id, {})
        if user_id in conns:
            await conns[user_id].send_json({
                "event": "ERROR",
                "message": result.get("error", "Could not submit title"),
            })
        return

    # Persist to DB
    async with AsyncSessionLocal() as db:
        db.add(Title(room_id=room_id, author_id=user_id, text=title_text))
        await db.commit()

    await manager.broadcast_to_room(room_id, {
        "event": "TITLE_ADDED",
        "user_id": user_id,
    })
    await broadcast_state(room_id)


async def handle_start_round(data: dict, room_id: str, user_id: str, force: bool = False):
    """
    BUG-6: Server-side guard — all connected players must have submitted at least 1 title,
    unless `force=True` (FORCE_START, BUG-16) where simple majority is enough.
    """
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()

    if not room or str(room.host_id) != user_id:
        return

    state = engine.get_state(room_id)
    if not state:
        return

    titles           = state.get("titles", [])
    players          = state.get("players", [])
    unique_submitters = len(set(t["author_id"] for t in titles))
    total_connected   = len(players)

    conns = manager.active_connections.get(room_id, {})

    if not force:
        # BUG-6: Strict guard
        if unique_submitters < total_connected:
            if user_id in conns:
                await conns[user_id].send_json({
                    "event": "ERROR",
                    "message": f"Not all players have submitted ({unique_submitters}/{total_connected})",
                })
            return
    else:
        # BUG-16: Force start — need at least simple majority
        majority = (total_connected // 2) + 1
        if unique_submitters < majority:
            if user_id in conns:
                await conns[user_id].send_json({
                    "event": "ERROR",
                    "message": f"Need at least {majority} submissions to force start",
                })
            return
        # Exclude non-submitters from being assigner this round
        submitter_ids = set(t["author_id"] for t in titles)
        non_submitters = [p for p in players if p not in submitter_ids]
        if non_submitters:
            engine.games[room_id]["assigned_this_round"].extend(non_submitters)

    async def _pick_roles_task():
        engine.games[room_id]["phase"] = "SELECTING_ASSIGNER"
        await broadcast_state(room_id)

        await asyncio.sleep(3)
        assigner = engine.select_assigner(room_id)
        await broadcast_state(room_id)

        if assigner is None:
            return

        await asyncio.sleep(3)
        engine.select_target(room_id)
        await broadcast_state(room_id)

        # BUG-15: Start idle timer for assigner
        await start_selection_timer(room_id)

    asyncio.create_task(_pick_roles_task())


async def handle_assign_title(data: dict, room_id: str, user_id: str):
    title = data.get("title", "").strip()
    if not title:
        return

    state = engine.get_state(room_id)
    if not state or state.get("phase") != "TITLE_SELECTION":
        return

    # Only the current assigner can assign a title
    if state.get("assigner_id") != user_id:
        return

    timer_duration = state.get("timer", 30)
    voting_id = engine.select_title(room_id, title)
    engine.games[room_id]["voting_ends_at"] = time.time() + timer_duration

    await broadcast_state(room_id)
    # BUG-1: Start guarded voting timer
    await start_voting_timer(room_id, voting_id, timer_duration)


async def handle_vote(data: dict, room_id: str, user_id: str):
    vote = data.get("vote")
    if vote is None:
        return

    all_voted = engine.submit_vote(room_id, user_id, vote)
    await broadcast_state(room_id)

    if all_voted:
        await process_round_results(room_id)


async def handle_start_game(data: dict, room_id: str, user_id: str):
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()

        if not room or str(room.host_id) != user_id:
            return

        room.status = RoomStatus.PLAYING
        room.current_round = 1
        max_rounds    = room.rounds
        timer_duration = room.timer
        secret_mode   = room.secret_mode

        users_res = await db.execute(
            select(User).where(User.room_id == room_id, User.is_connected == True)
        )
        users = users_res.scalars().all()
        user_ids = [str(u.id) for u in users]

        if len(user_ids) < 3:
            conns = manager.active_connections.get(room_id, {})
            if user_id in conns:
                await conns[user_id].send_json({
                    "event": "ERROR",
                    "message": "Need at least 3 connected players to start",
                })
            return

        await db.commit()

    engine.init_game(room_id, user_ids, max_rounds=max_rounds,
                     timer=timer_duration, secret_mode=secret_mode)

    # BUG-12: Include secret_mode in GAME_STARTED so all clients know
    await manager.broadcast_to_room(room_id, {
        "event": "GAME_STARTED",
        "secret_mode": secret_mode,
        "rounds": max_rounds,
    })
    await broadcast_state(room_id)


async def handle_reset_game(data: dict, room_id: str, user_id: str):
    """MISSING-1: Play Again — host resets game for a rematch."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()

        if not room or str(room.host_id) != user_id:
            return

        # Reset scores in DB
        users_res = await db.execute(select(User).where(User.room_id == room_id))
        for u in users_res.scalars().all():
            u.score = 0

        # Clear all titles from DB
        await db.execute(delete(Title).where(Title.room_id == room_id))
        await db.commit()

    engine.reset_game(room_id)

    await manager.broadcast_to_room(room_id, {"event": "GAME_RESET"})
    await broadcast_state(room_id)


# ─── BUG-2 & BUG-3: Handle player disconnect ─────────────────────────────────

async def handle_disconnect(room_id: str, user_id: str):
    """
    Called when a WebSocket connection drops.
    - Marks player as disconnected in DB.
    - Removes them from the in-memory game (BUG-2).
    - If they were the assigner, skips their turn immediately (BUG-3).
    - If too few players remain (<3), aborts game (BUG-4).
    - If they were a voter, checks if voting is now complete.
    """
    # 1. Update DB
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user:
            user.is_connected = False
            await db.commit()

    state = engine.get_state(room_id)
    safe_phases = {"TITLE_CREATION", "SELECTING_ASSIGNER", "SELECTING_TARGET", "GAME_OVER", ""}

    if state and state.get("phase") not in safe_phases:
        # Game is in a live phase — remove player and react
        removal = engine.remove_player(room_id, user_id)
        remaining = removal.get("remaining_players", 0)

        if not removal.get("removed"):
            # Player wasn't in the engine list (e.g. they never connected to a live game)
            pass
        elif remaining < 3:
            # BUG-4: Not enough players — abort
            logger.warning(f"Room {room_id}: only {remaining} players left — aborting game.")
            engine.games[room_id]["phase"] = "GAME_OVER"
            await manager.broadcast_to_room(room_id, {
                "event": "GAME_ABORTED",
                "message": "A player left. Not enough players to continue.",
            })
            await broadcast_state(room_id)
        else:
            phase = state.get("phase")

            if removal.get("was_assigner") and phase == "TITLE_SELECTION":
                # BUG-3: Assigner disconnected — skip their turn
                logger.info(f"Assigner {user_id} disconnected from room {room_id}. Skipping turn.")
                await manager.broadcast_to_room(room_id, {
                    "event": "PLAYER_LEFT",
                    "user_id": user_id,
                    "message": "The assigner left — skipping their turn.",
                })
                asyncio.create_task(_advance_from_title_selection(room_id))
                await broadcast_players(room_id)
                return  # Return early — broadcast_players already done

            elif phase == "VOTING":
                # A voter (or target, or assigner) disconnected during voting
                # Recalculate whether voting is now complete with fewer eligible voters
                await broadcast_state(room_id)
                updated = engine.get_state(room_id)
                assigner_id = updated.get("assigner_id")
                target_id   = updated.get("target_id")
                eligible    = [p for p in updated.get("players", []) if p not in (assigner_id, target_id)]
                votes_cast  = updated.get("votes", {})
                if eligible and len(votes_cast) >= len(eligible):
                    engine.force_finish_voting(room_id)
                    await broadcast_state(room_id)
                    await process_round_results(room_id)

    # Always broadcast the updated player list
    await manager.broadcast_to_room(room_id, {
        "event": "PLAYER_LEFT",
        "user_id": user_id,
    })
    await broadcast_players(room_id)


# ─── WebSocket endpoint ───────────────────────────────────────────────────────

@router.websocket("/ws/{room_id}/{user_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str, user_id: str):
    await manager.connect(websocket, room_id, user_id)

    # Mark connected in DB
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user:
            user.is_connected = True
            await db.commit()

    await manager.broadcast_to_room(room_id, {
        "event": "PLAYER_JOINED",
        "user_id": user_id,
    })
    await broadcast_players(room_id)

    # Send current game state to reconnecting client
    state = engine.get_state(room_id)
    if state:
        await websocket.send_json({"event": "STATE_UPDATE", "state": state})

    try:
        while True:
            data   = await websocket.receive_json()
            action = data.get("action")

            if action == "SUBMIT_TITLE":
                await handle_submit_title(data, room_id, user_id)
            elif action == "START_ROUND":
                await handle_start_round(data, room_id, user_id, force=False)
            elif action == "FORCE_START":
                # BUG-16: Host force-starts when someone is AFK during title creation
                await handle_start_round(data, room_id, user_id, force=True)
            elif action == "START_GAME":
                await handle_start_game(data, room_id, user_id)
            elif action == "ASSIGN_TITLE":
                await handle_assign_title(data, room_id, user_id)
            elif action == "VOTE":
                await handle_vote(data, room_id, user_id)
            elif action == "RESET_GAME":
                # MISSING-1: Play Again
                await handle_reset_game(data, room_id, user_id)
            elif action == "TYPING":
                await manager.broadcast_to_room(room_id, {
                    "event": "PLAYER_TYPING",
                    "user_id": user_id,
                    "is_typing": data.get("is_typing", False),
                })

    except WebSocketDisconnect:
        manager.disconnect(room_id, user_id)
        await handle_disconnect(room_id, user_id)

    except Exception as e:
        logger.error(f"WebSocket error for user {user_id} in room {room_id}: {e}")
        manager.disconnect(room_id, user_id)
        await handle_disconnect(room_id, user_id)
