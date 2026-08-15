import uuid
from sqlalchemy import Column, String, Integer, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_id = Column(String(4), ForeignKey("rooms.id", ondelete="CASCADE"), index=True)
    
    name = Column(String, nullable=False)
    color = Column(String, default="#FFFFFF")
    score = Column(Integer, default=0)
    is_connected = Column(Boolean, default=False)

    # Relationships
    room = relationship("Room", back_populates="users")
    titles = relationship("Title", back_populates="author", cascade="all, delete-orphan")
