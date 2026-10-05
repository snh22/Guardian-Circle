from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database.database import get_db
from app.models.event import Event
from app.models.alert import Alert
from app.models.user import User
from app.schemas.event import EventCreate, EventResponse


router = APIRouter(
    prefix="/api/v1/events",
    tags=["Events"]
)


@router.post("", response_model=EventResponse)
def create_event(
    data: EventCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    event = Event(**data.dict())

    db.add(event)
    db.commit()
    db.refresh(event)

    # Automatically create a caretaker alert for critical fall events.
    if (
        data.event_type.lower() == "fall"
        and data.risk_level.lower() == "critical"
    ):
        alert = Alert(
            user_id=1,
            risk_level="CRITICAL",
            reason="Fall detected by patient sensor",
            status="active",
        )

        db.add(alert)
        db.commit()

    return event


@router.get(
    "/user/{user_id}",
    response_model=list[EventResponse]
)
def get_events(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Event).filter(
        Event.user_id == user_id
    ).order_by(
        Event.timestamp.desc()
    ).all()


@router.get(
    "/{event_id}",
    response_model=EventResponse
)
def get_event(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    event = db.query(Event).filter(
        Event.event_id == event_id
    ).first()

    if not event:
        raise HTTPException(
            status_code=404,
            detail="Event not found"
        )

    return event
