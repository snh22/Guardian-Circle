from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database.database import Base


class SafeZone(Base):
    __tablename__ = "safe_zones"

    zone_id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.user_id"),
        nullable=False
    )

    name: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    latitude: Mapped[float] = mapped_column(
        nullable=False
    )

    longitude: Mapped[float] = mapped_column(
        nullable=False
    )

    radius: Mapped[float] = mapped_column(
        nullable=False
    )