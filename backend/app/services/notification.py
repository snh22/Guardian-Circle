def get_notification_action(risk_level: str):
    actions = {
        "LOW": "Continue monitoring",
        "MEDIUM": "Consider soft check-in",
        "HIGH": "Send caregiver alert",
        "CRITICAL": "Immediate caregiver attention"
    }

    return actions.get(
        risk_level.upper(),
        "Review situation"
    )