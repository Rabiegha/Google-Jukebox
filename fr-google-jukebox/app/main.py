from contextlib import asynccontextmanager
import time

from fastapi.responses import StreamingResponse
import uvicorn
from asgi_correlation_id import CorrelationIdMiddleware
from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware
from starlette_context.middleware import RawContextMiddleware

from app.api.deps import raise_500
from app.api.router import api_router
from app.core.cloud_logging import LoggingMiddleware
from app.core.config import settings
from app.middleware import ExceptionMiddleware, LoggingMiddlewareReq, MetricMiddleware
from app.music.models.prompt import PromptMusic
from app.music.service.generative_ai import MusicGenerator


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_PREFIX}/openapi.json",
    docs_url=f"{settings.API_PREFIX}/docs",
    redoc_url=f"{settings.API_PREFIX}/redoc",
)


# Set all CORS enabled origins
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.add_middleware(LoggingMiddleware)
app.add_middleware(ExceptionMiddleware)
# app.add_middleware(LoggingMiddlewareReq)
app.add_middleware(MetricMiddleware)
app.add_middleware(RawContextMiddleware)
app.add_middleware(CorrelationIdMiddleware)


app.include_router(api_router, prefix=settings.API_PREFIX)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
