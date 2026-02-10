from fastapi import WebSocket
from app.core.redis import redis_client

ONLINE_USERS_KEY = "online_users"

class ConnectionManager:
    def __init__(self):
        self.active_connections: dict[int, WebSocket] = {}

    async def connect(self, user_id: int, websocket: WebSocket):
        self.active_connections[user_id] = websocket

        redis_client.sadd(ONLINE_USERS_KEY, user_id)

        print(f"User {user_id} connected")
        print("Online users (Redis):", redis_client.smembers(ONLINE_USERS_KEY))

    def disconnect(self, user_id: int):
        self.active_connections.pop(user_id, None)

        redis_client.srem(ONLINE_USERS_KEY, user_id)

        print(f"User {user_id} disconnected")
        print("Online users (Redis):", redis_client.smembers(ONLINE_USERS_KEY))

    def is_online(self, user_id: int) -> bool:
        return redis_client.sismember(ONLINE_USERS_KEY, user_id)
