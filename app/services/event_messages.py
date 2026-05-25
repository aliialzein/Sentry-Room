from app.models.event import AccessEvent


def websocket_event_message(event: AccessEvent) -> dict:
    return {
        "type": event.event_type.value,
        "severity": event.severity.value,
        "message": event.message,
        "event_id": event.id,
        "snapshot_path": event.snapshot_path,
    }
