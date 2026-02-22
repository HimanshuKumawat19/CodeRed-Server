from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.database import get_db
from app.models.friend import Friend
from app.core.auth import get_current_user_id
from app.models.user import User
from app.schemas.friends import FriendOut
from app.schemas.user import UserListItem

router = APIRouter()


@router.get(
    "/friendlist",
    response_model=List[FriendOut]
)
async def get_friends_list(
    user_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Friend).where(Friend.user_id == user_id, Friend.is_blocked != True)
    result = await db.execute(stmt)
    friends = result.scalars().all()

    # for f in friends:
    #     friend_name = 
    return friends


@router.get(
    "/add-friend",
    response_model=list[UserListItem]
)
async def get_all_user(
    user_id: int  = Depends(get_current_user_id),
    db:AsyncSession=Depends(get_db)
):  
    stmt = select(User).where(User.is_verified == True, User.user_id != user_id)
    result = await db.execute(stmt)
    users = result.scalars().all()

    return users
