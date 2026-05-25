from fastapi import APIRouter, Depends
from sqlalchemy import func, select, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.enums import EventSeverity, SensorType
from app.models.event import AccessEvent
from app.models.sensor import SensorReading


router = APIRouter()


@router.get("/health")
def health() -> dict[str, str]:
    return {"status": "healthy"}


@router.get("/status")
def status(db: Session = Depends(get_db)) -> dict[str, str]:
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError:
        return {
            "api": "online",
            "database": "offline",
        }
    return {
        "api": "online",
        "database": "online",
    }


@router.get("/live-status")
def live_status(db: Session = Depends(get_db)) -> dict:
    try:
        return _database_live_status(db)
    except SQLAlchemyError:
        return {
            "api": "online",
            "database": "offline",
            "latest_readings": {},
            "active_unacknowledged_events": 0,
        }


def _database_live_status(db: Session) -> dict:
    latest_readings = {}
    for sensor_type in SensorType:
        statement = (
            select(SensorReading)
            .where(SensorReading.sensor_type == sensor_type)
            .order_by(SensorReading.created_at.desc())
            .limit(1)
        )
        reading = db.scalars(statement).first()
        latest_readings[sensor_type.value] = None if reading is None else reading.value

    active_alerts = db.scalar(
        select(func.count())
        .select_from(AccessEvent)
        .where(
            AccessEvent.is_acknowledged.is_(False),
            AccessEvent.severity != EventSeverity.INFO,
        )
    )
    return {
        "api": "online",
        "database": "online",
        "latest_readings": latest_readings,
        "active_unacknowledged_events": active_alerts or 0,
    }
