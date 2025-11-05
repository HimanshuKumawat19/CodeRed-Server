from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.schemas.auth import LoginRequest, AuthResponse

router = APIRouter()

@router.post("/login", response_model=AuthResponse)
async def login(
    login_data: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """Login user with email and password"""
    # Check if user exists
    user_exists = await UserService.check_email_exists(db, login_data.email)
    
    if not user_exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found. Please register first."
        )
    
    # Authenticate user
    user = await AuthService.authenticate_user(db, login_data.email, login_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password"
        )
    
    # Update last login
    await UserService.update_last_login(db, user.user_id)
    
    # Generate tokens
    tokens = AuthService.create_user_tokens(user.user_id)
    
    return AuthResponse(
        access_token=tokens["access_token"],
        token_type=tokens["token_type"],
        user_id=user.user_id,
        profile_complete=user.profile_complete,
        message="Login successful" if user.profile_complete else "Profile completion required"
    )