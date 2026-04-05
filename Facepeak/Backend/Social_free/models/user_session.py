from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    DateTime,
    Boolean,
    Index,
    text,
    CheckConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid

from database import Base


class UserSession(Base):
    __tablename__ = "user_sessions"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    # mora odgovarati session_id iz refresh token modela
    session_id = Column(
        UUID(as_uuid=True),
        nullable=False,
        default=uuid.uuid4,
        unique=True,
        index=True
    )

    # session classification
    device_name = Column(
        String(120),
        nullable=True
    )

    device_type = Column(
        String(50),
        nullable=True
    )
    # mobile, web, tablet, desktop

    platform = Column(
        String(50),
        nullable=True
    )
    # ios, android, web, windows, macos

    user_agent = Column(
        String(512),
        nullable=True
    )

    ip_address = Column(
        String(45),
        nullable=True
    )

    country_code = Column(
        String(8),
        nullable=True
    )

    # state
    is_active = Column(
        Boolean,
        nullable=False,
        server_default=text("true"),
        index=True
    )

    is_current = Column(
        Boolean,
        nullable=False,
        server_default=text("false")
    )
    # opcionalno za UI: current device

    is_trusted = Column(
        Boolean,
        nullable=False,
        server_default=text("false")
    )

    is_compromised = Column(
        Boolean,
        nullable=False,
        server_default=text("false"),
        index=True
    )

    revoked_reason = Column(
        String(100),
        nullable=True
    )
    # logout, password_change, admin_revoked, token_reuse_detected

    # activity
    last_seen_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True
    )

    last_refresh_at = Column(
        DateTime(timezone=True),
        nullable=True
    )

    expires_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True
    )

    # timestamps
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    revoked_at = Column(
        DateTime(timezone=True),
        nullable=True
    )

    compromised_at = Column(
        DateTime(timezone=True),
        nullable=True
    )

    # relations
    user = relationship(
        "User",
        back_populates="sessions"
    )

    __table_args__ = (
        CheckConstraint(
            "country_code IS NULL OR length(country_code) <= 8",
            name="check_user_session_country_code_len"
        ),
        Index("idx_user_session_user_active", "user_id", "is_active"),
        Index("idx_user_session_user_last_seen", "user_id", "last_seen_at"),
        Index("idx_user_session_user_compromised", "user_id", "is_compromised"),
        Index("idx_user_session_user_created", "user_id", "created_at"),
    )