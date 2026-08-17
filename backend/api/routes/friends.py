from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from sqlalchemy.orm import selectinload
from typing import List
from core.database import get_db
from models.friendship import Friendship
from models.account import Account
from schemas.friendship import FriendshipResponse, FriendResponse
from schemas.auth import AccountResponse
from api.dependencies import get_current_account

router = APIRouter(prefix="/friends", tags=["Friends"])

@router.post("/request/{username}", response_model=FriendshipResponse)
async def send_friend_request(username: str, db: AsyncSession = Depends(get_db), current_account: Account = Depends(get_current_account)):
    if current_account.username == username:
        raise HTTPException(status_code=400, detail="Cannot add yourself")
        
    res = await db.execute(select(Account).where(Account.username == username))
    target = res.scalar_one_or_none()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Check if already friends or requested
    res_fs = await db.execute(
        select(Friendship).where(
            or_(
                and_(Friendship.requester_id == current_account.id, Friendship.addressee_id == target.id),
                and_(Friendship.requester_id == target.id, Friendship.addressee_id == current_account.id)
            )
        )
    )
    existing = res_fs.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Friend request already exists or already friends")
        
    fs = Friendship(requester_id=current_account.id, addressee_id=target.id, status="PENDING")
    db.add(fs)
    await db.commit()
    await db.refresh(fs)
    return fs

@router.get("/", response_model=List[AccountResponse])
async def get_friends(db: AsyncSession = Depends(get_db), current_account: Account = Depends(get_current_account)):
    res = await db.execute(
        select(Friendship).where(
            and_(
                or_(Friendship.requester_id == current_account.id, Friendship.addressee_id == current_account.id),
                Friendship.status == "ACCEPTED"
            )
        )
    )
    friendships = res.scalars().all()
    friend_ids = []
    for f in friendships:
        if f.requester_id == current_account.id:
            friend_ids.append(f.addressee_id)
        else:
            friend_ids.append(f.requester_id)
            
    if not friend_ids:
        return []
        
    res_accs = await db.execute(select(Account).where(Account.id.in_(friend_ids)))
    return res_accs.scalars().all()

@router.get("/requests", response_model=List[FriendshipResponse])
async def get_requests(db: AsyncSession = Depends(get_db), current_account: Account = Depends(get_current_account)):
    res = await db.execute(
        select(Friendship).where(
            and_(Friendship.addressee_id == current_account.id, Friendship.status == "PENDING")
        )
    )
    return res.scalars().all()

@router.post("/accept/{request_id}")
async def accept_request(request_id: str, db: AsyncSession = Depends(get_db), current_account: Account = Depends(get_current_account)):
    res = await db.execute(select(Friendship).where(Friendship.id == request_id))
    fs = res.scalar_one_or_none()
    if not fs or fs.addressee_id != current_account.id:
        raise HTTPException(status_code=404, detail="Request not found")
        
    fs.status = "ACCEPTED"
    await db.commit()
    return {"message": "Accepted"}

@router.post("/reject/{request_id}")
async def reject_request(request_id: str, db: AsyncSession = Depends(get_db), current_account: Account = Depends(get_current_account)):
    res = await db.execute(select(Friendship).where(Friendship.id == request_id))
    fs = res.scalar_one_or_none()
    if not fs or fs.addressee_id != current_account.id:
        raise HTTPException(status_code=404, detail="Request not found")
        
    await db.delete(fs)
    await db.commit()
    return {"message": "Rejected"}
