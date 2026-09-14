from datetime import datetime

from pydantic import BaseModel


class EventCreate(BaseModel):
    user_id: int
    event_type: str
    risk_level: str


class EventResponse(EventCreate):
    event_id: int
    timestamp: datetime

    class Config:
        from_attributes = True