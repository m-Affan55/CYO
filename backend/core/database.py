import logging
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from core.config import settings

logger = logging.getLogger(__name__)

# Create the async engine
try:
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=True, # Echo SQL queries for debugging
    )
except Exception as e:
    logger.error(f"Failed to create database engine: {e}")
    raise

# Create a configured "Session" class
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False
)

Base = declarative_base()

async def get_db():
    """
    Dependency function that yields a database session.
    It automatically closes the session after the request is processed.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception as e:
            await session.rollback()
            logger.error(f"Database session error: {e}")
            raise
        finally:
            await session.close()
