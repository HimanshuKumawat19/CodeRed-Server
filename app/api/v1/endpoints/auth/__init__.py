from fastapi import APIRouter
from .login import router as login_router
from .register import router as register_router
# from .profile import router as profile_router
from .me import router as me_router  # Add this import

router = APIRouter(prefix="/auth", tags=["authentication"])

# Include all auth routers
router.include_router(login_router)
router.include_router(register_router)
# router.include_router(profile_router)
router.include_router(me_router)  # Add this line