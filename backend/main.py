from fastapi import FastAPI, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from contextlib import asynccontextmanager
from core.database import get_db, engine, Base
import models.room, models.user, models.title

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(title="CYO Game API", lifespan=lifespan)

@app.get("/")
def root():
    return {"message": "FastAPI is running!"}

@app.get("/health/db")
async def check_db(db: AsyncSession = Depends(get_db)):
    """Health check endpoint to verify database connection."""
    try:
        # Execute a simple query
        result = await db.execute(text("SELECT 1"))
        value = result.scalar()
        return {"status": "ok", "db_value": value}
    except Exception as e:
        return {"status": "error", "message": str(e)}