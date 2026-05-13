from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import EventSeverity, EventType
from app.models.event import AccessEvent
from app.models.person import Person
from app.services.notification import NotificationService
from app.services.recognition import FaceRecognitionService, KnownFace
from app.services.storage import save_bytes_file


class DetectionService:
    def __init__(self, recognizer: FaceRecognitionService | None = None) -> None:
        self.recognizer = recognizer or FaceRecognitionService()

    def process_image(
        self,
        db: Session,
        image_bytes: bytes,
        sensor_payload: dict | None = None,
    ) -> AccessEvent:
        snapshot_path = save_bytes_file(image_bytes, subdir="events", filename_prefix="detection")
        detected_faces = self.recognizer.detect_faces(image_bytes)

        if not detected_faces:
            event = AccessEvent(
                event_type=EventType.MOTION_DETECTED,
                severity=EventSeverity.WARNING,
                message="Motion or image captured, but no face was detected.",
                snapshot_path=snapshot_path,
                sensor_payload=sensor_payload,
            )
            db.add(event)
            db.flush()
            NotificationService().create_pending_alerts(db, event)
            return event

        known_faces = self._known_authorized_faces(db)
        matches = []
        unknown_count = 0

        for detected_face in detected_faces:
            match = self.recognizer.match_encoding(known_faces, detected_face.encoding)
            if match is None:
                unknown_count += 1
            else:
                matches.append(match)

        if unknown_count:
            event = AccessEvent(
                event_type=EventType.UNAUTHORIZED_ENTRY,
                severity=EventSeverity.CRITICAL,
                message=f"Unauthorized person detected ({unknown_count} unknown face(s)).",
                snapshot_path=snapshot_path,
                sensor_payload=sensor_payload,
            )
            db.add(event)
            db.flush()
            NotificationService().create_pending_alerts(db, event)
            return event

        primary_match = matches[0]
        names = ", ".join(match.name for match in matches)
        event = AccessEvent(
            event_type=EventType.AUTHORIZED_ENTRY,
            severity=EventSeverity.INFO,
            message=f"Authorized entry detected: {names}.",
            person_id=primary_match.person_id,
            confidence=primary_match.confidence,
            snapshot_path=snapshot_path,
            sensor_payload=sensor_payload,
        )
        db.add(event)
        db.flush()
        return event

    @staticmethod
    def _known_authorized_faces(db: Session) -> list[KnownFace]:
        statement = select(Person).where(Person.is_authorized.is_(True), Person.face_encoding.is_not(None))
        people = db.scalars(statement)
        return [
            KnownFace(name=person.full_name, encoding=person.face_encoding or [], person_id=person.id)
            for person in people
        ]
