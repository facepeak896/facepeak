from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class ProfileStats(Base):
    __tablename__ = "profile_stats"

    # 🔑 1:1 sa userom
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True
    )

    # 🔥 TOTAL (za UI)
    total_views = Column(
        Integer,
        default=0,
        nullable=False
    )

    # 🔥 DAILY (za growth feel)
    daily_views = Column(
        Integer,
        default=0,
        nullable=False
    )

    # 🔥 UNIQUE DAILY (kasnije za analytics)
    unique_daily_views = Column(
        Integer,
        default=0,
        nullable=False
    )

    # 🔥 LAST UPDATE (za reset logiku)
    last_updated = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )

    # 🔗 RELATION
    user = relationship(
        "User",
        back_populates="profile_stats",
        uselist=False
    )