from fastapi import WebSocket, WebSocketDisconnect, status
from app.core.security import verify_token
from app.services.auth_service import AuthService
from app.database import get_db
from app.core.ws_manager import ConnectionManager


manager = ConnectionManager()

async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    token = websocket.cookies.get("access_token")
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    payload = verify_token(token)
    if not payload:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    user_id = payload.get("sub")
    if not user_id:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    async for db in get_db():
        user = await AuthService.get_user_by_id(db, int(user_id))
        if not user:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

    await manager.connect(user.user_id, websocket)

    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_json({
                "message": "Authenticated",
                "user_id": user.user_id,
            })
    except WebSocketDisconnect:
        manager.disconnect(user.user_id)
        print("WebSocket disconnected")
