from sqlalchemy import (
    Column,
    Integer,
    BigInteger,
    ForeignKey,
    DateTime,
    String,
    UniqueConstraint,
    Index,
    CheckConstraint,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class Follow(Base):
    __tablename__ = "follows"

    id = Column(BigInteger, primary_key=True, index=True)

    follower_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    following_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    status = Column(
        String(20),
        default="accepted",
        server_default="accepted",
        nullable=False,
    )

    # ✅ NEW
    seen_at = Column(
        DateTime(timezone=True),
        nullable=True,
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

    follower = relationship(
        "User",
        foreign_keys=[follower_id],
        back_populates="following",
    )

    following = relationship(
        "User",
        foreign_keys=[following_id],
        back_populates="followers",
    )

    _table_args_ = (
        UniqueConstraint(
            "follower_id",
            "following_id",
            name="uq_user_follow",
        ),

        CheckConstraint(
            "follower_id != following_id",
            name="check_no_self_follow",
        ),

        CheckConstraint(
            "status IN ('pending', 'accepted')",
            name="check_follow_status_valid",
        ),

        Index("idx_follow_follower", "follower_id"),
        Index("idx_follow_following", "following_id"),

        Index(
            "idx_follow_follower_status_created",
            "follower_id",
            "status",
            "created_at",
        ),

        Index(
            "idx_follow_following_status_created",
            "following_id",
            "status",
            "created_at",
        ),

        Index(
            "idx_follow_pair",
            "follower_id",
            "following_id",
        ),
    )