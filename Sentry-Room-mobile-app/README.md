# Sentry Room Mobile

Flutter app for Sentry Room. This project currently supports Android, Windows, and Web for testing in Chrome or Edge.

## Folder Map

```text
lib/
├── main.dart            App startup, theme, providers
├── constants/           Backend URL setup
├── models/              Person, Event, SensorReading
├── services/            REST API, WebSocket alerts, notifications
├── providers/           AuthProvider and SentryProvider state
├── screens/             Login, dashboard, events, people, camera, users
└── widgets/             Camera stream widget
```

Kept platform folders:

```text
android/
windows/
web/
```

Normally edit `lib/`, not the platform folders, unless changing permissions or native settings.

## Backend URL

Defined in:

```text
lib/constants/api_constants.dart
```

Defaults:

- Windows: `http://127.0.0.1:8000`
- Web: `http://127.0.0.1:8000`
- Android emulator: `http://10.0.2.2:8000`
- Physical Android phone: pass your computer IP

Physical phone command:

```bash
flutter run --dart-define=SENTRY_API_BASE_URL=http://YOUR_COMPUTER_IP:8000
```

## Connected Backend Features

- Login/register: `/api/auth`
- Dashboard: `/api/live-status`
- People: `/api/persons`
- Events: `/api/events`
- Evidence snapshots: `/evidence`
- Camera stream: `/api/camera/stream`
- Live alerts: `/api/ws/alerts`

## Run

Start the backend from the parent folder first:

```bash
uvicorn app.main:app --reload
```

Then run Android, Windows, or Web:

```bash
flutter pub get
flutter run -d android
flutter run -d windows
flutter run -d chrome
```

## Check

```bash
flutter analyze
flutter test
```
