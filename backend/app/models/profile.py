from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.database.database import Base


class ElderlyProfile(Base):
    __tablename__ = "elderly_profiles"

    profile_id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True
    )

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.user_id"),
        nullable=False
    )

    caretaker_id: Mapped[int] = mapped_column(
        ForeignKey("users.user_id"),
        nullable=False
    )