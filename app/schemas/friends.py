from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class FriendCreate(BaseModel):

    user_id:Optional[int] = Field(None)
    friend_id: int = Field(...)
    friend_username: str =Field(None)


class FriendResponse(BaseModel):
    # friendship_id: int
    # user_id: int
    friend_id: int
    friend_username: str
    status: str | None = None
    
    class Config:
        from_attributes = True