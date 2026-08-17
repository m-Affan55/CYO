from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from schemas.auth import AccountResponse

class FriendshipResponse(BaseModel):
    id: UUID
    requester_id: UUID
    addressee_id: UUID
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class FriendResponse(BaseModel):
    friend_account: AccountResponse
    status: str
