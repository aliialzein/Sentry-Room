import asyncio
import logging
import threading
import time
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.orm.attributes import flag_modified

from app.core.config import get_settings
from app.core.database import SessionLocal
from app.models.enums import EventSeverity, EventType, SecurityMode
from app.models.event import AccessEvent
from app.services.event_messages import websocket_event_message
from app.services.face_index import face_index
from app.services.gemini_alerts import gemini_alert_service
from app.services.identity_detection import FaceIdentity, IdentityDetectionResult, IdentityDetectionService
from app.services.notification import NotificationService
from app.services.pi_camera_stream import pi_camera_stream
from app.services.security_modes import current_security_mode, person_detection_rule
from app.services.storage import save_bytes_file
from app.services.websocket_manager import manager


logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class PersonDetection:
    confidence: float
    bounding_box: dict[str, int]


@dataclass(frozen=True)
class EventDecision:
    event_key: str
    identity_key: str
    event_type: EventType
    severity: EventSeverity
    message: str
    person_id: int | None
    confidence: float | None
    identity: FaceIdentity | None


class PersonDetectionWorker:
    def __init__(self) -> None:
        self._stop_event = threading.Event()
        self._thread: threading.Thread | None = None
        self._loop: asyncio.AbstractEventLoop | None = None
        self._model = None
        self._identity_service = IdentityDetectionService()
        self._disabled_reason: str | None = None
        self._person_seen_since: float | None = None
        self._last_person_seen_at: float | None = None
        self._last_identity_check_at: float = 0.0
        self._last_identity_result: IdentityDetectionResult | None = None
        self._last_identity_error: str | None = None

    def start(self, loop: asyncio.AbstractEventLoop) -> None:
        settings = get_settings()
        if not settings.detection_worker_enabled:
            logger.info("Person detection worker disabled")
            return
        if self._thread and self._thread.is_alive():
            return

        self._loop = loop
        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._run,
            name="person-detection-worker",
            daemon=True,
        )
        self._thread.start()

    def stop(self) -> None:
        self._stop_event.set()

    def _run(self) -> None:
        settings = get_settings()
        logger.info("Person detection worker started")

        while not self._stop_event.is_set():
            started_at = time.monotonic()
            try:
                self._tick()
            except Exception:
                logger.exception("Person detection worker tick failed")

            elapsed = time.monotonic() - started_at
            sleep_for = max(0.2, settings.detection_sample_interval_seconds - elapsed)
            self._stop_event.wait(sleep_for)

    def _tick(self) -> None:
        if self._disabled_reason is not None:
            return

        self._close_stale_incidents()

        frame = pi_camera_stream.latest_frame()
        if frame is None:
            self._reset_person_presence()
            return

        detections = self._detect_people(frame)
        now = time.monotonic()

        if not detections:
            if self._last_person_seen_at is not None and now - self._last_person_seen_at > 4:
                self._reset_person_presence()
            return

        self._last_person_seen_at = now
        if self._person_seen_since is None:
            self._person_seen_since = now

        visible_seconds = now - self._person_seen_since
        self._create_or_update_person_incident(frame, detections, visible_seconds)

    def _detect_people(self, frame: bytes) -> list[PersonDetection]:
        model = self._load_model()
        if model is None:
            return []

        cv2 = self._cv2()
        numpy = self._numpy()
        if cv2 is None or numpy is None:
            return []

        image_array = numpy.frombuffer(frame, dtype=numpy.uint8)
        image = cv2.imdecode(image_array, cv2.IMREAD_COLOR)
        if image is None:
            return []

        settings = get_settings()
        results = model.predict(
            image,
            classes=[0],
            conf=settings.yolo_person_confidence,
            imgsz=settings.yolo_image_size,
            verbose=False,
        )
        people: list[PersonDetection] = []

        for result in results:
            for box in result.boxes:
                class_id = int(box.cls)
                confidence = float(box.conf)
                if class_id != 0 or confidence < settings.yolo_person_confidence:
                    continue

                x1, y1, x2, y2 = [int(value) for value in box.xyxy[0].tolist()]
                people.append(
                    PersonDetection(
                        confidence=confidence,
                        bounding_box={"x1": x1, "y1": y1, "x2": x2, "y2": y2},
                    )
                )

        return people

    def _create_or_update_person_incident(
        self,
        frame: bytes,
        detections: list[PersonDetection],
        visible_seconds: float,
    ) -> None:
        db = SessionLocal()
        try:
            mode = current_security_mode(db)
            rule = person_detection_rule(mode)
            if not rule.should_log or visible_seconds < rule.min_visible_seconds:
                return

            best_detection = max(detections, key=lambda detection: detection.confidence)
            identity_result = self._identity_result(db, frame)
            decision = self._event_decision(mode, best_detection, identity_result)
            active_event = self._active_event(db, decision)
            now = datetime.now(timezone.utc)

            if active_event is not None:
                self._touch_active_event(
                    db=db,
                    event=active_event,
                    now=now,
                    decision=decision,
                    frame=frame,
                    detections=detections,
                    visible_seconds=visible_seconds,
                    identity_result=identity_result,
                    identity_error=self._last_identity_error,
                )
                db.commit()
                return

            snapshot_path = save_bytes_file(
                frame,
                subdir="events",
                filename_prefix=f"person_{mode.value}_{decision.identity_key}",
            )
            event = AccessEvent(
                event_type=decision.event_type,
                severity=decision.severity,
                message=decision.message,
                person_id=decision.person_id,
                confidence=decision.confidence,
                snapshot_path=snapshot_path,
                last_seen_at=now,
                sensor_payload=self._event_payload(
                    event_key=decision.event_key,
                    identity_key=decision.identity_key,
                    mode=mode,
                    detections=detections,
                    visible_seconds=visible_seconds,
                    identity_result=identity_result,
                    identity_error=self._last_identity_error,
                    seen_count=1,
                ),
            )
            db.add(event)
            db.flush()
            if identity_result is not None:
                face_index.save_event_unknown_encodings(event.id, identity_result.unknown_encodings)

            if event.severity != EventSeverity.INFO:
                gemini_alert_service.enrich_event_message(db, event, frame)
                NotificationService().create_pending_alerts(db, event)

            db.commit()
            db.refresh(event)
            self._broadcast(websocket_event_message(event))
            logger.info("Created person incident event %s in mode %s", event.id, mode.value)
        finally:
            db.close()

    def _identity_result(self, db, frame: bytes) -> IdentityDetectionResult | None:
        settings = get_settings()
        if not settings.face_recognition_enabled:
            self._last_identity_result = None
            self._last_identity_error = "face recognition disabled"
            return None

        now = time.monotonic()
        if self._last_identity_result is not None and now - self._last_identity_check_at < settings.identity_detection_interval_seconds:
            return self._last_identity_result

        self._last_identity_check_at = now
        try:
            self._last_identity_result = self._identity_service.recognize(db, frame)
            self._last_identity_error = None
        except RuntimeError as exc:
            self._last_identity_result = None
            self._last_identity_error = str(exc)
            logger.warning("Face identity detection skipped: %s", exc)
        return self._last_identity_result

    def _event_decision(
        self,
        mode: SecurityMode,
        best_detection: PersonDetection,
        identity_result: IdentityDetectionResult | None,
    ) -> EventDecision:
        identity = identity_result.primary_identity if identity_result is not None else None
        confidence = best_detection.confidence

        if identity is None:
            identity_key = "no_face"
            severity = EventSeverity.INFO if mode == SecurityMode.WORKING_HOURS else EventSeverity.CRITICAL
            event_type = EventType.SYSTEM_EVENT if mode == SecurityMode.WORKING_HOURS else EventType.UNAUTHORIZED_ENTRY
            message = "Person activity observed; no face was visible."
            if mode == SecurityMode.LOCKED:
                message = "Person detected while the room is locked; no face was visible."
            return EventDecision(
                event_key=f"person_incident:{mode.value}:{identity_key}",
                identity_key=identity_key,
                event_type=event_type,
                severity=severity,
                message=message,
                person_id=None,
                confidence=confidence,
                identity=None,
            )

        if identity.status == "authorized":
            identity_key = f"person_{identity.person_id}"
            name = identity.name or "authorized person"
            return EventDecision(
                event_key=f"person_incident:{mode.value}:{identity_key}",
                identity_key=identity_key,
                event_type=EventType.AUTHORIZED_ENTRY,
                severity=EventSeverity.INFO,
                message=f"Authorized person detected: {name}.",
                person_id=identity.person_id,
                confidence=identity.confidence,
                identity=identity,
            )

        if identity.status == "unauthorized":
            identity_key = f"person_{identity.person_id}"
            severity = EventSeverity.WARNING if mode == SecurityMode.WORKING_HOURS else EventSeverity.CRITICAL
            name = identity.name or "unauthorized person"
            return EventDecision(
                event_key=f"person_incident:{mode.value}:{identity_key}",
                identity_key=identity_key,
                event_type=EventType.UNAUTHORIZED_ENTRY,
                severity=severity,
                message=f"Unauthorized person detected: {name}.",
                person_id=identity.person_id,
                confidence=identity.confidence,
                identity=identity,
            )

        identity_key = "unknown_face"
        severity = EventSeverity.WARNING if mode == SecurityMode.WORKING_HOURS else EventSeverity.CRITICAL
        return EventDecision(
            event_key=f"person_incident:{mode.value}:{identity_key}",
            identity_key=identity_key,
            event_type=EventType.UNAUTHORIZED_ENTRY,
            severity=severity,
            message="Unknown person detected.",
            person_id=None,
            confidence=confidence,
            identity=identity,
        )

    def _active_event(self, db, decision: EventDecision) -> AccessEvent | None:
        statement = (
            select(AccessEvent)
            .where(AccessEvent.ended_at.is_(None))
            .order_by(AccessEvent.created_at.desc())
            .limit(100)
        )

        uncertain_match: AccessEvent | None = None
        for event in db.scalars(statement):
            payload = event.sensor_payload or {}
            if payload.get("source") != "person_detection_worker":
                continue
            if payload.get("security_mode") != _mode_from_event_key(decision.event_key):
                continue

            active_identity_key = str(payload.get("identity_key") or "")
            if active_identity_key == decision.identity_key:
                return event

            if _is_uncertain_identity(active_identity_key):
                uncertain_match = event

            if _is_uncertain_identity(decision.identity_key):
                return event

        if _is_known_identity(decision.identity_key):
            return uncertain_match
        return None

    def _touch_active_event(
        self,
        db,
        event: AccessEvent,
        now: datetime,
        decision: EventDecision,
        frame: bytes,
        detections: list[PersonDetection],
        visible_seconds: float,
        identity_result: IdentityDetectionResult | None,
        identity_error: str | None,
    ) -> None:
        payload = event.sensor_payload or {}
        active_identity_key = str(payload.get("identity_key") or "")
        upgraded_identity = _identity_rank(decision.identity_key) > _identity_rank(active_identity_key)
        preserve_identity_fields = _identity_rank(active_identity_key) > _identity_rank(decision.identity_key)
        previous_identity_payload = {
            key: payload[key]
            for key in ("detected_face_count", "unknown_face_count", "identities", "identity_error")
            if key in payload
        }
        payload.update(
            self._event_payload(
                event_key=decision.event_key if upgraded_identity else str(payload.get("event_key") or decision.event_key),
                identity_key=decision.identity_key if upgraded_identity else str(payload.get("identity_key") or decision.identity_key),
                mode=_security_mode_from_value(payload.get("security_mode")),
                detections=detections,
                visible_seconds=visible_seconds,
                identity_result=identity_result,
                identity_error=identity_error,
                seen_count=int(payload.get("seen_count", 1)) + 1,
            )
        )
        if preserve_identity_fields:
            for key in ("detected_face_count", "unknown_face_count", "identities", "identity_error"):
                payload.pop(key, None)
            payload.update(previous_identity_payload)
        payload["last_seen_at"] = now.isoformat()
        event.last_seen_at = now
        event.sensor_payload = payload
        flag_modified(event, "sensor_payload")

        if upgraded_identity:
            event.event_type = decision.event_type
            event.severity = decision.severity
            event.person_id = decision.person_id
            event.confidence = decision.confidence
            event.message = decision.message
            if identity_result is not None and identity_result.unknown_encodings:
                face_index.save_event_unknown_encodings(event.id, identity_result.unknown_encodings)
            if event.severity != EventSeverity.INFO:
                gemini_alert_service.enrich_event_message(db, event, frame)

    def _close_stale_incidents(self) -> None:
        settings = get_settings()
        now = datetime.now(timezone.utc)
        cutoff = now - timedelta(seconds=settings.incident_clear_after_seconds)
        statement = (
            select(AccessEvent)
            .where(AccessEvent.ended_at.is_(None))
            .order_by(AccessEvent.created_at.desc())
            .limit(100)
        )

        db = SessionLocal()
        try:
            changed = False
            for event in db.scalars(statement):
                payload = event.sensor_payload or {}
                if payload.get("source") != "person_detection_worker":
                    continue

                last_seen_at = _as_aware(event.last_seen_at or event.created_at)
                if last_seen_at > cutoff:
                    continue

                event.ended_at = now
                payload["ended_at"] = now.isoformat()
                event.sensor_payload = payload
                flag_modified(event, "sensor_payload")
                changed = True

            if changed:
                db.commit()
        finally:
            db.close()

    def _event_payload(
        self,
        event_key: str,
        identity_key: str,
        mode: SecurityMode,
        detections: list[PersonDetection],
        visible_seconds: float,
        identity_result: IdentityDetectionResult | None,
        identity_error: str | None,
        seen_count: int,
    ) -> dict:
        payload = {
            "source": "person_detection_worker",
            "event_key": event_key,
            "identity_key": identity_key,
            "security_mode": mode.value,
            "person_count": len(detections),
            "visible_seconds": round(visible_seconds, 2),
            "seen_count": seen_count,
            "detections": [
                {
                    "label": "person",
                    "confidence": detection.confidence,
                    "bounding_box": detection.bounding_box,
                }
                for detection in detections
            ],
        }

        if identity_result is not None:
            payload["detected_face_count"] = identity_result.detected_face_count
            payload["unknown_face_count"] = len(identity_result.unknown_encodings)
            payload["identities"] = [
                {
                    "status": identity.status,
                    "person_id": identity.person_id,
                    "name": identity.name,
                    "is_authorized": identity.is_authorized,
                    "confidence": identity.confidence,
                    "distance": identity.distance,
                    "location": identity.location,
                }
                for identity in identity_result.identities
            ]
        elif identity_error:
            payload["identity_error"] = identity_error

        return payload

    def _reset_person_presence(self) -> None:
        self._person_seen_since = None
        self._last_person_seen_at = None
        self._last_identity_result = None
        self._last_identity_error = None

    def _broadcast(self, payload: dict) -> None:
        if self._loop is None:
            return
        asyncio.run_coroutine_threadsafe(manager.broadcast(payload), self._loop)

    def _load_model(self):
        if self._model is not None:
            return self._model

        try:
            from ultralytics import YOLO
        except ImportError:
            self._disabled_reason = "ultralytics is not installed"
            logger.warning("Person detection worker disabled: %s", self._disabled_reason)
            return None

        settings = get_settings()
        try:
            self._model = YOLO(settings.yolo_model_path)
        except Exception as exc:
            self._disabled_reason = str(exc)
            logger.exception("Person detection worker disabled: could not load YOLO model")
            return None

        logger.info("Loaded YOLO model for person detection: %s", settings.yolo_model_path)
        return self._model

    def _cv2(self):
        try:
            import cv2
        except ImportError:
            self._disabled_reason = "opencv-python is not installed"
            logger.warning("Person detection worker disabled: %s", self._disabled_reason)
            return None
        return cv2

    def _numpy(self):
        try:
            import numpy
        except ImportError:
            self._disabled_reason = "numpy is not installed"
            logger.warning("Person detection worker disabled: %s", self._disabled_reason)
            return None
        return numpy


def _as_aware(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value


def _security_mode_from_value(value: object) -> SecurityMode:
    raw_value = str(value or SecurityMode.WORKING_HOURS.value)
    if raw_value in {"deep_night", "lockdown"}:
        return SecurityMode.LOCKED
    try:
        return SecurityMode(raw_value)
    except ValueError:
        return SecurityMode.WORKING_HOURS


def _mode_from_event_key(event_key: str) -> str:
    parts = event_key.split(":")
    return parts[1] if len(parts) >= 2 else SecurityMode.WORKING_HOURS.value


def _is_uncertain_identity(identity_key: str) -> bool:
    return identity_key in {"no_face", "unknown_face", ""}


def _is_known_identity(identity_key: str) -> bool:
    return identity_key.startswith("person_")


def _identity_rank(identity_key: str) -> int:
    if _is_known_identity(identity_key):
        return 2
    if identity_key == "unknown_face":
        return 1
    return 0


person_detection_worker = PersonDetectionWorker()
