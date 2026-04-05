from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Boolean, Index, UniqueConstraint, text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentNotification(Base):
    __tablename__ = "comment_notifications"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    actor_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=True
    )

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False
    )

    type = Column(
        String(20),
        nullable=False
    )
    # like, reply, mention

    is_read = Column(
        Boolean,
        nullable=False,
        server_default=text("false")
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    read_at = Column(
        DateTime(timezone=True),
        nullable=True
    )

    # relationships

    user = relationship(
        "User",
        foreign_keys=[user_id]
    )

    actor = relationship(
        "User",
        foreign_keys=[actor_id]
    )

    comment = relationship(
        "Comment"
    )

    __table_args__ = (

        # sprječava duple notifikacije
        UniqueConstraint(
            "user_id",
            "actor_id",
            "comment_id",
            "type",
            name="uq_comment_notification"
        ),

        # učitavanje notification feeda
        Index("idx_comment_notification_user_time", "user_id", "created_at"),

        # unread count query
        Index("idx_comment_notification_unread", "user_id", "is_read"),
    )