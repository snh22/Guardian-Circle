from fastapi import APIRouter

from app.schemas.risk import RiskInput
from app.services.risk_engine import calculate_risk


router = APIRouter(
    prefix="/api/v1/risk",
    tags=["Risk Analysis"]
)


@router.post("/analyze")
def analyze_risk(data: RiskInput):
    return calculate_risk(
        movement=data.movement,
        location_status=data.location_status,
        trip_status=data.trip_status,
        event_type=data.event_type
    )