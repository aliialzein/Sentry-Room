from datetime import datetime

from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from app.models.emergency_incident import EmergencyIncident
from app.models.enums import EmergencyIncidentStatus


class AnalyticsRepository:
    def get_summary_counts(self, db: Session, start_at: datetime) -> tuple[int, int, int, int]:
        successful_status = case(
            (EmergencyIncident.status != EmergencyIncidentStatus.FAILED_TO_OPEN_EXTERNAL_APP, 1),
            else_=0,
        )
        failed_status = case(
            (EmergencyIncident.status == EmergencyIncidentStatus.FAILED_TO_OPEN_EXTERNAL_APP, 1),
            else_=0,
        )
        pending_status = case(
            (EmergencyIncident.status == EmergencyIncidentStatus.CONFIRMED, 1),
            else_=0,
        )

        statement = select(
            func.count(EmergencyIncident.id),
            func.coalesce(func.sum(pending_status), 0),
            func.coalesce(func.sum(successful_status), 0),
            func.coalesce(func.sum(failed_status), 0),
        ).where(EmergencyIncident.recorded_at >= start_at)

        row = db.execute(statement).one()
        return int(row[0]), int(row[1]), int(row[2]), int(row[3])

    def get_most_common_type(self, db: Session, start_at: datetime) -> str | None:
        statement = (
            select(EmergencyIncident.emergency_type, func.count(EmergencyIncident.id).label("incident_count"))
            .where(EmergencyIncident.recorded_at >= start_at)
            .group_by(EmergencyIncident.emergency_type)
            .order_by(func.count(EmergencyIncident.id).desc(), EmergencyIncident.emergency_type.asc())
            .limit(1)
        )
        row = db.execute(statement).first()
        return row[0] if row else None

    def get_counts_by_type(self, db: Session, start_at: datetime) -> list[tuple[str, int]]:
        statement = (
            select(EmergencyIncident.emergency_type, func.count(EmergencyIncident.id).label("incident_count"))
            .where(EmergencyIncident.recorded_at >= start_at)
            .group_by(EmergencyIncident.emergency_type)
            .order_by(func.count(EmergencyIncident.id).desc(), EmergencyIncident.emergency_type.asc())
        )
        return [(str(row[0]), int(row[1])) for row in db.execute(statement)]

    def get_counts_by_action(self, db: Session, start_at: datetime) -> list[tuple[str, int]]:
        statement = (
            select(EmergencyIncident.action_type, func.count(EmergencyIncident.id).label("incident_count"))
            .where(EmergencyIncident.recorded_at >= start_at)
            .group_by(EmergencyIncident.action_type)
            .order_by(func.count(EmergencyIncident.id).desc(), EmergencyIncident.action_type.asc())
        )
        return [(str(row[0]), int(row[1])) for row in db.execute(statement)]

    def get_trends(self, db: Session, start_at: datetime) -> list[tuple[object, int]]:
        incident_date = func.date(EmergencyIncident.recorded_at)
        statement = (
            select(incident_date.label("incident_date"), func.count(EmergencyIncident.id).label("incident_count"))
            .where(EmergencyIncident.recorded_at >= start_at)
            .group_by(incident_date)
            .order_by(incident_date.asc())
        )
        return [(row[0], int(row[1])) for row in db.execute(statement)]
