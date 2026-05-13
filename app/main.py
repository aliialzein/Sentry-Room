from fastapi import FastAPI

from app.api.router import api_router
from app.core.config import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    fastapi_app = FastAPI(
        title=settings.app_name,
        description="Sentry Room IoT backend for detection events, enrollment, evidence, and live sensor status.",
        version="0.1.0",
    )
    fastapi_app.include_router(api_router)

    @fastapi_app.get("/", tags=["health"])
    def root() -> dict[str, str]:
        return {
            "message": "Sentry Room Backend Running",
            "docs": "/docs",
        }

    return fastapi_app


app = create_app()
