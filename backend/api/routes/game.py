import json
import logging
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

async def handle_submit_title(data: dict, room_id: str, user_id: str):
    title_text = data.get("title")
    if not title_text:
        return
        
    async with AsyncSessionLocal() as db:
        new_title = Title(room_id=room_id, author_id=user_id, text=title_text)
        db.add(new_title)
        await db.commit()
    
    # Update state
    all_submitted = engine.submit_title(room_id, user_id, title_text)
    await manager.broadcast_to_room(room_id, {
        "event": "TITLE_ADDED",
        "user_id": user_id
    })
    await broadcast_state(room_id)

async def handle_assign_title(data: dict, room_id: str, user_id: str):
    target_id = data.get("target_id")
    title = data.get("title")
    if not target_id or not title:
        return
        
    engine.select_target_and_title(room_id, target_id, title)
    await broadcast_state(room_id)
    
async def handle_select_assigner(data: dict, room_id: str, user_id: str):
    assigner_id = data.get("assigner_id")
    if not assigner_id:
        return
    engine.select_assigner(room_id, assigner_id)
    await broadcast_state(room_id)

async def handle_vote(data: dict, room_id: str, user_id: str):
    vote = data.get("vote") # boolean
    if vote is None:
        return
        
    all_voted = engine.submit_vote(room_id, user_id, vote)
    await broadcast_state(room_id)
    
    if all_voted:
        # Save points to db
        results = engine.calculate_results(room_id)
        target_id = results.get("target_id")
        assigner_id = results.get("assigner_id")
        
        async with AsyncSessionLocal() as db:
            users_res = await db.execute(select(User).where(User.room_id == room_id))
            users = users_res.scalars().all()
            for u in users:
                if str(u.id) == target_id:
                    u.score = (u.score or 0) + results.get("target_points", 0)
                if str(u.id) == assigner_id:
                    u.score = (u.score or 0) + results.get("assigner_points", 0)
            await db.commit()
        
        await manager.broadcast_to_room(room_id, {
            "event": "ROUND_RESULTS_COMPLETED",
            "results": results
        })

async def handle_start_game(data: dict, room_id: str, user_id: str):
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()
        
        if room and str(room.host_id) == user_id:
            room.status = RoomStatus.PLAYING
            room.current_round = 1
            
            # Fetch all users
            users_res = await db.execute(select(User).where(User.room_id == room_id))
            users = users_res.scalars().all()
            user_ids = [str(u.id) for u in users]
            
            await db.commit()
            
            engine.init_game(room_id, user_ids)
            
            await manager.broadcast_to_room(room_id, {
                "event": "GAME_STARTED"
            })
            await broadcast_state(room_id)

@router.websocket("/ws/{room_id}/{user_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str, user_id: str):
    await manager.connect(websocket, room_id, user_id)
    
    # Mark user as connected in DB
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
    
    # Send current game state if playing
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
            elif action == "START_GAME":
                await handle_start_game(data, room_id, user_id)
            elif action == "ASSIGN_TITLE":
                await handle_assign_title(data, room_id, user_id)
            elif action == "SELECT_ASSIGNER":
                await handle_select_assigner(data, room_id, user_id)
            elif action == "VOTE":
                await handle_vote(data, room_id, user_id)

    except WebSocketDisconnect:
        manager.disconnect(room_id, user_id)
        
        # Mark user as disconnected in DB
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
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(room_id, user_id)
