from sqlalchemy import Column, Integer, String, Boolean, DateTime, DECIMAL, Date, Text
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    __tablename__ = "users"

    # Primary Key & Identification
    user_id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=True, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=True)

    # Profile Information
    first_name = Column(String(50), nullable=True)
    last_name = Column(String(50), nullable=True)
    date_of_birth = Column(Date, nullable=True)
    bio = Column(Text, nullable=True)
    preferred_language = Column(String(20), default='python')
    profile_picture = Column(String(255), nullable=True)
    country = Column(String(100), nullable=True)
    timezone = Column(String(50), default='UTC')

    # Rating & Ranking System
    current_rating = Column(Integer, default=1000, nullable=False)
    peak_rating = Column(Integer, default=1000, nullable=False)
    current_rank = Column(String(20), default='Bronze', nullable=False)

    # Match Performance Statistics
    total_matches = Column(Integer, default=0, nullable=False)
    matches_won = Column(Integer, default=0, nullable=False)
    win_rate = Column(DECIMAL(5, 2), default=0.00, nullable=False)
    problems_solved = Column(Integer, default=0, nullable=False)

    # Authentication & Status
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    profile_complete = Column(Boolean, default=False, nullable=False)  # This was missing!
    auth_provider = Column(String(20), default='local', nullable=False)
    google_id = Column(String(100), unique=True, nullable=True)
    #google_refresh_token = Column(String(500), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), 
                       onupdate=func.now(), nullable=False)
    last_login = Column(DateTime(timezone=True), nullable=True)
    email_verified_at = Column(DateTime(timezone=True), nullable=True)

    def __repr__(self) -> str:
        return f"<User(user_id={self.user_id}, email='{self.email}')>"