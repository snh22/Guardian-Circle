from pydantic import BaseModel


class RiskInput(BaseModel):
    movement: str
    location_status: str
    trip_status: str
    event_type: str