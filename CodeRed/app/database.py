from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import settings

class Base(DeclarativeBase):
    pass


def create_database_engine():
    """Create database engine with connection pooling for performance"""

    # ❗ USE SETTINGS, NOT os.getenv
    database_url = settings.DATABASE_URL

    # Convert sync style to asyncpg
    database_url = database_url.replace("postgresql://", "postgresql+asyncpg://")

    # Remove unsupported argument
    database_url = database_url.replace("&channel_binding=require", "")

    # Convert sslmode=require → ssl=require for asyncpg
    database_url = database_url.replace("sslmode=require", "ssl=require")


    #print("DATABASE URL (DATABASE.PY) →", database_url)

    return create_async_engine(
        database_url,
        echo=False,
        pool_size=20,
        max_overflow=30,
        pool_pre_ping=True
    )


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
