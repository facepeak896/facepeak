from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Boolean, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    actor_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    notification_type = Column(
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

    is_read = Column(
        Boolean,
        default=False,
        nullable=False
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
        back_populates="notifications"
    )

    actor = relationship(
        "User",
        foreign_keys=[actor_id]
    )

    post = relationship(
        "Post"
    )

    __table_args__ = (
        Index("idx_notification_user_read", "user_id", "is_read"),
    )