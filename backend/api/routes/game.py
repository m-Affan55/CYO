import json
import logging
import asyncio
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy import select

from core.connection import manager
from core.database import AsyncSessionLocal
from core.game_engine import engine
from models.room import Room, RoomStatus
from models.user import User
from models.title import Title

router = APIRouter(prefix="/game", tags=["Game"])
logger = logging.getLogger(__name__)

async def broadcast_state(room_id: str):
    state = engine.get_state(room_id)
    await manager.broadcast_to_room(room_id, {
        "event": "STATE_UPDATE",
        "state": state
    })

async def broadcast_players(room_id: str):
    async with AsyncSessionLocal() as db:
        users_res = await db.execute(select(User).where(User.room_id == room_id))
        users = users_res.scalars().all()
        players_data = [{"id": str(u.id), "name": u.name, "color": u.color, "is_connected": u.is_connected, "score": u.score} for u in users]
        user_ids = [str(u.id) for u in users]
        
    engine.update_players(room_id, user_ids)
    
    await manager.broadcast_to_room(room_id, {
        "event": "PLAYERS_UPDATED",
        "players": players_data
    })

async def process_round_results(room_id: str):
    results = engine.calculate_results(room_id)
    target_id = results.get("target_id")
    assigner_id = results.get("assigner_id")
    missed_voters = results.get("missed_voters", [])
    missed_penalty = results.get("missed_penalty", 0)
    
    async with AsyncSessionLocal() as db:
        users_res = await db.execute(select(User).where(User.room_id == room_id))
        users = users_res.scalars().all()
        for u in users:
            if str(u.id) == target_id:
                u.score = (u.score or 0) + results.get("target_points", 0)
            if str(u.id) == assigner_id:
                u.score = (u.score or 0) + results.get("assigner_points", 0)
            if str(u.id) in missed_voters:
                u.score = (u.score or 0) + missed_penalty
        await db.commit()
    
    await broadcast_players(room_id)
    await manager.broadcast_to_room(room_id, {
        "event": "ROUND_RESULTS_COMPLETED",
        "results": results
    })
    
    # Auto-start next round
    async def next_round_task():
        await asyncio.sleep(8) # Show results for 8 seconds
        has_next = engine.next_round(room_id)
        await broadcast_state(room_id)
        
        if has_next:
            await asyncio.sleep(3)
            engine.select_assigner(room_id)
            await broadcast_state(room_id)
            
            await asyncio.sleep(3)
            engine.select_target(room_id)
            await broadcast_state(room_id)
            
    asyncio.create_task(next_round_task())

async def handle_submit_title(data: dict, room_id: str, user_id: str):
    title_text = data.get("title")
    if not title_text:
        return
        
    async with AsyncSessionLocal() as db:
        new_title = Title(room_id=room_id, author_id=user_id, text=title_text)
        db.add(new_title)
        await db.commit()
    
    engine.submit_title(room_id, user_id, title_text)
    await manager.broadcast_to_room(room_id, {
        "event": "TITLE_ADDED",
        "user_id": user_id
    })
    await broadcast_state(room_id)

async def handle_start_round(data: dict, room_id: str, user_id: str):
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()
        
        if room and str(room.host_id) == user_id:
            async def pick_roles_task():
                engine.games[room_id]["phase"] = "SELECTING_ASSIGNER"
                await broadcast_state(room_id)
                
                await asyncio.sleep(3)
                engine.select_assigner(room_id)
                await broadcast_state(room_id)
                
                await asyncio.sleep(3)
                engine.select_target(room_id)
                await broadcast_state(room_id)
                
            asyncio.create_task(pick_roles_task())

async def handle_assign_title(data: dict, room_id: str, user_id: str):
    title = data.get("title")
    if not title:
        return
        
    engine.select_title(room_id, title)
    state = engine.get_state(room_id)
    timer_duration = state.get("timer", 30)
    current_round = state.get("round", 1)
    
    import time
    engine.games[room_id]["voting_ends_at"] = time.time() + timer_duration
    
    await broadcast_state(room_id)
    
    async def voting_timer():
        await asyncio.sleep(timer_duration)
        current_state = engine.get_state(room_id)
        if current_state and current_state.get("phase") == "VOTING" and current_state.get("round") == current_round:
            engine.force_finish_voting(room_id)
            await broadcast_state(room_id)
            await process_round_results(room_id)
            
    asyncio.create_task(voting_timer())

async def handle_vote(data: dict, room_id: str, user_id: str):
    vote = data.get("vote") # string: "agree", "disagree", "neutral"
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
        
        if room and str(room.host_id) == user_id:
            room.status = RoomStatus.PLAYING
            room.current_round = 1
            max_rounds = room.rounds
            timer_duration = room.timer
            
            users_res = await db.execute(select(User).where(User.room_id == room_id))
            users = users_res.scalars().all()
            user_ids = [str(u.id) for u in users]
            
            if len(user_ids) < 3:
                return
                
            await db.commit()
            
            engine.init_game(room_id, user_ids, max_rounds=max_rounds, timer=timer_duration)
            
            await manager.broadcast_to_room(room_id, {
                "event": "GAME_STARTED"
            })
            await broadcast_state(room_id)

@router.websocket("/ws/{room_id}/{user_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str, user_id: str):
    await manager.connect(websocket, room_id, user_id)
    
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user:
            user.is_connected = True
            await db.commit()
            
    await manager.broadcast_to_room(room_id, {
        "event": "PLAYER_JOINED",
        "user_id": user_id
    })
    
    await broadcast_players(room_id)
    
    state = engine.get_state(room_id)
    if state:
        await websocket.send_json({
            "event": "STATE_UPDATE",
            "state": state
        })

    try:
        while True:
            data = await websocket.receive_json()
            action = data.get("action")
            
            if action == "SUBMIT_TITLE":
                await handle_submit_title(data, room_id, user_id)
            elif action == "START_ROUND":
                await handle_start_round(data, room_id, user_id)
            elif action == "START_GAME":
                await handle_start_game(data, room_id, user_id)
            elif action == "ASSIGN_TITLE":
                await handle_assign_title(data, room_id, user_id)
            elif action == "VOTE":
                await handle_vote(data, room_id, user_id)
            elif action == "TYPING":
                is_typing = data.get("is_typing", False)
                await manager.broadcast_to_room(room_id, {
                    "event": "PLAYER_TYPING",
                    "user_id": user_id,
                    "is_typing": is_typing
                })

    except WebSocketDisconnect:
        manager.disconnect(room_id, user_id)
        
        async with AsyncSessionLocal() as db:
            result = await db.execute(select(User).where(User.id == user_id))
            user = result.scalar_one_or_none()
            if user:
                user.is_connected = False
                await db.commit()
                
        await manager.broadcast_to_room(room_id, {
            "event": "PLAYER_LEFT",
            "user_id": user_id
        })
        await broadcast_players(room_id)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(room_id, user_id)
