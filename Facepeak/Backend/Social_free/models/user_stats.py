from sqlalchemy import Column, Integer, ForeignKey, DateTime, Index, text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class UserStats(Base):
    __tablename__ = "user_stats"

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )

    # ======================
    # 🔥 SOCIAL CORE
    # ======================
    followers_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    following_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    matches_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    # ======================
    # 👁️ ENGAGEMENT
    # ======================
    profile_views_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    # ======================
    # 💬 MESSAGING
    # ======================
    unread_messages_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    message_requests_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    # ======================
    # ❤️ MATCHES
    # ======================
    match_requests_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    # ======================
    # 🔔 GLOBAL NOTIFICATIONS
    # ======================
    notifications_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    # ======================
    # 📊 CONTENT (future ready)
    # ======================
    posts_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    likes_received_count = Column(
        Integer,
        default=0,
        server_default=text("0"),
        nullable=False,
    )

    # ======================
    # 🕒 META
    # ======================
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

    # ======================
    # 🔗 RELATION
    # ======================
    user = relationship(
        "User",
        back_populates="stats",
        uselist=False,
    )

    # ======================
    # ⚡ INDEXES (performance)
    # ======================
    __table_args__ = (
        Index("idx_user_stats_notifications", "notifications_count"),
        Index("idx_user_stats_followers", "followers_count"),
        Index("idx_user_stats_matches", "matches_count"),
        Index("idx_user_stats_unread_messages", "unread_messages_count"),
    )