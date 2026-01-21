from fastapi import APIRouter
from app.core.redis import redis_client

router = APIRouter(prefix="/system", tags=["System"])

@router.get("/online-users")
def get_online_users():
    users = redis_client.smembers("online_users")
    return {
        "count": len(users),
        "users": list(users)
    }
