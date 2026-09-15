from datetime import datetime, timezone
from uuid import uuid4

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="Guardian Circle Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

latest_event = None

# ============================================================
# GUARDIAN CIRCLE CONFIGURATION
# ============================================================

guardian_circle_range = 10.0

allowed_guardian_circle_ranges = {
    5.0,
    10.0,
    15.0,
    20.0,
}


class GuardianCircleRequest(BaseModel):
    radius: float


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():
    return {
        "status": "Guardian Circle backend is running"
    }


# ============================================================
# FALL DETECTION
# ============================================================

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


# ============================================================
# LATEST EVENT
# ============================================================

@app.get("/latest")
def get_latest_event():
    if latest_event is None:
        return {
            "status": "none"
        }

    return latest_event


# ============================================================
# ACKNOWLEDGE EVENT
# ============================================================

@app.post("/acknowledge")
def acknowledge_event():
    global latest_event

    latest_event = None

    return {
        "status": "acknowledged"
    }


# ============================================================
# GUARDIAN CIRCLE
# ============================================================

@app.get("/guardian-circle")
def get_guardian_circle():
    return {
        "status": "success",
        "radius": guardian_circle_range,
        "unit": "metres",
    }


@app.post("/guardian-circle")
def set_guardian_circle(
    request: GuardianCircleRequest,
):
    global guardian_circle_range

    if request.radius not in allowed_guardian_circle_ranges:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid Guardian Circle radius. "
                "Allowed values are 5, 10, 15, and 20 metres."
            ),
        )

    guardian_circle_range = request.radius

    return {
        "status": "updated",
        "radius": guardian_circle_range,
        "unit": "metres",
    }
