from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.alert import AlertDelivery
from app.models.enums import AlertChannel
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
            deliveries.append(
                AlertDelivery(
                    event=event,
                    channel=AlertChannel.EMAIL,
                    target=settings.alert_email_to,
                )
            )

        db.add_all(deliveries)
        return deliveries
