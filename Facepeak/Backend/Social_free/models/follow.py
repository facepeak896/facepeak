from sqlalchemy import (
    Column,
    Integer,
    ForeignKey,
    DateTime,
    String,
    UniqueConstraint,
    Index,
    CheckConstraint,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class Follow(Base):
    __tablename__ = "follows"

    id = Column(Integer, primary_key=True, index=True)

    # 👤 WHO FOLLOWS
    follower_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    # 🎯 WHO IS BEING FOLLOWED
    following_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )

    # 🔄 STATUS (future: private accounts, requests)
    status = Column(
        String,
        default="accepted",  # "pending", "accepted"
        nullable=False,
        index=True,
    )

    # ⏱ TIME
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    # 🔗 RELATIONSHIPS
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

    # ⚡ CONSTRAINTS + INDEXES
    _table_args_ = (

        # ❌ NO DUPLICATES
        UniqueConstraint(
            "follower_id",
            "following_id",
            name="uq_user_follow",
        ),

        # ❌ NO SELF FOLLOW
        CheckConstraint(
            "follower_id != following_id",
            name="check_no_self_follow",
        ),

        # ⚡ FAST LOOKUPS
        Index("idx_follow_follower", "follower_id"),
        Index("idx_follow_following", "following_id"),

        # 🔥 COMPOSITE INDEX (KEY FOR SCALE)
        Index(
            "idx_follow_pair",
            "follower_id",
            "following_id",
        ),
    )