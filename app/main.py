from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import engine, Base

def create_application() -> FastAPI:
    """Application factory pattern for better testability"""
    app = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        docs_url="/docs",
        redoc_url="/redoc"
    )

    # Add middleware
    setup_middleware(app)

    # Add routes
    setup_routes(app)

    # Add event handlers
    setup_events(app)

    return app

def setup_middleware(app: FastAPI) -> None:
    """setup all middleware"""
    
    # Allow both your frontend URLs
    origins = [
        "http://localhost:3000",      # Local development
        "http://127.0.0.1:3000",      # Local development
        "https://ec3d0556de7f.ngrok-free.app",  # Your ngrok URL
        "https://*.ngrok-free.app",
        "http://localhost:8000",      # Backend itself
        # Add your actual frontend domain if deployed
    ]
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,  # Important for cookies/tokens
        allow_methods=["*"],     # Allow all methods
        allow_headers=["*"],     # Allow all headers
    )

def setup_routes(app: FastAPI) -> None:
    """Setup all API routes"""
    
    # REST API only - no GraphQL!
    from app.api.v1.endpoints import auth
    app.include_router(auth.router, prefix="/api/v1")

def setup_events(app: FastAPI) -> None:
    """Setup startup/shutdown events"""
    
    @app.on_event("startup")
    async def startup_event():
        from app.models.user import User  # Import inside function to avoid circular imports
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        print("✅ Database tables created successfully")
    
    @app.get("/")
    async def root():
        return {
            "message": "CodeForge API is running!",
            "version": settings.VERSION,
            "docs": "/docs"
            # Removed "graphql" reference
        }
    
    @app.get("/health")
    async def health_check():
        return {"status": "healthy", "service": "CodeForge API"}

# Create app instance
app = create_application()