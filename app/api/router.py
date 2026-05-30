from fastapi import APIRouter

from app.api.routes import auth, camera, emergency, events, health, persons, sensors, settings, users, ws


api_router = APIRouter(prefix="/api")
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(camera.router, prefix="/camera", tags=["camera"])
api_router.include_router(persons.router, prefix="/persons", tags=["persons"])
api_router.include_router(events.router, prefix="/events", tags=["events"])
api_router.include_router(sensors.router, prefix="/sensor-readings", tags=["sensor-readings"])
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])
api_router.include_router(emergency.router, prefix="/emergency-incidents", tags=["emergency-incidents"])
api_router.include_router(ws.router, prefix="/ws", tags=["websocket"])
