from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any

from app.database import get_db
from app.core.auth import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("/me")
async def get_current_user_info(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get current user information
    Returns user data if token is valid, otherwise returns token expired message
    """
    
    # If execution reaches here, token is valid (get_current_user already validated it)
    # Return comprehensive user information for the player
    
    return {
        "user_id": current_user.user_id,
        "username": current_user.username,
        "email": current_user.email,
        "first_name": current_user.first_name,
        "last_name": current_user.last_name,
        "profile_complete": current_user.profile_complete,
        
        # Player stats
        "current_rating": current_user.current_rating,
        "current_rank": current_user.current_rank,
        "total_matches": current_user.total_matches,
        "matches_won": current_user.matches_won,
        "win_rate": float(current_user.win_rate) if current_user.win_rate else 0.0,
        "problems_solved": current_user.problems_solved,
        
        # Profile information
        "date_of_birth": current_user.date_of_birth.isoformat() if current_user.date_of_birth else None,
        "bio": current_user.bio,
        "preferred_language": current_user.preferred_language,
        "country": current_user.country,
        "timezone": current_user.timezone,
        
        # Status
        "is_verified": current_user.is_verified,
        "last_login": current_user.last_login.isoformat() if current_user.last_login else None,
        "created_at": current_user.created_at.isoformat() if current_user.created_at else None
    }