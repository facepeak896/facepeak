from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class UserStats(Base):
    __tablename__ = "user_stats"

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True
    )

    # 🔥 CORE
    followers_count = Column(Integer, default=0, nullable=False)
    following_count = Column(Integer, default=0, nullable=False)
    matches_count = Column(Integer, default=0, nullable=False)
    profile_views_count = Column(Integer, default=0, nullable=False)

    posts_count = Column(Integer, default=0, nullable=False)

    # (future)
    likes_received_count = Column(Integer, default=0, nullable=False)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )

    user = relationship(
        "User",
        back_populates="stats",
        uselist=False
    )