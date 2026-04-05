from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class AnalyticsEvent(Base):
    __tablename__ = "analytics_events"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    event_type = Column(
        String,
        nullable=False,
        index=True
    )

    target_post_id = Column(
        Integer,
        ForeignKey("posts.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    target_user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    event_metadata = Column(
        JSON,
        nullable=True
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True
    )

    user = relationship(
        "User",
        foreign_keys=[user_id],
        back_populates="analytics_events"
    )

    post = relationship(
        "Post",
        foreign_keys=[target_post_id]
    )

    target_user = relationship(
        "User",
        foreign_keys=[target_user_id]
    )