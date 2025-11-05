import httpx
from typing import Dict, Optional, Tuple
from app.config import settings
from app.models.user import User
from app.services.user_service import UserService
from sqlalchemy.ext.asyncio import AsyncSession


class GoogleAuthService:
    """Service for Google OAuth authentication"""
    
    GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
    GOOGLE_USER_INFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo"
    GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/auth"
    
    @staticmethod
    def get_authorization_url() -> Dict[str, str]:
        """Generate Google OAuth authorization URL"""
        from urllib.parse import urlencode
        
        params = {
            "client_id": settings.GOOGLE_CLIENT_ID,
            "redirect_uri": settings.GOOGLE_REDIRECT_URI,
            "response_type": "code",
            "scope": "openid email profile",
            "access_type": "offline",
            "prompt": "consent"
        }
        
        authorization_url = f"{GoogleAuthService.GOOGLE_AUTH_URL}?{urlencode(params)}"
        
        return {
            "authorization_url": authorization_url,
            "client_id": settings.GOOGLE_CLIENT_ID,
            "redirect_uri": settings.GOOGLE_REDIRECT_URI
        }
    
    @staticmethod
    async def exchange_code_for_tokens(authorization_code: str) -> Optional[Dict]:
        """Exchange authorization code for access and refresh tokens"""
        try:
            async with httpx.AsyncClient() as client:
                data = {
                    "code": authorization_code,
                    "client_id": settings.GOOGLE_CLIENT_ID,
                    "client_secret": settings.GOOGLE_CLIENT_SECRET,
                    "redirect_uri": settings.GOOGLE_REDIRECT_URI,
                    "grant_type": "authorization_code"
                }
                
                response = await client.post(GoogleAuthService.GOOGLE_TOKEN_URL, data=data)
                
                if response.status_code == 200:
                    return response.json()
                else:
                    print(f"Token exchange failed: {response.status_code} - {response.text}")
                    return None
                    
        except Exception as e:
            print(f"Token exchange error: {e}")
            return None
    
    @staticmethod
    async def get_user_info(access_token: str) -> Optional[Dict]:
        """Get user info from Google using access token"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    GoogleAuthService.GOOGLE_USER_INFO_URL,
                    headers={"Authorization": f"Bearer {access_token}"}
                )
                
                if response.status_code == 200:
                    return response.json()
                else:
                    print(f"User info fetch failed: {response.status_code} - {response.text}")
                    return None
                    
        except Exception as e:
            print(f"User info fetch error: {e}")
            return None
    
    @staticmethod
    async def authenticate_with_code(
        db: AsyncSession, 
        authorization_code: str
    ) -> Tuple[Optional[User], bool, Optional[Dict]]:
        """
        Complete Google OAuth flow with authorization code
        Returns: (user, is_new_user, google_user_info)
        """
        try:
            # Exchange code for tokens
            token_data = await GoogleAuthService.exchange_code_for_tokens(authorization_code)
            
            if not token_data or "access_token" not in token_data:
                return None, False, None
            
            # Get user info from Google
            google_user_info = await GoogleAuthService.get_user_info(token_data["access_token"])
            
            if not google_user_info:
                return None, False, None
            
            # Get or create user in our system
            user, is_new_user = await GoogleAuthService.get_or_create_user_from_google(
                db, google_user_info, token_data
            )
            
            return user, is_new_user, google_user_info
            
        except Exception as e:
            print(f"Google authentication error: {e}")
            return None, False, None
    
    @staticmethod
    async def get_or_create_user_from_google(
        db: AsyncSession, 
        google_user_info: Dict,
        token_data: Optional[Dict] = None
    ) -> Tuple[Optional[User], bool]:
        """
        Get existing user or create new user from Google info
        Returns: (user, is_new_user)
        """
        google_id = google_user_info.get("sub")
        email = google_user_info.get("email")
        
        if not google_id or not email:
            return None, False
        
        # Check if user already exists with this Google ID
        existing_user = await GoogleAuthService.get_user_by_google_id(db, google_id)
        if existing_user:
            return existing_user, False
        
        # Check if user exists with this email (but different auth method)
        existing_email_user = await UserService.get_user_by_email(db, email)
        if existing_email_user:
            # Link Google account to existing user
            existing_email_user.google_id = google_id
            existing_email_user.auth_provider = "google"
            if token_data and "refresh_token" in token_data:
                # Store refresh token for future use (encrypt in production)
                existing_email_user.google_refresh_token = token_data["refresh_token"]
            await db.commit()
            await db.refresh(existing_email_user)
            return existing_email_user, False
        
        # Create new user from Google info
        new_user = User(
            email=email,
            username=GoogleAuthService.generate_username_from_email(email),
            first_name=google_user_info.get("given_name", ""),
            last_name=google_user_info.get("family_name", ""),
            profile_picture=google_user_info.get("picture"),
            google_id=google_id,
            auth_provider="google",
            is_verified=google_user_info.get("email_verified", False),
            is_active=True,
            profile_complete=bool(google_user_info.get("given_name") and google_user_info.get("family_name"))
        )
        
        if token_data and "refresh_token" in token_data:
            # Store refresh token (encrypt in production)
            new_user.google_refresh_token = token_data["refresh_token"]
        
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        
        return new_user, True
    
    @staticmethod
    def generate_username_from_email(email: str) -> str:
        """Generate username from email address"""
        base_username = email.split('@')[0]
        # Remove special characters and make lowercase
        import re
        username = re.sub(r'[^a-zA-Z0-9_]', '', base_username).lower()
        return username if username else "google_user"
    
    @staticmethod
    async def get_user_by_google_id(db: AsyncSession, google_id: str) -> Optional[User]:
        """Get user by Google ID"""
        from sqlalchemy import select
        result = await db.execute(
            select(User).where(User.google_id == google_id)
        )
        return result.scalar_one_or_none()