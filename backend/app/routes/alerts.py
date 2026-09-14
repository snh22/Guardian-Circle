from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.database.database import get_db
from app.models.alert import Alert
from app.models.user import User
from app.services.notification import get_notification_action


router = APIRouter(
    prefix="/api/v1/alerts",
    tags=["Alerts"]
)


@router.post("")
def create_alert(
    user_id: int,
    risk_level: str,
    reason: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    alert = Alert(
        user_id=user_id,
        risk_level=risk_level.upper(),
        reason=reason,
        status="active"
    )

    db.add(alert)
    db.commit()
    db.refresh(alert)

    return {
        "alert_id": alert.alert_id,
        "user_id": alert.user_id,
        "risk_level": alert.risk_level,
        "reason": alert.reason,
        "status": alert.status,
        "recommended_action": get_notification_action(
            alert.risk_level
        ),
        "timestamp": alert.timestamp
    }


@router.get("/user/{user_id}")
def get_alerts(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Alert).filter(
        Alert.user_id == user_id
    ).order_by(
        Alert.timestamp.desc()
    ).all()


@router.put("/{alert_id}/resolve")
def resolve_alert(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    alert = db.query(Alert).filter(
        Alert.alert_id == alert_id
    ).first()

    if not alert:
        raise HTTPException(
            status_code=404,
            detail="Alert not found"
        )

    alert.status = "resolved"

    db.commit()
    db.refresh(alert)

    return {
        "message": "Alert resolved successfully",
        "alert_id": alert.alert_id,
        "status": alert.status
    }