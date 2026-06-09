from dataclasses import dataclass

from sqlalchemy.orm import Session

from app.models.enums import EventSeverity, EventType, SecurityMode
from app.models.system import SystemSetting


SECURITY_MODE_KEY = "security_mode"


@dataclass(frozen=True)
class PersonDetectionRule:
    should_log: bool
    min_visible_seconds: float
    event_type: EventType
    severity: EventSeverity
    message: str


def current_security_mode(db: Session) -> SecurityMode:
    setting = db.get(SystemSetting, SECURITY_MODE_KEY)
    if setting is None:
        return SecurityMode.WORKING_HOURS

    raw_mode = (setting.value or {}).get("mode")
    if raw_mode in {"deep_night", "lockdown"}:
        return SecurityMode.LOCKED

    try:
        return SecurityMode(raw_mode)
    except ValueError:
        return SecurityMode.WORKING_HOURS


def person_detection_rule(mode: SecurityMode) -> PersonDetectionRule:
    if mode == SecurityMode.DISARMED:
        return PersonDetectionRule(
            should_log=False,
            min_visible_seconds=999999,
            event_type=EventType.SYSTEM_EVENT,
            severity=EventSeverity.INFO,
            message="Person detected while monitoring is disarmed.",
        )

    if mode == SecurityMode.WORKING_HOURS:
        return PersonDetectionRule(
            should_log=True,
            min_visible_seconds=5,
            event_type=EventType.SYSTEM_EVENT,
            severity=EventSeverity.INFO,
            message="Person activity observed during working hours.",
        )

    return PersonDetectionRule(
        should_log=True,
        min_visible_seconds=2.5,
        event_type=EventType.UNAUTHORIZED_ENTRY,
        severity=EventSeverity.CRITICAL,
        message="Person detected while the room is locked.",
    )
