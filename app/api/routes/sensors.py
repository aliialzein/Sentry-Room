from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.enums import EventSeverity, EventType, SensorType
from app.models.event import AccessEvent
from app.models.sensor import SensorReading
from app.models.system import SystemSetting
from app.schemas.sensor import SensorReadingCreate, SensorReadingRead


router = APIRouter()


@router.post("", response_model=SensorReadingRead, status_code=status.HTTP_201_CREATED)
def create_sensor_reading(payload: SensorReadingCreate, db: Session = Depends(get_db)) -> SensorReading:
    reading = SensorReading(**payload.model_dump())
    db.add(reading)
    db.flush()
    _create_alert_if_threshold_crossed(db, reading)
    db.commit()
    db.refresh(reading)
    return reading


@router.get("/recent", response_model=list[SensorReadingRead])
def recent_sensor_readings(
    limit: int = Query(default=25, ge=1, le=200),
    db: Session = Depends(get_db),
) -> list[SensorReading]:
    statement = select(SensorReading).order_by(SensorReading.created_at.desc()).limit(limit)
    return list(db.scalars(statement))


def _create_alert_if_threshold_crossed(db: Session, reading: SensorReading) -> None:
    if reading.sensor_type == SensorType.TEMPERATURE_HUMIDITY:
        thresholds = _thresholds(db, "environment_thresholds", _default_environment_thresholds())
        temperature = reading.value.get("temperature_c")
        humidity = reading.value.get("humidity_percent")
        violations = []

        if temperature is not None and not thresholds["temperature_c_min"] <= temperature <= thresholds["temperature_c_max"]:
            violations.append(f"temperature={temperature}C")
        if humidity is not None and not thresholds["humidity_percent_min"] <= humidity <= thresholds["humidity_percent_max"]:
            violations.append(f"humidity={humidity}%")

        if violations:
            db.add(
                AccessEvent(
                    event_type=EventType.ENVIRONMENTAL_ALERT,
                    severity=EventSeverity.WARNING,
                    message=f"Environment threshold crossed: {', '.join(violations)}.",
                    sensor_payload=reading.value,
                )
            )

    if reading.sensor_type == SensorType.DISTANCE:
        thresholds = _thresholds(db, "distance_thresholds", {"min_distance_cm": 30})
        distance = reading.value.get("distance_cm")
        if distance is not None and distance < thresholds["min_distance_cm"]:
            db.add(
                AccessEvent(
                    event_type=EventType.MOTION_DETECTED,
                    severity=EventSeverity.WARNING,
                    message=f"Distance anomaly detected: {distance}cm.",
                    sensor_payload=reading.value,
                )
            )


def _thresholds(db: Session, key: str, default: dict) -> dict:
    setting = db.get(SystemSetting, key)
    if setting is None:
        return default
    return {**default, **setting.value}


def _default_environment_thresholds() -> dict:
    return {
        "temperature_c_min": 18,
        "temperature_c_max": 30,
        "humidity_percent_min": 30,
        "humidity_percent_max": 70,
    }
