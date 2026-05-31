from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.ai_reporting import AIReportRange, AIReportResponse
from app.services.ai_reporting import AIReportingService, AIRateLimitExceeded

router = APIRouter()


@router.get("/summary", response_model=AIReportResponse)
def generate_ai_summary(
    report_range: AIReportRange = Query(default=AIReportRange.DAILY, alias="range"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AIReportResponse:
    try:
        return AIReportingService().generate_summary(
            db=db,
            report_range=report_range,
            user_id=current_user.id,
        )
    except AIRateLimitExceeded as exc:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="AI summary request limit exceeded. Try again later.",
        ) from exc
    except SQLAlchemyError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to load analytics for AI summary.",
        ) from exc
