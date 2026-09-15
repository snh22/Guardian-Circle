from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from jose import JWTError, jwt
from passlib.context import CryptContext


app = FastAPI(title="Guardian Circle Backend")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# AUTHENTICATION
# ============================================================

SECRET_KEY = "guardian-circle-development-secret-key"
ALGORITHM = "HS256"
TOKEN_EXPIRE_MINUTES = 60 * 24

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
)


# Prototype caregiver account.
# We will move this to a database later.
DEMO_USER = {
    "user_id": 1,
    "name": "Guardian Caregiver",
    "email": "caregiver@guardian.com",
    "password_hash": pwd_context.hash("guardian123"),
    "role": "caretaker",
}


class LoginRequest(BaseModel):
    email: str
    password: str


def create_access_token(user_id: int) -> str:
    expires = datetime.now(timezone.utc) + timedelta(
        minutes=TOKEN_EXPIRE_MINUTES
    )

    payload = {
        "sub": str(user_id),
        "exp": expires,
    }

    return jwt.encode(
        payload,
        SECRET_KEY,
        algorithm=ALGORITHM,
    )


def get_current_user(
    authorization: str | None,
):
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Missing authorization header",
        )

    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Invalid authorization header",
        )

    token = authorization.replace(
        "Bearer ",
        "",
        1,
    )

    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM],
        )

        user_id = int(payload["sub"])

    except (JWTError, ValueError, KeyError):
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token",
        )

    if user_id != DEMO_USER["user_id"]:
        raise HTTPException(
            status_code=401,
            detail="User not found",
        )

    return DEMO_USER


# ============================================================
# DATA MODELS
# ============================================================


class GuardianCircleRequest(BaseModel):
    radius: float


class LocationRequest(BaseModel):
    user_id: int
    latitude: float
    longitude: float


class TripRequest(BaseModel):
    user_id: int
    destination: str
    start_time: str
    status: str = "planned"


class TripUpdateRequest(BaseModel):
    destination: str | None = None
    start_time: str | None = None
    status: str | None = None


# ============================================================
# GLOBAL STATE
# ============================================================

latest_event = None

guardian_circle_range = 10.0

allowed_guardian_circle_ranges = {
    5.0,
    10.0,
    15.0,
    20.0,
}

locations = {}

trips = {}

events = []


# ============================================================
# ROOT
# ============================================================


@app.get("/")
def root():
    return {
        "status": "Guardian Circle backend is running"
    }


# ============================================================
# AUTH
# ============================================================


@app.post("/api/v1/auth/login")
def login(request: LoginRequest):

    if request.email.lower() != DEMO_USER["email"]:
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password.",
        )

    if not pwd_context.verify(
        request.password,
        DEMO_USER["password_hash"],
    ):
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password.",
        )

    token = create_access_token(
        DEMO_USER["user_id"]
    )

    return {
        "access_token": token,
        "token_type": "bearer",
    }


# ============================================================
# USERS
# ============================================================


@app.get("/api/v1/users/me")
def get_current_user_profile(
    authorization: str | None = Header(default=None),
):

    user = get_current_user(authorization)

    return {
        "user_id": user["user_id"],
        "name": user["name"],
        "email": user["email"],
        "role": user["role"],
    }


@app.get("/api/v1/users/{user_id}")
def get_user(
    user_id: int,
    authorization: str | None = Header(default=None),
):

    get_current_user(authorization)

    if user_id != DEMO_USER["user_id"]:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )

    return {
        "user_id": DEMO_USER["user_id"],
        "name": DEMO_USER["name"],
        "email": DEMO_USER["email"],
        "role": DEMO_USER["role"],
    }


# ============================================================
# FALL DETECTION
# ============================================================


@app.post("/fall")
def fall_detected():

    global latest_event

    event = {
        "status": "received",
        "event": "fall",
        "risk": "critical",
        "event_id": str(uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    latest_event = event

    events.append({
        "event_id": event["event_id"],
        "user_id": 1,
        "event_type": "fall",
        "risk_level": "CRITICAL",
        "timestamp": event["timestamp"],
    })

    return event


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
# EVENTS
# ============================================================


@app.get("/api/v1/events/user/{user_id}")
def get_events_for_user(
    user_id: int,
    authorization: str | None = Header(default=None),
):

    get_current_user(authorization)

    user_events = [
        event
        for event in events
        if event["user_id"] == user_id
    ]

    return user_events


# ============================================================
# RISK ANALYSIS
# ============================================================


class RiskRequest(BaseModel):
    movement: str
    location_status: str
    trip_status: str
    event_type: str


@app.post("/api/v1/risk/analyze")
def analyze_risk(
    request: RiskRequest,
):

    event_type = request.event_type.lower()
    movement = request.movement.lower()
    location_status = request.location_status.lower()
    trip_status = request.trip_status.lower()

    reasons = []

    if event_type == "fall":
        risk_level = "CRITICAL"
        reasons.append("Fall detected.")

    elif location_status in {
        "outside",
        "unsafe",
        "unknown",
    }:
        risk_level = "HIGH"
        reasons.append(
            "Patient is outside the safe location."
        )

    elif movement in {
        "abnormal",
        "low",
        "none",
    }:
        risk_level = "MEDIUM"
        reasons.append(
            "Patient movement appears abnormal."
        )

    else:
        risk_level = "LOW"
        reasons.append(
            "No immediate safety risk detected."
        )

    if trip_status == "overdue":
        risk_level = "HIGH"
        reasons.append(
            "Planned trip is overdue."
        )

    actions = {
        "LOW": "Continue monitoring.",
        "MEDIUM": "Check the patient's status.",
        "HIGH": "Contact the patient.",
        "CRITICAL": "Contact the patient immediately.",
    }

    return {
        "risk_level": risk_level,
        "reason": reasons,
        "recommended_action": actions[risk_level],
    }


# ============================================================
# LOCATION
# ============================================================


@app.post("/api/v1/location")
def post_location(
    request: LocationRequest,
):

    get_current_user_from_optional_location_request(
        request.user_id
    )

    locations[request.user_id] = {
        "user_id": request.user_id,
        "latitude": request.latitude,
        "longitude": request.longitude,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    return {
        "status": "received"
    }


def get_current_user_from_optional_location_request(
    user_id: int,
):

    if user_id != DEMO_USER["user_id"]:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )


@app.get("/api/v1/location/latest/{user_id}")
def get_latest_location(
    user_id: int,
    authorization: str | None = Header(default=None),
):

    get_current_user(authorization)

    location = locations.get(user_id)

    if location is None:
        raise HTTPException(
            status_code=404,
            detail="No location available",
        )

    return location


# ============================================================
# TRIPS
# ============================================================


@app.post("/api/v1/trips")
def create_trip(
    request: TripRequest,
    authorization: str | None = Header(default=None),
):

    get_current_user(authorization)

    trip_id = len(trips) + 1

    trip = {
        "trip_id": trip_id,
        "user_id": request.user_id,
        "destination": request.destination,
        "start_time": request.start_time,
        "status": request.status,
    }

    trips[trip_id] = trip

    return trip


@app.get("/api/v1/trips/user/{user_id}")
def get_trips_for_user(
    user_id: int,
    authorization: str | None = Header(default=None),
):

    get_current_user(authorization)

    return [
        trip
        for trip in trips.values()
        if trip["user_id"] == user_id
    ]


@app.put("/api/v1/trips/{trip_id}")
def update_trip(
    trip_id: int,
    request: TripUpdateRequest,
    authorization: str | None = Header(default=None),
):

    get_current_user(authorization)

    if trip_id not in trips:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    trip = trips[trip_id]

    if request.destination is not None:
        trip["destination"] = request.destination

    if request.start_time is not None:
        trip["start_time"] = request.start_time

    if request.status is not None:
        trip["status"] = request.status

    return trip


@app.delete("/api/v1/trips/{trip_id}")
def delete_trip(
    trip_id: int,
    authorization: str | None = Header(default=None),
):

    get_current_user(authorization)

    if trip_id not in trips:
        raise HTTPException(
            status_code=404,
            detail="Trip not found",
        )

    del trips[trip_id]

    return {
        "status": "deleted"
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
