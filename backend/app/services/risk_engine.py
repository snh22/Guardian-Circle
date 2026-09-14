from typing import Dict


def calculate_risk(
    movement: str,
    location_status: str,
    trip_status: str,
    event_type: str
) -> Dict:

    movement = movement.lower()
    location_status = location_status.lower()
    trip_status = trip_status.lower()
    event_type = event_type.lower()

    reasons = []

    # SOS is always critical
    if event_type == "sos":
        return {
            "risk_level": "CRITICAL",
            "reason": ["SOS event detected"],
            "recommended_action": "Immediate caregiver attention"
        }

    # Check movement
    if movement == "unusual":
        reasons.append(
            "Movement differs from expected activity"
        )

    # Check location
    if location_status == "unexpected":
        reasons.append(
            "Current location is outside expected context"
        )

    # Check trip
    if trip_status == "not planned":
        reasons.append(
            "No planned trip matches current activity"
        )

    # Two or more unusual conditions
    if len(reasons) >= 2:
        return {
            "risk_level": "HIGH",
            "reason": reasons,
            "recommended_action": "Send caregiver alert"
        }

    # One unusual condition
    if len(reasons) == 1:
        return {
            "risk_level": "MEDIUM",
            "reason": reasons,
            "recommended_action": "Consider soft check-in"
        }

    # Everything appears normal
    return {
        "risk_level": "LOW",
        "reason": [
            "Activity appears consistent with expected context"
        ],
        "recommended_action": "Continue monitoring"
    }