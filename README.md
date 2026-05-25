# Sentry Room

Sentry Room is a restricted-room security system with a FastAPI backend, PostgreSQL database, AI face detection, camera/sensor integration, and a Flutter app for Android, Windows, and Web testing.

## Project Map

```text
Sentry-Room/
├── app/                         Backend API, database, services, AI, IoT
├── Sentry-Room-mobile-app/      Flutter app for Android, Windows, and Web
├── data/                        Evidence images and optional legacy face data
├── docs/                        Architecture, contracts, setup notes
└── scripts/                     Setup, import, camera, and pipeline commands
```

Read these first:

- `docs/architecture.md`: full project architecture
- `docs/mobile-backend-contract.md`: exact API contract used by the mobile app
- `docs/database-ai.md`: database tables and AI responsibilities
- `docs/postgresql-setup.md`: local PostgreSQL setup

## Backend

```text
app/
├── main.py              Creates FastAPI app, CORS, routes, evidence files
├── api/routes/          HTTP and WebSocket endpoints
├── core/                Config and database connection
├── models/              SQLAlchemy database tables
├── schemas/             Pydantic request/response models
├── services/            Business logic: detection, AI, storage, alerts
└── iot/                 Camera and sensor helpers
```

Backend layer rule:

```text
API routes -> services -> database models
```

## Mobile App

```text
Sentry-Room-mobile-app/lib/
├── main.dart
├── constants/           Backend URL configuration
├── models/              Dart data models
├── services/            HTTP API, WebSocket, notifications
├── providers/           App state
├── screens/             App pages
└── widgets/             Reusable UI
```

The mobile app talks only to the backend. It never connects directly to PostgreSQL.

## Main Flow

```text
Camera/Sensor
    ↓
FastAPI backend
    ↓
AI detection + PostgreSQL event
    ↓
Evidence image saved under data/evidence
    ↓
Mobile app receives WebSocket alert
    ↓
User acknowledges event or authorizes person
```

## Backend Setup

```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

Edit `.env` and set the correct PostgreSQL password:

```env
DATABASE_URL=postgresql+psycopg2://postgres:YOUR_PASSWORD@localhost:5432/sentry_room
```

Create tables:

```powershell
.\.venv\Scripts\python.exe scripts\create_tables.py
```

Start backend:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

Open:

```text
http://127.0.0.1:8000/docs
```

## Mobile Setup

```powershell
cd Sentry-Room-mobile-app
flutter pub get
flutter run
```

For a real phone:

```powershell
flutter run --dart-define=SENTRY_API_BASE_URL=http://YOUR_COMPUTER_IP:8000
```

## AI And Camera Setup

Install AI/camera dependencies only when needed:

```powershell
pip install -r requirements-ai.txt
```

Useful scripts:

```powershell
.\.venv\Scripts\python.exe scripts\register_person.py "Person Name"
.\.venv\Scripts\python.exe scripts\run_camera_pipeline.py
.\.venv\Scripts\python.exe scripts\debug_camera_faces.py
```

## Important Endpoints

- `GET /api/health`
- `GET /api/status`
- `GET /api/live-status`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/users`
- `GET /api/persons`
- `POST /api/persons/enroll-from-image`
- `GET /api/events`
- `POST /api/events/detection`
- `PATCH /api/events/{event_id}/acknowledge`
- `POST /api/events/{event_id}/authorize-person`
- `POST /api/sensor-readings`
- `GET /api/camera/snapshot`
- `GET /api/camera/stream`
- `WS /api/ws/alerts`
- `GET /evidence/...`

## Testing

Backend syntax check:

```powershell
python -m compileall app scripts
```

Mobile checks:

```powershell
cd Sentry-Room-mobile-app
flutter analyze
flutter test
```
