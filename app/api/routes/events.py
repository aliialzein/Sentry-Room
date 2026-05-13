from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.enums import EventSeverity, EventType
from app.models.event import AccessEvent
from app.schemas.event import DetectionRequest, EventCreate, EventRead
from app.services.detection import DetectionService
from app.services.notification import NotificationService
from app.services.storage import decode_base64_payload, save_bytes_file


router = APIRouter()


@router.post("", response_model=EventRead, status_code=status.HTTP_201_CREATED)
def create_event(payload: EventCreate, db: Session = Depends(get_db)) -> AccessEvent:
    snapshot_path = payload.snapshot_path
    if payload.snapshot_base64:
        snapshot_bytes = decode_base64_payload(payload.snapshot_base64)
        snapshot_path = save_bytes_file(snapshot_bytes, subdir="events", filename_prefix=payload.event_type.value)

    event = AccessEvent(
        event_type=payload.event_type,
        severity=payload.severity,
        message=payload.message,
        person_id=payload.person_id,
        confidence=payload.confidence,
        snapshot_path=snapshot_path,
        sensor_payload=payload.sensor_payload,
    )
    db.add(event)
    db.flush()

    if event.severity in {EventSeverity.WARNING, EventSeverity.CRITICAL}:
        NotificationService().create_pending_alerts(db, event)

    db.commit()
    db.refresh(event)
    return event


@router.get("", response_model=list[EventRead])
def list_events(
    event_type: EventType | None = None,
    severity: EventSeverity | None = None,
    acknowledged: bool | None = None,
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
) -> list[AccessEvent]:
    statement = select(AccessEvent).order_by(AccessEvent.created_at.desc()).limit(limit)
    if event_type is not None:
        statement = statement.where(AccessEvent.event_type == event_type)
    if severity is not None:
        statement = statement.where(AccessEvent.severity == severity)
    if acknowledged is not None:
        statement = statement.where(AccessEvent.is_acknowledged == acknowledged)
    return list(db.scalars(statement))


@router.get("/{event_id}", response_model=EventRead)
def get_event(event_id: int, db: Session = Depends(get_db)) -> AccessEvent:
    event = db.get(AccessEvent, event_id)
    if event is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Event not found")
    return event


@router.patch("/{event_id}/acknowledge", response_model=EventRead)
def acknowledge_event(event_id: int, db: Session = Depends(get_db)) -> AccessEvent:
    event = db.get(AccessEvent, event_id)
    if event is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Event not found")
    event.is_acknowledged = True
    db.commit()
    db.refresh(event)
    return event


@router.post("/detection", response_model=EventRead, status_code=status.HTTP_201_CREATED)
def process_detection(payload: DetectionRequest, db: Session = Depends(get_db)) -> AccessEvent:
    image_bytes = decode_base64_payload(payload.image_base64)
    try:
        event = DetectionService().process_image(
            db=db,
            image_bytes=image_bytes,
            sensor_payload=payload.sensor_payload,
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc

    db.commit()
    db.refresh(event)
    return event
