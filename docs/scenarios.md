# Sentry Room Scenarios

## Core Entry Scenarios

1. **Idle monitoring**: the Raspberry Pi keeps reading camera, motion, temperature/humidity, and distance data. The mobile app shows the system as online.
2. **Motion detected, no face visible**: motion or distance changes are logged as a warning with the latest sensor payload and snapshot for review.
3. **Authorized person detected**: the face matches an authorized enrolled person. The event is saved silently as `authorized_entry`.
4. **Unknown person detected**: the face does not match any authorized person. The event is saved as `unauthorized_entry`, a snapshot is stored, and app/email alert rows are created.
5. **Multiple people detected**: if every visible face is authorized, the entry is logged. If any face is unknown, the whole event is treated as unauthorized.
6. **Low-quality frame**: if the face cannot be encoded because of blur, light, or angle, the system logs a warning and stores evidence for manual review.

## Enrollment And Access Control

7. **Enroll person from mobile/upload**: the app sends a face image; the backend extracts one face encoding and stores the person as authorized.
8. **Enroll person from Raspberry Pi camera**: an admin runs the camera enrollment script; the encoding and enrollment image are saved to PostgreSQL.
9. **Revoke access**: an admin sets `is_authorized=false`; future detections for that person become unauthorized.
10. **Import legacy registrations**: old `faces_db.pkl` records are imported into PostgreSQL through `scripts/import_legacy_faces.py`.

## Sensor And Alert Scenarios

11. **Temperature/humidity abnormal**: temperature or humidity values outside configured thresholds create an `environmental_alert`.
12. **Distance anomaly**: a close distance reading without a recognized person is logged as suspicious movement.
13. **Camera offline**: camera failure creates a `sensor_fault` event so the app can show degraded status.
14. **Database temporarily unavailable**: the Pi should buffer snapshots/events locally and retry when PostgreSQL returns.
15. **Alert delivery failure**: failed app/email delivery is stored in `alert_deliveries` for retry.
16. **Event acknowledged**: a mobile user acknowledges an alert so it remains in history but stops showing as active.
