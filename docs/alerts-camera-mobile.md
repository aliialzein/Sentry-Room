# Alerts, Camera Stream, And Mobile Admin Flow

## Email Alerts

Unauthorized and warning/critical events create app alerts and email alert deliveries.

Set these values in `.env`:

```env
ALERT_EMAIL_TO=security@example.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_gmail_app_password
SMTP_FROM=your_email@gmail.com
SMTP_USE_TLS=true
```

For Gmail, `SMTP_PASSWORD` must be an app password, not the normal Gmail password.

## Authorize Unknown Person

When the camera detects an unknown face, the backend stores that face encoding inside the unauthorized event.

The admin can authorize that detected person by calling:

```text
POST /api/events/{event_id}/authorize-person
```

Body:

```json
{
  "full_name": "Person Name",
  "role": "student",
  "notes": "Authorized by admin from mobile alert"
}
```

This creates a new authorized `Person`, links it to the event, and acknowledges the event.

## Camera View

The backend exposes the laptop webcam as:

```text
GET /api/camera/snapshot
GET /api/camera/stream
```

For Flutter Web:

```text
http://127.0.0.1:8000/api/camera/stream
```

For Android Emulator:

```text
http://10.0.2.2:8000/api/camera/stream
```

Only one process may be able to use the laptop webcam at a time. If the detection pipeline is already using the webcam, the stream endpoint may fail until the pipeline stops.
