from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.database import get_db
from app.models.friend import Friend
from app.schemas.friends import FriendOut

router = APIRouter()


@router.get(
    "/friendlist/{user_id}",
    response_model=List[FriendOut]
)
async def get_friends_list(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    stmt = select(Friend).where(Friend.user_id == user_id and Friend.is_blocked != True)
    result = await db.execute(stmt)
    friends = result.scalars().all()

    return friends
