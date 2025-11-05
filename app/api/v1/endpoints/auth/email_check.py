from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, EmailStr

from app.database import get_db
from app.services.user_service import UserService

router = APIRouter()

class EmailCheckRequest(BaseModel):
    email: EmailStr

class EmailCheckResponse(BaseModel):
    exists: bool
    message: str

@router.post("/check-email", response_model=EmailCheckResponse)
async def check_email(
    email_data: EmailCheckRequest,
    db: AsyncSession = Depends(get_db)
):
    """Check if email exists in database"""
    exists = await UserService.check_email_exists(db, email_data.email)
    
    return EmailCheckResponse(
        exists=exists,
        message="User exists" if exists else "Email available for registration"
    )