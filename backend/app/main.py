from fastapi import FastAPI

from app.core.config import settings
from app.database.database import Base, engine
from app.database import base

from app.routes import (
    auth,
    users,
    location,
    trips,
    events,
    alerts,
    risk
)


# Create database tables
Base.metadata.create_all(bind=engine)


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Context-aware safety monitoring backend for elderly users"
)


# Include API routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(location.router)
app.include_router(trips.router)
app.include_router(events.router)
app.include_router(alerts.router)
app.include_router(risk.router)


@app.get("/")
def root():
    return {
        "message": "Guardian Circle Backend API",
        "status": "running"
    }


@app.get("/health")
def health():
    return {
        "status": "healthy"
    }