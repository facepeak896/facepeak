from sqlalchemy import Column, Integer, String, DateTime, Boolean, Index, text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)

    google_id = Column(String(255), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)

    username = Column(String(100), nullable=True, index=True)

    profile_image_url = Column(String, nullable=True)
    bio = Column(String(500), nullable=True)

    weekly_potential_range = Column(String(50), nullable=True)

    reach_target_percentile = Column(
        Integer,
        nullable=False,
        default=50,
        server_default=text("50"),
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        server_default=text("true"),
        index=True,
    )

    is_banned = Column(
        Boolean,
        nullable=False,
        default=False,
        server_default=text("false"),
        index=True,
    )

    is_live = Column(
        Boolean,
        nullable=False,
        default=False,
        server_default=text("false"),
        index=True,
    )

    social_activated_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )

    # 🔥 NEW
    last_social_rescore_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )

    has_seen_social_explainer = Column(
        Boolean,
        nullable=False,
        default=False,
        server_default=text("false"),
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    last_active_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )

    # ======================
    # 🔗 FOLLOW RELATIONS
    # ======================

    followers = relationship(
        "Follow",
        foreign_keys="Follow.following_id",
        back_populates="following",
        cascade="all, delete-orphan",
    )

    following = relationship(
        "Follow",
        foreign_keys="Follow.follower_id",
        back_populates="follower",
        cascade="all, delete-orphan",
    )

    stats = relationship(
        "UserStats",
        back_populates="user",
        uselist=False,
        cascade="all, delete",
        lazy="selectin",
    )

    psl_history = relationship(
        "UserPSL",
        back_populates="user",
        cascade="all, delete",
        lazy="selectin",
    )

    __table_args__ = (
        Index("idx_user_active_created", "is_active", "created_at"),
        Index("idx_user_last_active", "last_active_at"),
        Index("idx_user_live_created", "is_live", "created_at"),

        # 🔥 NEW
        Index(
            "idx_user_last_social_rescore",
            "last_social_rescore_at",
        ),
    )