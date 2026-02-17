from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.schemas.auth import RegisterRequest, AuthResponse
from app.schemas.user import UserCreate

router = APIRouter()

@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(
    register_data: RegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    """Register new user with email and password"""
    try:
        # Check if user already exists
        user_exists = await UserService.check_email_exists(db, register_data.email)
        
        if user_exists:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User already exists. Please login instead."
            )
        
        # Create minimal user data for registration - only email and password
        user_create = UserCreate(
            email=register_data.email,
            password=register_data.password,
            # All other fields are optional and will be None by default
        )
        
        # Create user
        user, error = await AuthService.create_user(db, user_create)
        
        if error:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=error
            )
        
        # Generate tokens
        tokens = AuthService.create_user_tokens(user.user_id)
        
        return AuthResponse(
            access_token=tokens["access_token"],
            token_type=tokens["token_type"],
            user_id=user.user_id,
            profile_complete=False,
            message="Registration successful. Please complete your profile."
        )
        
    except Exception as e:
        print(f"Registration error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )