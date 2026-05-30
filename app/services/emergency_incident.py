from datetime import datetime

from sqlalchemy.orm import Session

from app.models.enums import EmergencyIncidentStatus
from app.repositories.emergency_incident import EmergencyIncidentRepository
from app.schemas.emergency import EmergencyIncidentCreate


class EmergencyIncidentService:
    def __init__(self, repository: EmergencyIncidentRepository | None = None) -> None:
        self._repository = repository or EmergencyIncidentRepository()

    def create_incident(
        self,
        db: Session,
        payload: EmergencyIncidentCreate,
        reported_by_user_id: int | None = None,
    ):
        recorded_at = payload.recorded_at or datetime.utcnow()
        incident = self._repository.create(
            db=db,
            payload=payload.copy(update={"recorded_at": recorded_at}),
            reported_by_user_id=reported_by_user_id,
        )
        db.commit()
        db.refresh(incident)
        return incident

    def list_incidents(
        self,
        db: Session,
        emergency_type: str | None = None,
        status: EmergencyIncidentStatus | None = None,
        limit: int = 100,
    ):
        return self._repository.list(
            db=db,
            emergency_type=emergency_type,
            status=status,
            limit=limit,
        )

    def get_incident(self, db: Session, incident_id: int):
        return self._repository.get(db, incident_id)
