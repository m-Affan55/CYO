from pydantic import BaseModel, Field
from uuid import UUID

class TitleBase(BaseModel):
    text: str = Field(..., min_length=1, max_length=50)

class TitleCreate(TitleBase):
    pass

class TitleResponse(TitleBase):
    id: UUID
    room_id: str
    author_id: UUID
    used: bool

    class Config:
        from_attributes = True
