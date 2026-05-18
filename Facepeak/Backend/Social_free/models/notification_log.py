from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    Text,
    ForeignKey,
    Index,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # message, follow, match, chat_limit_reset, rescore_available, premium_teaser...
    type = Column(String(60), nullable=False, index=True)

    # unique key for dedupe:
    # message:message_id
    # follow:follower_id:following_id:day
    # match:match_id
    # chat_limit_reset:user_id:reset_at
    dedupe_key = Column(String(255), nullable=False)

    title = Column(String(120), nullable=False)
    body = Column(String(255), nullable=False)

    # deeplink/action data
    data = Column(
        JSONB,
        nullable=False,
        server_default=text("'{}'::jsonb"),
    )

    # pending, sent, skipped, failed
    status = Column(
        String(30),
        nullable=False,
        default="pending",
        server_default=text("'pending'"),
        index=True,
    )

    # For scheduled notifications.
    send_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )

    sent_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )

    skipped_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    failed_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    error = Column(Text, nullable=True)

    attempts = Column(
        Integer,
        nullable=False,
        default=0,
        server_default=text("0"),
    )

    max_attempts = Column(
        Integer,
        nullable=False,
        default=3,
        server_default=text("3"),
    )

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        index=True,
    )

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    user = relationship("User")

    __table_args__ = (
        UniqueConstraint(
            "dedupe_key",
            name="uq_notification_logs_dedupe_key",
        ),

        Index(
            "idx_notification_user_type_created",
            "user_id",
            "type",
            "created_at",
        ),

        Index(
            "idx_notification_pending_send_at",
            "status",
            "send_at",
        ),

        Index(
            "idx_notification_user_status",
            "user_id",
            "status",
        ),
    )