from sqlalchemy import Column, Integer, Boolean, ForeignKey, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class UserSettings(Base):
    __tablename__ = "user_settings"

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True
    )

    # 🔒 PRIVACY
    is_private = Column(
        Boolean,
        default=True,
        nullable=False
    )

    # 🔔 NOTIFICATIONS (optional kasnije)
    notifications_enabled = Column(
        Boolean,
        default=True,
        nullable=False
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    updated_at = Column(
        DateTime(timezone=True),
        onupdate=func.now()
    )

    # RELATIONSHIP
    user = relationship(
        "User",
        back_populates="settings",
        uselist=False
    )