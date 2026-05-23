# Sentry Room Architecture

This project has four main parts:

```text
Sentry-Room/
├── app/                         Backend API, database models, services, AI, IoT
├── Sentry-Room-mobile-app/      Flutter app for Android, Windows, and Web
├── data/                        Evidence images and optional legacy face DB
├── docs/                        Project explanation and setup guides
└── scripts/                     Local setup, camera, and import commands
```

## 1. Backend

The backend is a FastAPI app.

```text
app/
├── main.py              Creates the FastAPI app, CORS, API routes, evidence files
├── api/                 HTTP and WebSocket endpoints
├── core/                Configuration and database connection
├── models/              SQLAlchemy database tables
├── schemas/             Pydantic request/response objects
├── services/            Business logic: AI, detection, storage, alerts, websocket
└── iot/                 Camera and sensor integration helpers
```

Layer rule:

```text
routes -> services -> models/database
```

Routes should stay thin. They receive requests, validate data, call a service, and return a response.

## 2. Mobile App

The mobile app is Flutter.

```text
Sentry-Room-mobile-app/lib/
├── main.dart            App startup, theme, providers
├── constants/           Backend URL configuration
├── models/              Mobile-side data models
├── services/            API, WebSocket, local notifications
├── providers/           App state and backend calls
├── screens/             Visible pages
└── widgets/             Reusable UI pieces
```

The app talks only to the backend. It does not connect directly to PostgreSQL or the camera hardware.

## 3. Platform Files

The project keeps these Flutter platform targets:

```text
Sentry-Room-mobile-app/android/
Sentry-Room-mobile-app/windows/
Sentry-Room-mobile-app/web/
```

The real app code is still in `lib/`.

Run Android:

```bash
flutter run -d android
```

Run Windows:

```bash
flutter run -d windows
```

Run Web:

```bash
flutter run -d chrome
```

For Android emulator, the app uses:

```text
http://10.0.2.2:8000
```

For Windows, it uses:

```text
http://127.0.0.1:8000
```

For Web, it also uses:

```text
http://127.0.0.1:8000
```

For a real phone, pass your computer IP:

```bash
flutter run --dart-define=SENTRY_API_BASE_URL=http://YOUR_COMPUTER_IP:8000
```

## 4. Database

PostgreSQL stores the permanent data.

Main tables:

```text
users             Mobile app accounts
persons           People known by the security system
access_events     Authorized/unauthorized/security events
sensor_readings   Temperature, humidity, distance, motion data
alert_deliveries  App/email alert delivery records
system_settings   Thresholds and runtime settings
```

The first registered user becomes `admin`. Later users become `viewer` until an admin changes their role.

## 5. AI

AI face detection is isolated in:

```text
app/services/recognition.py
app/services/detection.py
```

`recognition.py` handles face detection, face encoding, and matching.

`detection.py` decides what event to create:

```text
image -> detect faces -> compare authorized persons -> create event
```

AI dependencies are optional and live in:

```text
requirements-ai.txt
```

Install them only when testing camera enrollment or detection.

## 6. Evidence Files

Images are saved under:

```text
data/evidence/
```

The backend serves them through:

```text
/evidence/...
```

The mobile app receives `snapshot_path` from events and converts it to a full image URL.

## 7. Live Alerts

The backend exposes:

```text
/api/ws/alerts
```

The mobile app listens with `WebSocketService`. New events also refresh through polling every 10 seconds, so the app still works if WebSocket reconnects.

## Main Flow

```text
Camera/Sensor
    ↓
Backend API
    ↓
AI detection + database event
    ↓
Evidence saved to data/evidence
    ↓
WebSocket alert + mobile refresh
    ↓
Mobile user acknowledges or authorizes person
```
