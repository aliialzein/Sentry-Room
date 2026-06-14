from fastapi import APIRouter, Depends, HTTPException, Response, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.enums import EventSeverity, EventType
from app.models.event import AccessEvent
from app.schemas.event import EventRead
from app.services.event_messages import websocket_event_message
from app.services.gemini_alerts import gemini_alert_service
from app.services.notification import NotificationService
from app.services.pi_camera_stream import pi_camera_stream
from app.services.storage import save_bytes_file
from app.services.websocket_manager import manager


router = APIRouter()


@router.get("/snapshot")
def camera_snapshot() -> Response:
    frame = pi_camera_stream.wait_for_frame(timeout=2.0)
    if frame is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No Pi camera frame has been received yet.",
        )

    return Response(content=frame, media_type="image/jpeg")


@router.get("/stream")
def camera_stream() -> StreamingResponse:
    return StreamingResponse(
        pi_camera_stream.mjpeg_frames(),
        media_type="multipart/x-mixed-replace; boundary=frame",
        headers={
            "Cache-Control": "no-cache, no-store, must-revalidate, no-transform",
            "Pragma": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("/test-alert", response_model=EventRead, status_code=status.HTTP_201_CREATED)
async def create_camera_test_alert(
    db: Session = Depends(get_db),
) -> AccessEvent:
    frame = pi_camera_stream.wait_for_frame(timeout=2.0)
    if frame is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No Pi camera frame has been received yet.",
        )

    snapshot_path = save_bytes_file(
        frame,
        subdir="events",
        filename_prefix="manual_camera_alert",
    )
    event = AccessEvent(
        event_type=EventType.UNAUTHORIZED_ENTRY,
        severity=EventSeverity.CRITICAL,
        message="Camera alert: review the latest room snapshot.",
        snapshot_path=snapshot_path,
        sensor_payload={
            "source": "manual_camera_test_alert",
            "camera": "pi_stream",
        },
    )
    db.add(event)
    db.flush()
    gemini_alert_service.enrich_event_message(db, event, frame)
    NotificationService().create_pending_alerts(db, event)
    db.commit()
    db.refresh(event)

    await manager.broadcast(websocket_event_message(event))
    return event
