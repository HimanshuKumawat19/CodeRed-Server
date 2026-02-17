from pydantic import BaseModel

class FriendOut(BaseModel):
    # friendship_id: int
    # user_id: int
    friend_id: int
    status: str | None = None
    
    class Config:
        from_attributes = True
