from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.emergency_incident import EmergencyIncident
from app.models.enums import EmergencyIncidentStatus
from app.schemas.emergency import EmergencyIncidentCreate


class EmergencyIncidentRepository:
    def create(
        self,
        db: Session,
        payload: EmergencyIncidentCreate,
        reported_by_user_id: int | None = None,
    ) -> EmergencyIncident:
        incident = EmergencyIncident(
            emergency_type=payload.emergency_type,
            emergency_title=payload.emergency_title,
            action_type=payload.action_type,
            contact_name=payload.contact_name,
            contact_phone=payload.contact_phone,
            contact_email=payload.contact_email,
            manual_location=payload.manual_location,
            gps_latitude=payload.gps_latitude,
            gps_longitude=payload.gps_longitude,
            status=payload.status,
            source=payload.source,
            details=payload.details,
            reported_by_user_id=reported_by_user_id,
            recorded_at=payload.recorded_at,
        )
        db.add(incident)
        db.flush()
        return incident

    def list(
        self,
        db: Session,
        emergency_type: str | None = None,
        status: EmergencyIncidentStatus | None = None,
        limit: int = 100,
    ) -> list[EmergencyIncident]:
        statement = select(EmergencyIncident).order_by(EmergencyIncident.created_at.desc()).limit(limit)
        if emergency_type is not None:
            statement = statement.where(EmergencyIncident.emergency_type == emergency_type)
        if status is not None:
            statement = statement.where(EmergencyIncident.status == status)
        return list(db.scalars(statement))

    def get(self, db: Session, incident_id: int) -> EmergencyIncident | None:
        return db.get(EmergencyIncident, incident_id)
