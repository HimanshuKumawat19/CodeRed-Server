from fastapi import APIRouter, Depends,HTTPException,status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.database import get_db
from app.models.friend import Friend
from app.core.auth import get_current_user_id
from app.models.user import User
from app.schemas.friends import FriendResponse,FriendCreate
from app.schemas.user import UserListItem
from app.services.user_service import UserService
router = APIRouter()


@router.get(
    "/friendlist",
    response_model=List[FriendResponse]
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


@router.post(
    "/send-request",
    status_code=status.HTTP_201_CREATED
)
async def send_request(
    friend_data: FriendCreate,
    db: AsyncSession = Depends(get_db),
    user_id:int = Depends(get_current_user_id)
):
    try:
        # check if user id is not none
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail = "User id is not availabel"
            )
        
        # check does user exist or not

        user = await UserService.get_user_by_user_id(db,user_id)

        if not user:
            raise HTTPException(
                status_code = status.HTTP_401_UNAUTHORIZED,
                detail="user does not exist"
            )
        
        friend_data = await UserService.get_user_by_user_id(db,friend_data.friend_id)

        if not friend_data:
            raise HTTPException(
                status_code=status.HTTP_204_NO_CONTENT,
                detail ="friend id doesn't exist"
            )
        
        friend_row_data = Friend(
            friend_id=friend_data.user_id,
            user_id=user_id,
            friend_username=friend_data.username
        )

        db.add(friend_row_data)
        await db.commit()
        await db.refresh(friend_row_data)

        return "Request Successfully Sended"

    except Exception as e:
        print(f"Friend Request error: {e}") 
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Request failed: {str(e)}"
        )