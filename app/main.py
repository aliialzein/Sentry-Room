import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI # type: ignore
from fastapi.middleware.cors import CORSMiddleware # type: ignore
from fastapi.staticfiles import StaticFiles # type: ignore

from app.api.router import api_router
from app.core.config import get_settings
from app.services import mqtt_bridge
from app.services.detection_worker import person_detection_worker
from app.services.pi_camera_stream import pi_camera_stream


@asynccontextmanager
async def lifespan(app: FastAPI):
    loop = asyncio.get_event_loop()
    mqtt_bridge.start(loop)
    pi_camera_stream.start()
    person_detection_worker.start(loop)
    try:
        yield
    finally:
        person_detection_worker.stop()
        pi_camera_stream.stop()


def create_app() -> FastAPI:
    settings = get_settings()
    fastapi_app = FastAPI(
        title=settings.app_name,
        description="Sentry Room IoT backend for detection events, enrollment, evidence, and live sensor status.",
        version="0.1.0",
        lifespan=lifespan,
    )
    fastapi_app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )
    fastapi_app.include_router(api_router)
    settings.evidence_dir.mkdir(parents=True, exist_ok=True)
    fastapi_app.mount("/evidence", StaticFiles(directory=settings.evidence_dir), name="evidence")

    @fastapi_app.get("/", tags=["health"])
    def root() -> dict[str, str]:
        return {
            "message": "Sentry Room Backend Running",
            "docs": "/docs",
        }

    return fastapi_app


app = create_app()
