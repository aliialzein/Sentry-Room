# Sentry Room

Sentry Room is an AI-based restricted-room security system. A Raspberry Pi reads four hardware inputs, runs camera/person detection, stores evidence in PostgreSQL through a FastAPI backend, and exposes data to the mobile app.

## Architecture

- `app/main.py`: FastAPI application entry point.
- `app/api/routes`: HTTP endpoints for health, persons, events, sensor readings, and settings.
- `app/models`: SQLAlchemy PostgreSQL models for people, events, alerts, sensors, and settings.
- `app/schemas`: Pydantic request/response models for the mobile app and Raspberry Pi.
- `app/services`: face recognition, detection decisions, evidence storage, legacy face DB import, and alert creation.
- `app/iot`: Raspberry Pi camera/pipeline integration points and sensor provider abstractions.
- `scripts`: local operational scripts for creating tables, importing legacy faces, camera enrollment, and running the camera pipeline.
- `data/legacy/faces_db.pkl`: migrated legacy face database from `mobiot_mahmezharzein`.

## Main Flows

- Authorized entry: camera image -> face encoding -> authorized person match -> silent `authorized_entry` event.
- Unauthorized entry: camera image -> unknown face -> saved snapshot -> `unauthorized_entry` event -> pending app/email alert.
- Enrollment: mobile upload or Pi camera capture -> one face encoding -> `persons.face_encoding` in PostgreSQL.
- Sensor logging: Pi posts motion, distance, temperature, and humidity readings to `/api/sensor-readings`.
- Evidence browser: mobile app reads `/api/events` and uses `snapshot_path` to locate saved evidence.

## Legacy Migration

- `mobiot_mahmezharzein/faceperson.py` is now split into `app/services/recognition.py`, `app/services/detection.py`, and `scripts/run_camera_pipeline.py`.
- `mobiot_mahmezharzein/register_person.py` is now `scripts/register_person.py` with PostgreSQL storage.
- `mobiot_mahmezharzein/faces_db.pkl` was copied to `data/legacy/faces_db.pkl` and can be imported with `scripts/import_legacy_faces.py`.

## Setup

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python scripts/create_tables.py
uvicorn app.main:app --reload
```

Set `DATABASE_URL` in `.env` to your PostgreSQL database before creating tables.

## Useful Endpoints

- `GET /api/health`
- `GET /api/status`
- `GET /api/live-status`
- `POST /api/persons`
- `POST /api/persons/enroll-from-image`
- `POST /api/events/detection`
- `GET /api/events`
- `PATCH /api/events/{event_id}/acknowledge`
- `POST /api/sensor-readings`
- `GET /api/sensor-readings/recent`

See `docs/scenarios.md` for the complete project scenario list.
