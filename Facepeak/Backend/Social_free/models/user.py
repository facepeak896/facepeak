from sqlalchemy import Column, Integer, String, DateTime, Boolean, Index, text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)

    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)

    password_hash = Column(String, nullable=True)

    bio = Column(String(500), nullable=True)

    # 🔥 PROFILE
    profile_image_url = Column(String, nullable=True)

    # 🔒 PRIVACY
    is_private = Column(Boolean, nullable=False, server_default=text("true"), index=True)

    # STATUS
    is_active = Column(Boolean, nullable=False, server_default=text("true"), index=True)
    is_banned = Column(Boolean, nullable=False, server_default=text("false"), index=True)

    # 🔥 SOCIAL LIVE STATE
    is_live = Column(Boolean, nullable=False, server_default=text("false"), index=True)
    social_activated_at = Column(DateTime(timezone=True), nullable=True, index=True)
    has_seen_social_explainer = Column(
        Boolean,
        nullable=False,
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

    # =========================
    # 🔥 RELATIONS
    # =========================

    # STATS (1-1)
    stats = relationship(
        "UserStats",
        back_populates="user",
        uselist=False,
        cascade="all, delete",
        lazy="selectin"
    )

    # 🔥 PSL HISTORY (1-M)
    psl_history = relationship(
        "UserPSL",
        back_populates="user",
        cascade="all, delete",
        lazy="selectin"
    )

    # =========================
    # INDEXES
    # =========================

    __table_args__ = (
        Index("idx_user_active_created", "is_active", "created_at"),
        Index("idx_user_last_active", "last_active_at"),
        Index("idx_user_live_created", "is_live", "created_at"),
    )