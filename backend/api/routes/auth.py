from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from core.database import get_db
from models.account import Account
from schemas.auth import AccountCreate, AccountLogin, AccountResponse, Token, AccountUpdate
from core.security import get_password_hash, verify_password, create_access_token
from api.dependencies import get_current_account

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=Token)
async def register(user_in: AccountCreate, db: AsyncSession = Depends(get_db)):
    # Check if username exists
    result = await db.execute(select(Account).where(Account.username == user_in.username))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Username already registered")
    
    hashed_password = get_password_hash(user_in.password)
    new_account = Account(
        username=user_in.username,
        password_hash=hashed_password,
        color=user_in.color,
        status=user_in.status
    )
    db.add(new_account)
    await db.commit()
    await db.refresh(new_account)
    
    access_token = create_access_token(data={"username": new_account.username})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=Token)
async def login(user_in: AccountLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Account).where(Account.username == user_in.username))
    account = result.scalar_one_or_none()
    if not account or not verify_password(user_in.password, account.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    
    access_token = create_access_token(data={"username": account.username})
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=AccountResponse)
async def read_users_me(current_account: Account = Depends(get_current_account)):
    return current_account

@router.put("/update", response_model=AccountResponse)
async def update_profile(update_data: AccountUpdate, db: AsyncSession = Depends(get_db), current_account: Account = Depends(get_current_account)):
    if update_data.username and update_data.username != current_account.username:
        # Check uniqueness
        res = await db.execute(select(Account).where(Account.username == update_data.username))
        if res.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Username already taken")
        current_account.username = update_data.username
    
    if update_data.color:
        current_account.color = update_data.color
    if update_data.status:
        current_account.status = update_data.status
        
    await db.commit()
    await db.refresh(current_account)
    return current_account
