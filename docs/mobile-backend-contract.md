# Mobile And Backend Contract

This file lists what the Flutter app expects from the FastAPI backend.

## Base URLs

Default URLs are handled in:

```text
Sentry-Room-mobile-app/lib/constants/api_constants.dart
```

```text
Windows           http://127.0.0.1:8000
Web               http://127.0.0.1:8000
Android emulator  http://10.0.2.2:8000
Physical phone    --dart-define=SENTRY_API_BASE_URL=http://YOUR_IP:8000
```

## Auth

### Register

```http
POST /api/auth/register
```

Request:

```json
{
  "username": "ali",
  "email": "ali@example.com",
  "password": "secret123",
  "full_name": "Ali"
}
```

Response:

```json
{
  "user": {
    "id": 1,
    "username": "ali",
    "email": "ali@example.com",
    "full_name": "Ali",
    "role": "admin",
    "is_admin": true,
    "is_active": true,
    "created_at": "...",
    "updated_at": "..."
  },
  "message": "User registered successfully."
}
```

### Login

```http
POST /api/auth/login
```

Request:

```json
{
  "identifier": "ali",
  "password": "secret123"
}
```

## Dashboard

```http
GET /api/live-status
```

The mobile dashboard expects:

```json
{
  "api": "online",
  "database": "online",
  "latest_readings": {
    "temperature_humidity": {
      "temperature_c": 24.0,
      "humidity_percent": 50.0
    },
    "distance": {
      "distance_cm": 120.0
    }
  },
  "active_unacknowledged_events": 0
}
```

## People

```http
GET /api/persons
POST /api/persons
PATCH /api/persons/{person_id}
POST /api/persons/enroll-from-image
```

The mobile app displays:

```json
{
  "id": 1,
  "full_name": "Ali",
  "role": "Student",
  "is_authorized": true,
  "image_path": "data/evidence/enrollments/image.jpg",
  "notes": null,
  "created_at": "...",
  "updated_at": "..."
}
```

## Events

```http
GET /api/events
POST /api/events/detection
PATCH /api/events/{event_id}/acknowledge
POST /api/events/{event_id}/authorize-person
```

The app expects each event to include:

```json
{
  "id": 10,
  "event_type": "unauthorized_entry",
  "severity": "critical",
  "message": "Unauthorized person detected.",
  "person_id": null,
  "confidence": null,
  "snapshot_path": "data/evidence/events/detection_....jpg",
  "sensor_payload": {},
  "is_acknowledged": false,
  "created_at": "..."
}
```

## Camera

```http
GET /api/camera/snapshot
GET /api/camera/stream
```

The stream endpoint returns MJPEG frames.

## Evidence

```http
GET /evidence/{folder}/{filename}
```

The backend stores paths like:

```text
data/evidence/events/detection_....jpg
```

The mobile app converts that to:

```text
http://BACKEND/evidence/events/detection_....jpg
```

## Live Alerts

```text
ws://BACKEND/api/ws/alerts
```

Message:

```json
{
  "type": "unauthorized_entry",
  "severity": "critical",
  "message": "Unauthorized person detected.",
  "event_id": 10,
  "snapshot_path": "data/evidence/events/detection_....jpg"
}
```
