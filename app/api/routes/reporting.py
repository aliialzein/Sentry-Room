import smtplib

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.reporting import DailyReportEmailResponse, ReportRange
from app.services.daily_report_email import DailyReportEmailService
from app.services.reporting import ReportingService

router = APIRouter()


@router.post("/daily-email/send", response_model=DailyReportEmailResponse)
def send_daily_email_report(db: Session = Depends(get_db)) -> DailyReportEmailResponse:
    try:
        result = DailyReportEmailService().send_today_report(db)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except smtplib.SMTPAuthenticationError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="SMTP authentication failed. Check the Gmail address and app password in .env.",
        ) from exc
    except (smtplib.SMTPException, OSError) as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Unable to send email through SMTP: {exc}",
        ) from exc

    return DailyReportEmailResponse(
        sent=result.sent,
        recipient=result.recipient,
        event_count=result.event_count,
        subject=result.subject,
        generated_at=result.generated_at,
        gemini_status=result.gemini_status,
    )


@router.get("/pdf")
def generate_pdf_report(
    report_range: ReportRange = Query(default=ReportRange.DAILY, alias="range"),
    db: Session = Depends(get_db),
) -> StreamingResponse:
    try:
        service = ReportingService()
        pdf = service.generate_pdf_report(
            db=db,
            report_range=report_range,
            user_id=0,
        )
        filename = service.filename(report_range)
    except SQLAlchemyError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to generate analytics report.",
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to generate PDF report.",
        ) from exc

    return StreamingResponse(
        pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Cache-Control": "no-store",
        },
    )
