from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.models.enums import EmergencyIncidentStatus
from app.schemas.emergency import EmergencyIncidentCreate, EmergencyIncidentRead
from app.services.emergency_incident import EmergencyIncidentService

router = APIRouter()


@router.post("", response_model=EmergencyIncidentRead, status_code=status.HTTP_201_CREATED)
def create_emergency_incident(
    payload: EmergencyIncidentCreate,
    db: Session = Depends(get_db),
) -> EmergencyIncidentRead:
    incident = EmergencyIncidentService().create_incident(
        db=db,
        payload=payload,
        reported_by_user_id=None,
    )
    return incident


@router.get("", response_model=list[EmergencyIncidentRead])
def list_emergency_incidents(
    emergency_type: str | None = None,
    status: EmergencyIncidentStatus | None = None,
    limit: int = Query(default=100, ge=1, le=500),
    db: Session = Depends(get_db),
) -> list[EmergencyIncidentRead]:
    return EmergencyIncidentService().list_incidents(
        db=db,
        emergency_type=emergency_type,
        status=status,
        limit=limit,
    )


@router.get("/{incident_id}", response_model=EmergencyIncidentRead)
def get_emergency_incident(
    incident_id: int,
    db: Session = Depends(get_db),
) -> EmergencyIncidentRead:
    incident = EmergencyIncidentService().get_incident(db=db, incident_id=incident_id)
    if incident is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")
    return incident
