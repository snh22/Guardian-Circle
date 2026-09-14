from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class TripCreate(BaseModel):
    user_id: int
    destination: str
    start_time: datetime
    status: str = "planned"


class TripUpdate(BaseModel):
    destination: Optional[str] = None
    start_time: Optional[datetime] = None
    status: Optional[str] = None


class TripResponse(TripCreate):
    trip_id: int

    class Config:
        from_attributes = True