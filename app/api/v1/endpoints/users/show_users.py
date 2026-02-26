from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.schemas.user import PaginatedUsers
from app.services.user_service import UserService
from app.core.auth import get_current_user_id

router = APIRouter()

@router.get("/show_users", response_model=PaginatedUsers)
async def list_users(
    limit: int = Query(20, ge=1, le=50),
    cursor: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    users, next_cursor = await UserService.get_users_paginated(
        db=db,
        limit=limit,
        cursor=cursor,
        current_user_id = user_id
    )

    return {
        "users": users,
        "next_cursor": next_cursor
    }

