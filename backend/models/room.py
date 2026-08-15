import enum
from sqlalchemy import Column, String, Integer, Boolean, Enum
from sqlalchemy.orm import relationship
from core.database import Base

class RoomStatus(str, enum.Enum):
    WAITING = "WAITING"
    PLAYING = "PLAYING"
    FINISHED = "FINISHED"

class Room(Base):
    __tablename__ = "rooms"

    id = Column(String(4), primary_key=True, index=True) # 4-letter invite code
    host_id = Column(String, nullable=True) # UUID of the host user
    status = Column(Enum(RoomStatus), default=RoomStatus.WAITING)
    
    # Game Settings
    max_players = Column(Integer, default=6)
    rounds = Column(Integer, default=3)
    timer = Column(Integer, default=30)
    secret_mode = Column(Boolean, default=False)
    
    # Current Game State
    current_round = Column(Integer, default=0)
    turn_user_id = Column(String, nullable=True)
    target_user_id = Column(String, nullable=True)

    # Relationships
    users = relationship("User", back_populates="room", cascade="all, delete-orphan", lazy="selectin")
    titles = relationship("Title", back_populates="room", cascade="all, delete-orphan", lazy="selectin")
