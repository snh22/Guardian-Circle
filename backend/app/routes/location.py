from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database.database import get_db
from app.models.location import Location
from app.models.user import User
from app.schemas.location import LocationCreate, LocationResponse


router = APIRouter(
    prefix="/api/v1/location",
    tags=["Location"]
)


@router.post("", response_model=LocationResponse)
def create_location(
    data: LocationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    location = Location(
        user_id=data.user_id,
        latitude=data.latitude,
        longitude=data.longitude
    )

    db.add(location)
    db.commit()
    db.refresh(location)

    return location


@router.get(
    "/user/{user_id}",
    response_model=list[LocationResponse]
)
def get_locations(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Location).filter(
        Location.user_id == user_id
    ).order_by(
        Location.timestamp.desc()
    ).all()


@router.get(
    "/latest/{user_id}",
    response_model=LocationResponse
)
def get_latest_location(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    location = db.query(Location).filter(
        Location.user_id == user_id
    ).order_by(
        Location.timestamp.desc()
    ).first()

    if not location:
        raise HTTPException(
            status_code=404,
            detail="No location found"
        )

    return location