from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database.database import get_db
from app.models.trip import Trip
from app.models.user import User
from app.schemas.trip import TripCreate, TripUpdate, TripResponse


router = APIRouter(
    prefix="/api/v1/trips",
    tags=["Trips"]
)


@router.post("", response_model=TripResponse)
def create_trip(
    data: TripCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    trip = Trip(**data.dict())

    db.add(trip)
    db.commit()
    db.refresh(trip)

    return trip


@router.get(
    "/user/{user_id}",
    response_model=list[TripResponse]
)
def get_trips(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Trip).filter(
        Trip.user_id == user_id
    ).order_by(
        Trip.start_time.desc()
    ).all()


@router.get(
    "/{trip_id}",
    response_model=TripResponse
)
def get_trip(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    trip = db.query(Trip).filter(
        Trip.trip_id == trip_id
    ).first()

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found"
        )

    return trip


@router.put(
    "/{trip_id}",
    response_model=TripResponse
)
def update_trip(
    trip_id: int,
    data: TripUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    trip = db.query(Trip).filter(
        Trip.trip_id == trip_id
    ).first()

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found"
        )

    updates = data.dict(exclude_unset=True)

    for key, value in updates.items():
        setattr(trip, key, value)

    db.commit()
    db.refresh(trip)

    return trip


@router.delete("/{trip_id}")
def delete_trip(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    trip = db.query(Trip).filter(
        Trip.trip_id == trip_id
    ).first()

    if not trip:
        raise HTTPException(
            status_code=404,
            detail="Trip not found"
        )

    db.delete(trip)
    db.commit()

    return {
        "message": "Trip deleted successfully"
    }