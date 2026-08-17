from pydantic import BaseModel, Field
from typing import List, Optional
from models.room import RoomStatus
from schemas.user import UserResponse

class RoomBase(BaseModel):
    max_players: int = Field(default=6, ge=3, le=12)
    rounds: int = Field(default=3, ge=1, le=10)
    timer: int = Field(default=30, ge=10, le=60)
    secret_mode: bool = Field(default=False)
    luck_play: bool = Field(default=True)

class RoomCreate(RoomBase):
    host_name: str = Field(..., min_length=1, max_length=20)
    host_color: str = Field(default="#FFFFFF")

class RoomResponse(RoomBase):
    id: str
    host_id: Optional[str]
    status: RoomStatus
    current_round: int
    turn_user_id: Optional[str]
    target_user_id: Optional[str]
    users: List[UserResponse] = []

    class Config:
        from_attributes = True
