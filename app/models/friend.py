from sqlalchemy import Column, Integer, String,ForeignKey
from app.database import Base

class Friend(Base):
    __tablename__ = "friends"

    user_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)
    friend_id = Column(Integer, ForeignKey("users.user_id"), primary_key=True)
    status = Column(String, nullable=False)
