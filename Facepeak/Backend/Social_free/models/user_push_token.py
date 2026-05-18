from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Index, text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class UserPushToken(Base):
    __tablename__ = "user_push_tokens"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    fcm_token = Column(String(512), nullable=False, unique=True, index=True)

    platform = Column(String(30), nullable=False, default="android", server_default="android")
    device_id = Column(String(255), nullable=True, index=True)

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        server_default=text("true"),
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    last_seen_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    user = relationship("User")

    __table_args__ = (
        Index("idx_push_user_active", "user_id", "is_active"),
        Index("idx_push_device", "user_id", "device_id"),
    )