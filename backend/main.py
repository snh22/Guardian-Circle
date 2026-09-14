from datetime import datetime, timezone
from uuid import uuid4

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Guardian Circle Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

latest_event = None


@app.get("/")
def root():
    return {"status": "Guardian Circle backend is running"}


@app.post("/fall")
def fall_detected():
    global latest_event

    latest_event = {
        "status": "received",
        "event": "fall",
        "risk": "critical",
        "event_id": str(uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    return latest_event


@app.get("/latest")
def get_latest_event():
    if latest_event is None:
        return {
            "status": "none"
        }

    return latest_event


@app.post("/acknowledge")
def acknowledge_event():
    global latest_event

    latest_event = None

    return {
        "status": "acknowledged"
    }