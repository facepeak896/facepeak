from sqlalchemy import (
    Column,
    Integer,
    ForeignKey,
    DateTime,
    UniqueConstraint,
    Index
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentMention(Base):
    __tablename__ = "comment_mentions"

    id = Column(Integer, primary_key=True)

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False
    )

    mentioned_user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    # relationships

    comment = relationship(
        "Comment",
        lazy="joined"
    )

    mentioned_user = relationship(
        "User",
        lazy="joined"
    )

    __table_args__ = (

        # sprječava duple mentione
        UniqueConstraint(
            "comment_id",
            "mentioned_user_id",
            name="uq_comment_mention"
        ),

        # dohvat mentiona za komentar
        Index(
            "idx_comment_mention_comment",
            "comment_id"
        ),

        # dohvat svih mentiona za usera
        Index(
            "idx_comment_mention_user",
            "mentioned_user_id"
        ),

        # brži notification feed
        Index(
            "idx_comment_mention_user_created",
            "mentioned_user_id",
            "created_at"
        ),

        # optimizacija join querya
        Index(
            "idx_comment_mention_user_comment",
            "mentioned_user_id",
            "comment_id"
        ),
    )