from sqlalchemy import Column, Integer, String,ForeignKey,DateTime,Boolean
from sqlalchemy.sql import func
from app.database import Base

class Friend(Base):
    __tablename__ = "friends"

    friendship_id = Column("friendship_id",Integer,primary_key=True,index = True)
    user_id = Column("user_id",Integer,ForeignKey("user.id"),index=True,nullable=False)
    friend_id = Column("friend_id",Integer,ForeignKey("user.id"),nullable=False)
    status = Column("status",String,default="Pending",nullable= False)
    is_blocked = Column("is_blocked",Boolean,default = False,nullable=False)
    requested_date = Column("requested_date",DateTime(timezone=True),server_default = func.now(),nullable = False)
    accepted_date = Column("accepted_date",DateTime(timezone=True),nullable = True)