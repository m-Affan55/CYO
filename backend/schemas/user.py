from pydantic import BaseModel, Field
from uuid import UUID
from typing import Optional

class UserBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=20)
    color: str = Field(default="#FFFFFF")

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: UUID
    room_id: str
    score: int
    is_connected: bool

    class Config:
        from_attributes = True
