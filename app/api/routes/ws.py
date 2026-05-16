from fastapi import APIRouter, WebSocket, WebSocketDisconnect # type: ignore

from app.services.websocket_manager import manager


router = APIRouter()


@router.websocket("/alerts")
async def websocket_alerts(websocket: WebSocket):
    await manager.connect(websocket)

    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)