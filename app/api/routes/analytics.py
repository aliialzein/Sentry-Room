from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.schemas.analytics import (
    AnalyticsActionCount,
    AnalyticsRange,
    AnalyticsSummary,
    AnalyticsTrendPoint,
    AnalyticsTypeCount,
)
from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.services.analytics import AnalyticsService

router = APIRouter()


def _service_error(exc: SQLAlchemyError) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="Unable to load analytics.",
    )


@router.get("/summary", response_model=AnalyticsSummary)
def get_analytics_summary(
    analytics_range: AnalyticsRange = Query(default=AnalyticsRange.DAILY, alias="range"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AnalyticsSummary:
    try:
        return AnalyticsService().get_summary(db=db, analytics_range=analytics_range)
    except SQLAlchemyError as exc:
        raise _service_error(exc) from exc


@router.get("/trends", response_model=list[AnalyticsTrendPoint])
def get_analytics_trends(
    analytics_range: AnalyticsRange = Query(default=AnalyticsRange.DAILY, alias="range"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[AnalyticsTrendPoint]:
    try:
        return AnalyticsService().get_trends(db=db, analytics_range=analytics_range)
    except SQLAlchemyError as exc:
        raise _service_error(exc) from exc


@router.get("/by-type", response_model=list[AnalyticsTypeCount])
def get_analytics_by_type(
    analytics_range: AnalyticsRange = Query(default=AnalyticsRange.DAILY, alias="range"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[AnalyticsTypeCount]:
    try:
        return AnalyticsService().get_counts_by_type(db=db, analytics_range=analytics_range)
    except SQLAlchemyError as exc:
        raise _service_error(exc) from exc


@router.get("/by-action", response_model=list[AnalyticsActionCount])
def get_analytics_by_action(
    analytics_range: AnalyticsRange = Query(default=AnalyticsRange.DAILY, alias="range"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[AnalyticsActionCount]:
    try:
        return AnalyticsService().get_counts_by_action(db=db, analytics_range=analytics_range)
    except SQLAlchemyError as exc:
        raise _service_error(exc) from exc
