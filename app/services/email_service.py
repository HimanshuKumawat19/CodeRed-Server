import secrets
from typing import Optional
from app.config import settings


class EmailService:
    """Service for sending verification emails"""
    
    @staticmethod
    def generate_verification_token() -> str:
        """Generate email verification token"""
        return secrets.token_urlsafe(32)

    @staticmethod
    async def send_verification_email(email: str, token: str) -> bool:
        """
        Send email verification link
        In production, integrate with services like SendGrid, AWS SES, etc.
        """
        try:
            # TODO: Implement actual email sending
            # For now, just log the verification link
            verification_url = f"http://localhost:3000/verify-email?token={token}"
            print(f"📧 Verification email for {email}: {verification_url}")
            return True
        except Exception as e:
            print(f"❌ Failed to send verification email: {e}")
            return False

    @staticmethod
    async def send_welcome_email(email: str, username: str) -> bool:
        """Send welcome email after registration"""
        try:
            # TODO: Implement actual email sending
            print(f"🎉 Welcome email sent to {email} for user {username}")
            return True
        except Exception as e:
            print(f"❌ Failed to send welcome email: {e}")
            return False