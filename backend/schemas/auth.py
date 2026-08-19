from pydantic import BaseModel
from typing import Optional
from uuid import UUID

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

class AccountCreate(BaseModel):
    username: str
    email: str
    password: str
    color: str = "#FFFFFF"
    status: Optional[str] = None

class AccountLogin(BaseModel):
    email: str
    password: str

class AccountResponse(BaseModel):
    id: UUID
    username: str
    email: Optional[str] = None
    color: str
    status: Optional[str] = None
    points: int

    class Config:
        from_attributes = True

class AccountUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    color: Optional[str] = None
    status: Optional[str] = None
