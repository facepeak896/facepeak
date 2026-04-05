from sqlalchemy import (
    Column,
    Integer,
    ForeignKey,
    DateTime,
    Boolean,
    UniqueConstraint,
    Index
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentThreadSubscription(Base):
    __tablename__ = "comment_thread_subscriptions"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    thread_root_comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False
    )

    # da li je subscription automatski (npr. kad user napiše komentar)
    is_auto = Column(
        Boolean,
        nullable=False,
        default=False
    )

    # zadnja aktivnost u threadu
    last_activity_at = Column(
        DateTime(timezone=True),
        nullable=True
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    # relationships

    user = relationship(
        "User"
    )

    thread_root = relationship(
        "Comment",
        foreign_keys=[thread_root_comment_id]
    )

    __table_args__ = (

        # sprječava duple subscribe
        UniqueConstraint(
            "user_id",
            "thread_root_comment_id",
            name="uq_comment_thread_subscription"
        ),

        # dohvat subscriber-a threada
        Index(
            "idx_comment_thread_subscription_thread",
            "thread_root_comment_id"
        ),

        # dohvat threadova koje user prati
        Index(
            "idx_comment_thread_subscription_user",
            "user_id"
        ),

        # feed threadova koje user prati
        Index(
            "idx_comment_thread_subscription_user_created",
            "user_id",
            "created_at"
        ),

        # activity sorting
        Index(
            "idx_comment_thread_subscription_user_activity",
            "user_id",
            "last_activity_at"
        ),
    )