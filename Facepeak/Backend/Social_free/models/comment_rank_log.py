from sqlalchemy import (
    Column,
    Integer,
    Float,
    Enum,
    ForeignKey,
    DateTime,
    Index
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentRankLog(Base):
    __tablename__ = "comment_rank_logs"

    id = Column(Integer, primary_key=True)

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False
    )

    actor_user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    # moderator ili system actor

    old_score = Column(
        Float,
        nullable=True
    )

    new_score = Column(
        Float,
        nullable=False
    )

    reason = Column(
        Enum(
            "like_spike",
            "reply_boost",
            "manual_mod",
            "decay",
            name="comment_rank_reason"
        ),
        nullable=False
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    # relationships

    comment = relationship(
        "Comment"
    )

    actor = relationship(
        "User"
    )

    __table_args__ = (

        # ranking history po komentaru
        Index(
            "idx_comment_rank_log_comment",
            "comment_id"
        ),

        # timeline za debugging
        Index(
            "idx_comment_rank_log_comment_created",
            "comment_id",
            "created_at"
        ),

        # moderator actions
        Index(
            "idx_comment_rank_log_actor",
            "actor_user_id"
        ),
    )