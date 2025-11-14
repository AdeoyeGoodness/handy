from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.routes import auth, bookings, messages, services, users
from .core.config import get_settings
from .core.database import init_db

settings = get_settings()

init_db()

app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=settings.api_v1_prefix)
app.include_router(users.router, prefix=settings.api_v1_prefix)
app.include_router(services.router, prefix=settings.api_v1_prefix)
app.include_router(bookings.router, prefix=settings.api_v1_prefix)
app.include_router(messages.router, prefix=settings.api_v1_prefix)


@app.get("/healthz")
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}

