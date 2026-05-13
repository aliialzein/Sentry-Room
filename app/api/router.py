from fastapi import APIRouter

from app.api.routes import events, health, persons, sensors, settings


api_router = APIRouter(prefix="/api")
api_router.include_router(health.router, tags=["health"])
api_router.include_router(persons.router, prefix="/persons", tags=["persons"])
api_router.include_router(events.router, prefix="/events", tags=["events"])
api_router.include_router(sensors.router, prefix="/sensor-readings", tags=["sensor-readings"])
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])
