from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    DateTime,
    Boolean,
    Index,
    text,
    CheckConstraint,
    UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship, backref
import uuid

from database import Base


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    # SHA256(raw_refresh_token)
    token_hash = Column(
        String(64),
        nullable=False,
        unique=True,
        index=True
    )

    # svi tokeni iz istog login/rotation lanca
    token_family = Column(
        UUID(as_uuid=True),
        nullable=False,
        default=uuid.uuid4,
        index=True
    )

    # jedan uređaj / browser session
    session_id = Column(
        UUID(as_uuid=True),
        nullable=False,
        default=uuid.uuid4,
        index=True
    )

    # rotation chain
    parent_token_id = Column(
        Integer,
        ForeignKey("refresh_tokens.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    replaced_by_token_id = Column(
        Integer,
        ForeignKey("refresh_tokens.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
        index=True
    )

    # device / security metadata
    device_name = Column(
        String(120),
        nullable=True
    )

    device_type = Column(
        String(50),
        nullable=True
    )

    ip_address = Column(
        String(45),
        nullable=True
    )

    user_agent = Column(
        String(512),
        nullable=True
    )

    # state
    is_revoked = Column(
        Boolean,
        nullable=False,
        server_default=text("false"),
        index=True
    )

    reuse_detected = Column(
        Boolean,
        nullable=False,
        server_default=text("false"),
        index=True
    )

    revoked_reason = Column(
        String(100),
        nullable=True
    )

    # hash tokena koji je kasnije pokušao reuse attack
    reused_token_hash = Column(
        String(64),
        nullable=True
    )

    compromised_at = Column(
        DateTime(timezone=True),
        nullable=True
    )

    # snapshot user token versiona u trenutku izdavanja
    invalidated_by_user_version = Column(
        Integer,
        nullable=False,
        server_default=text("0")
    )

    # lifecycle
    issued_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    # kada je ovaj refresh token iskorišten za rotation
    used_at = Column(
        DateTime(timezone=True),
        nullable=True
    )

    expires_at = Column(
        DateTime(timezone=True),
        nullable=False,
        index=True
    )

    revoked_at = Column(
        DateTime(timezone=True),
        nullable=True
    )

    # relationships
    user = relationship(
        "User",
        back_populates="refresh_tokens"
    )

    parent_token = relationship(
        "RefreshToken",
        foreign_keys=[parent_token_id],
        remote_side=[id],
        backref=backref("child_tokens", lazy="selectin")
    )

    replaced_by_token = relationship(
        "RefreshToken",
        foreign_keys=[replaced_by_token_id],
        remote_side=[id]
    )

    __table_args__ = (
        # jedan token ne može zamijeniti sam sebe
        CheckConstraint(
            "parent_token_id IS NULL OR parent_token_id != id",
            name="check_refresh_parent_not_self"
        ),
        CheckConstraint(
            "replaced_by_token_id IS NULL OR replaced_by_token_id != id",
            name="check_refresh_replaced_not_self"
        ),
        CheckConstraint(
            "invalidated_by_user_version >= 0",
            name="check_refresh_user_version_nonnegative"
        ),
        UniqueConstraint(
            "user_id",
            "session_id",
            "token_hash",
            name="uq_refresh_user_session_token"
        ),
        Index("idx_refresh_user_session", "user_id", "session_id"),
        Index("idx_refresh_user_family", "user_id", "token_family"),
        Index("idx_refresh_family_revoked", "token_family", "is_revoked"),
        Index("idx_refresh_session_revoked", "session_id", "is_revoked"),
        Index("idx_refresh_user_version", "user_id", "invalidated_by_user_version"),
        Index("idx_refresh_user_expires", "user_id", "expires_at"),
    )