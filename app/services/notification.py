from datetime import datetime, timezone
from email.message import EmailMessage
from pathlib import Path
import mimetypes
import smtplib

from sqlalchemy.orm import Session

from app.core.config import PROJECT_ROOT, get_settings
from app.models.alert import AlertDelivery
from app.models.enums import AlertChannel, DeliveryStatus
from app.models.event import AccessEvent


class NotificationService:
    def create_pending_alerts(self, db: Session, event: AccessEvent) -> list[AlertDelivery]:
        settings = get_settings()
        deliveries = [
            AlertDelivery(
                event=event,
                channel=AlertChannel.APP,
                target=settings.app_alert_channel,
            )
        ]

        if settings.alert_email_to:
            email_delivery = AlertDelivery(
                event=event,
                channel=AlertChannel.EMAIL,
                target=settings.alert_email_to,
            )
            self._send_email_alert(email_delivery)
            deliveries.append(email_delivery)

        db.add_all(deliveries)
        return deliveries

    def _send_email_alert(self, delivery: AlertDelivery) -> None:
        settings = get_settings()
        if not self._smtp_is_configured():
            delivery.status = DeliveryStatus.FAILED
            delivery.error = "SMTP is not configured. Set SMTP_HOST, SMTP_USERNAME, SMTP_PASSWORD, and SMTP_FROM."
            return

        event = delivery.event
        message = EmailMessage()
        message["Subject"] = f"Sentry Room Alert: {event.severity.value.upper()} {event.event_type.value}"
        message["From"] = settings.smtp_from
        message["To"] = delivery.target or settings.alert_email_to
        message.set_content(self._email_body(event))

        snapshot = self._snapshot_path(event.snapshot_path)
        if snapshot and snapshot.exists():
            content_type, _ = mimetypes.guess_type(snapshot)
            main_type, sub_type = (content_type or "image/jpeg").split("/", 1)
            message.add_attachment(
                snapshot.read_bytes(),
                maintype=main_type,
                subtype=sub_type,
                filename=snapshot.name,
            )

        try:
            with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
                if settings.smtp_use_tls:
                    smtp.starttls()
                smtp.login(settings.smtp_username, settings.smtp_password)
                smtp.send_message(message)
        except Exception as exc:
            delivery.status = DeliveryStatus.FAILED
            delivery.error = str(exc)
            return

        delivery.status = DeliveryStatus.SENT
        delivery.sent_at = datetime.now(timezone.utc)

    @staticmethod
    def _smtp_is_configured() -> bool:
        settings = get_settings()
        return all([settings.smtp_host, settings.smtp_username, settings.smtp_password, settings.smtp_from])

    @staticmethod
    def _email_body(event: AccessEvent) -> str:
        return "\n".join(
            [
                "Sentry Room detected a security event.",
                "",
                f"Event ID: {event.id}",
                f"Type: {event.event_type.value}",
                f"Severity: {event.severity.value}",
                f"Message: {event.message}",
                f"Snapshot: {event.snapshot_path or 'No snapshot'}",
                "",
                "Open the Sentry Room app to review and acknowledge this alert.",
            ]
        )

    @staticmethod
    def _snapshot_path(snapshot_path: str | None) -> Path | None:
        if not snapshot_path:
            return None
        path = Path(snapshot_path)
        return path if path.is_absolute() else PROJECT_ROOT / path
