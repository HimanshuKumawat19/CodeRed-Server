from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
import os

# Base class for models
class Base(DeclarativeBase):
    pass

def create_database_engine():
    """Create database engine with connection pooling for performance"""
    database_url = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:password@localhost:5432/Codered"
    ).replace("postgresql://", "postgresql+asyncpg://")

    return create_async_engine(
        database_url,
        echo=False,  # Set to false for production (better performance)
        pool_size=20,
        max_overflow=30,
        pool_pre_ping=True # Better connection health checks
    )

# create engine and session factory
engine = create_database_engine()
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False
)

async def get_db():
    """Dependency to get database session"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
