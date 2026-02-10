from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import Optional

from app.database import get_db
from app.services.google_auth_service import GoogleAuthService
from app.services.auth_service import AuthService
from app.schemas.auth import AuthResponse

router = APIRouter()

class GoogleAuthCodeRequest(BaseModel):
    authorization_code: str

class GoogleAuthResponse(BaseModel):
    authorization_url: str
    client_id: str
    redirect_uri: str
    scope: str = "openid email profile"

@router.get("/auth-url", response_model=GoogleAuthResponse)
async def get_google_auth_url():
    """
    Get Google OAuth URL for frontend to redirect to
    Frontend should redirect user to this URL
    """
    auth_info = GoogleAuthService.get_authorization_url()
    
    return GoogleAuthResponse(
        authorization_url=auth_info["authorization_url"],
        client_id=auth_info["client_id"],
        redirect_uri=auth_info["redirect_uri"]
    )

@router.post("/authenticate", response_model=AuthResponse)
async def google_authenticate(
    auth_data: GoogleAuthCodeRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Complete Google OAuth authentication
    Frontend sends the authorization code obtained after user consent
    """
    try:
        # Complete Google OAuth flow
        user, is_new_user, google_user_info = await GoogleAuthService.authenticate_with_code(
            db, auth_data.authorization_code
        )
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Google authentication failed"
            )
        
        # Generate JWT tokens for our app
        tokens = AuthService.create_user_tokens(user.user_id)
        
        # Determine message based on whether user is new and profile complete
        if is_new_user:
            message = "Google registration successful"
            if not user.profile_complete:
                message += ". Please complete your profile."
        else:
            message = "Google login successful"
            if not user.profile_complete:
                message += ". Please complete your profile."
        
        return AuthResponse(
            access_token=tokens["access_token"],
            token_type=tokens["token_type"],
            user_id=user.user_id,
            profile_complete=user.profile_complete,
            message=message
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Google authentication error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Google authentication failed"
        )

@router.get("/callback")
async def google_callback(
    request: Request,
    code: Optional[str] = None,
    error: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    Google OAuth callback endpoint
    Google will redirect here after user consent
    """
    if error:
        return {"error": f"Google OAuth error: {error}"}
    
    if not code:
        return {"error": "No authorization code received"}
    
    try:
        # Complete authentication with the code
        user, is_new_user, google_user_info = await GoogleAuthService.authenticate_with_code(db, code)
        
        if not user:
            return {"error": "Authentication failed"}
        
        # Generate JWT tokens
        tokens = AuthService.create_user_tokens(user.user_id)
        
        # In a real app, you'd redirect to frontend with tokens
        # For now, return the tokens directly
        return {
            "success": True,
            "user_id": user.user_id,
            "email": user.email,
            "is_new_user": is_new_user,
            "profile_complete": user.profile_complete,
            "access_token": tokens["access_token"],
            "token_type": tokens["token_type"]
        }
        
    except Exception as e:
        print(f"Google callback error: {e}")
        return {"error": "Authentication failed"}