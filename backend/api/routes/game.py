import json
import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy import select

from core.connection import manager
from core.database import AsyncSessionLocal
from models.room import Room, RoomStatus
from models.user import User
from models.title import Title

router = APIRouter(prefix="/game", tags=["Game"])
logger = logging.getLogger(__name__)

async def handle_submit_title(data: dict, room_id: str, user_id: str):
    title_text = data.get("title")
    if not title_text:
        return
        
    async with AsyncSessionLocal() as db:
        new_title = Title(room_id=room_id, author_id=user_id, text=title_text)
        db.add(new_title)
        await db.commit()
    
    # Notify room that a title was added (could just send the count)
    await manager.broadcast_to_room(room_id, {
        "event": "TITLE_ADDED",
        "user_id": user_id
    })

async def handle_start_game(data: dict, room_id: str, user_id: str):
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar_one_or_none()
        
        if room and str(room.host_id) == user_id:
            room.status = RoomStatus.PLAYING
            room.current_round = 1
            await db.commit()
            
            await manager.broadcast_to_room(room_id, {
                "event": "GAME_STARTED"
            })

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

    try:
        while True:
            data = await websocket.receive_json()
            action = data.get("action")
            
            if action == "SUBMIT_TITLE":
                await handle_submit_title(data, room_id, user_id)
            elif action == "START_GAME":
                await handle_start_game(data, room_id, user_id)
            # Add more handlers like ASSIGN_TITLE, VOTE here...

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
