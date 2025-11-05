from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.auth import get_current_user
from app.services.user_service import UserService
from app.services.auth_service import AuthService
from app.services.email_service import EmailService
from app.schemas.auth import ProfileCompletionRequest, AuthResponse
from app.schemas.user import UserProfileUpdate  # Fixed import
from app.models.user import User

router = APIRouter()

@router.post("/complete-profile", response_model=AuthResponse)
async def complete_profile(
    profile_data: ProfileCompletionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Complete user profile after registration"""
    # Check if username is available
    username_exists = await UserService.check_username_exists(db, profile_data.username)
    
    if username_exists and current_user.username != profile_data.username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    # Convert to UserProfileUpdate schema
    profile_update = UserProfileUpdate(
        username=profile_data.username,
        first_name=profile_data.first_name,
        last_name=profile_data.last_name,
        date_of_birth=profile_data.date_of_birth,
        bio=profile_data.bio,
        preferred_language=profile_data.preferred_language
    )
    
    # Complete profile
    updated_user = await UserService.complete_user_profile(
        db, current_user.user_id, profile_update
    )
    
    if not updated_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to complete profile"
        )
    
    # Generate new tokens with updated user info
    tokens = AuthService.create_user_tokens(updated_user.user_id)
    
    # Send welcome email
    await EmailService.send_welcome_email(updated_user.email, updated_user.username)
    
    return AuthResponse(
        access_token=tokens["access_token"],
        token_type=tokens["token_type"],
        user_id=updated_user.user_id,
        profile_complete=True,
        message="Profile completed successfully!"
    )