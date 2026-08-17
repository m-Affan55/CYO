from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from core.database import get_db
from models.invite import GameInvite
from models.account import Account
from schemas.invite import InviteCreate, InviteResponse
from api.dependencies import get_current_account

router = APIRouter(prefix="/invites", tags=["Invites"])

@router.post("/send")
async def send_invite(invite_in: InviteCreate, db: AsyncSession = Depends(get_db), current_account: Account = Depends(get_current_account)):
    # Verify the target exists
    res = await db.execute(select(Account).where(Account.id == invite_in.friend_id))
    target = res.scalar_one_or_none()
    if not target:
        raise HTTPException(status_code=404, detail="Friend not found")
        
    invite = GameInvite(
        sender_id=current_account.id,
        receiver_id=target.id,
        room_code=invite_in.room_code
    )
    db.add(invite)
    await db.commit()
    await db.refresh(invite)
    return {"message": "Invite sent successfully"}

@router.get("/", response_model=List[InviteResponse])
async def get_invites(db: AsyncSession = Depends(get_db), current_account: Account = Depends(get_current_account)):
    res = await db.execute(select(GameInvite).where(GameInvite.receiver_id == current_account.id))
    invites = res.scalars().all()
    
    # Attach sender info
    result_list = []
    for inv in invites:
        sender_res = await db.execute(select(Account).where(Account.id == inv.sender_id))
        sender = sender_res.scalar_one_or_none()
        inv_dict = {
            "id": inv.id,
            "sender_id": inv.sender_id,
            "receiver_id": inv.receiver_id,
            "room_code": inv.room_code,
            "created_at": inv.created_at,
            "sender": sender
        }
        result_list.append(inv_dict)
        
    return result_list

@router.delete("/{invite_id}")
async def delete_invite(invite_id: str, db: AsyncSession = Depends(get_db), current_account: Account = Depends(get_current_account)):
    res = await db.execute(select(GameInvite).where(GameInvite.id == invite_id))
    inv = res.scalar_one_or_none()
    if not inv or inv.receiver_id != current_account.id:
        raise HTTPException(status_code=404, detail="Invite not found")
        
    await db.delete(inv)
    await db.commit()
    return {"message": "Invite removed"}
