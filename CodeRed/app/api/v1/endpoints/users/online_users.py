from fastapi import APIRouter
from app.core.redis import redis_client

router = APIRouter()

@router.get("/online/{user_id}")
def get_user_status(user_id: int):
    is_online = redis_client.sismember("online_users", user_id)
    return {"user_id": user_id, "online": is_online}
