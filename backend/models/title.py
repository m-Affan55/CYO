import uuid
from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from core.database import Base

class Title(Base):
    __tablename__ = "titles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    room_id = Column(String(4), ForeignKey("rooms.id", ondelete="CASCADE"), index=True)
    author_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"))
    
    text = Column(String, nullable=False)
    used = Column(Boolean, default=False)

    # Relationships
    room = relationship("Room", back_populates="titles")
    author = relationship("User", back_populates="titles")
