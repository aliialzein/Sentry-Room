# Database And AI Notes

## Database Ownership

Only the backend talks to PostgreSQL.

```text
Mobile app -> FastAPI backend -> PostgreSQL
```

The mobile app must never connect directly to the database.

## Tables

`users`

Stores mobile app accounts. Used for login/register and admin management.

`persons`

Stores known people. A person can be authorized or not authorized. Face encodings are stored here.

`access_events`

Stores security events such as:

```text
authorized_entry
unauthorized_entry
motion_detected
environmental_alert
sensor_fault
system_event
```

`sensor_readings`

Stores sensor values sent by the Raspberry Pi or simulator.

`alert_deliveries`

Tracks app/email alerts created for important events.

`system_settings`

Stores thresholds and settings such as temperature, humidity, or distance limits.

## AI Boundary

The AI code is intentionally separate from API routes.

```text
app/services/recognition.py
```

Does:

- Load image bytes
- Find faces
- Create face encodings
- Compare one face encoding against known faces

```text
app/services/detection.py
```

Does:

- Save the captured image
- Ask the recognition service for detected faces
- Load authorized people from the database
- Decide whether the event is authorized, unauthorized, or motion/no-face
- Create alerts when needed

## Why AI Dependencies Are Separate

The backend can run basic API and database features without camera AI packages.

Install basic backend:

```bash
pip install -r requirements.txt
```

Install AI/camera tools only when needed:

```bash
pip install -r requirements-ai.txt
```

This keeps setup easier and avoids camera/face-recognition problems while testing normal mobile screens.

