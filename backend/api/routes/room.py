import random
import string
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from core.database import get_db
from models.room import Room, RoomStatus
from models.user import User
from schemas.room import RoomCreate, RoomResponse
from schemas.user import UserCreate, UserResponse

router = APIRouter(prefix="/rooms", tags=["Rooms"])

def generate_room_code() -> str:
    """Generate a 4-letter uppercase room code."""
    return "".join(random.choices(string.ascii_uppercase, k=4))

@router.post("/create", response_model=RoomResponse, status_code=status.HTTP_201_CREATED)
async def create_room(room_in: RoomCreate, db: AsyncSession = Depends(get_db)):
    # Generate unique room code
    code = generate_room_code()
    while True:
        result = await db.execute(select(Room).where(Room.id == code))
        if not result.scalar_one_or_none():
            break
        code = generate_room_code()

    # Create Room
    new_room = Room(
        id=code,
        max_players=room_in.max_players,
        rounds=room_in.rounds,
        timer=room_in.timer,
        secret_mode=room_in.secret_mode,
        luck_play=room_in.luck_play,
        status=RoomStatus.WAITING
    )
    db.add(new_room)
    await db.flush() # Flush to get the room in the session

    # Create Host User
    host_user = User(
        room_id=code,
        name=room_in.host_name,
        color=room_in.host_color,
        is_connected=False
    )
    db.add(host_user)
    await db.flush()

    # Update Room's host_id
    new_room.host_id = str(host_user.id)
    await db.commit()
    await db.refresh(new_room)

    return new_room


@router.post("/{room_id}/join", response_model=UserResponse)
async def join_room(room_id: str, user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    room_id = room_id.upper()
    
    # Check if room exists and get its users
    result = await db.execute(
        select(Room).options(selectinload(Room.users)).where(Room.id == room_id)
    )
    room = result.scalar_one_or_none()

    if not room:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail=f"Room {room_id} not found."
        )

    if room.status != RoomStatus.WAITING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Game is already in progress or finished."
        )

    if len(room.users) >= room.max_players:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Room is full."
        )

    # Check if a user with the same name already exists in the room
    if any(u.name.lower() == user_in.name.lower() for u in room.users):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="A player with this name is already in the room."
        )

    new_user = User(
        room_id=room_id,
        name=user_in.name,
        color=user_in.color,
        is_connected=False
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    return new_user
