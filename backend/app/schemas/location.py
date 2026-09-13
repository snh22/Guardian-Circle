from datetime import datetime

from pydantic import BaseModel


class LocationCreate(BaseModel):
    user_id: int
    latitude: float
    longitude: float


class LocationResponse(LocationCreate):
    location_id: int
    timestamp: datetime

    class Config:
        from_attributes = True