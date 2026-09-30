from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database.database import get_db
from app.models.profile import ElderlyProfile
from app.models.user import User


router = APIRouter(
    prefix="/api/v1/profile",
    tags=["Profile"]
)


@router.post("/link")
def link_elderly_to_caretaker(
    elderly_user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "caretaker":
        raise HTTPException(
            status_code=403,
            detail="Only caretakers can link an elderly user"
        )

    elderly_user = db.query(User).filter(
        User.user_id == elderly_user_id,
        User.role == "elderly"
    ).first()

    if not elderly_user:
        raise HTTPException(
            status_code=404,
            detail="Elderly user not found"
        )

    existing_profile = db.query(ElderlyProfile).filter(
        ElderlyProfile.user_id == elderly_user_id
    ).first()

    if existing_profile:
        existing_profile.caretaker_id = current_user.user_id
    else:
        profile = ElderlyProfile(
            user_id=elderly_user_id,
            caretaker_id=current_user.user_id
        )
        db.add(profile)

    db.commit()

    return {
        "message": "Elderly user linked successfully",
        "elderly_user_id": elderly_user_id,
        "caretaker_id": current_user.user_id
    }