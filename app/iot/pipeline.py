from dataclasses import dataclass

from app.core.database import SessionLocal
from app.models.event import AccessEvent
from app.services.detection import DetectionService


@dataclass(frozen=True)
class PipelineResult:
    event_id: int
    event_type: str
    severity: str
    message: str


class SentryPipeline:
    def __init__(self, detection_service: DetectionService | None = None) -> None:
        self.detection_service = detection_service or DetectionService()

    def process_snapshot(self, image_bytes: bytes, sensor_payload: dict | None = None) -> PipelineResult:
        db = SessionLocal()
        try:
            event = self.detection_service.process_image(db, image_bytes, sensor_payload)
            db.commit()
            db.refresh(event)
            return self._result(event)
        finally:
            db.close()

    @staticmethod
    def _result(event: AccessEvent) -> PipelineResult:
        return PipelineResult(
            event_id=event.id,
            event_type=event.event_type.value,
            severity=event.severity.value,
            message=event.message,
        )
