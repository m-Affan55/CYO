from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from schemas.auth import AccountResponse

class InviteCreate(BaseModel):
    friend_id: UUID
    room_code: str

class InviteResponse(BaseModel):
    id: UUID
    sender_id: UUID
    receiver_id: UUID
    room_code: str
    created_at: datetime
    sender: AccountResponse

    class Config:
        from_attributes = True
