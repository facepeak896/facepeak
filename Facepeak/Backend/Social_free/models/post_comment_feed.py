from sqlalchemy import Column, Integer, ForeignKey, DateTime, Float, Index, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class PostCommentFeed(Base):
    __tablename__ = "post_comment_feed"

    id = Column(Integer, primary_key=True)

    post_id = Column(
        Integer,
        ForeignKey("posts.id", ondelete="CASCADE"),
        nullable=False
    )

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False
    )

    ranking_score = Column(
        Float,
        nullable=False,
        default=0
    )

    sort_key = Column(
        Float,
        nullable=False,
        default=0,
        index=True
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    post = relationship("Post")
    comment = relationship("Comment")

    __table_args__ = (
        UniqueConstraint("post_id", "comment_id", name="uq_post_comment_feed"),

        Index("idx_post_comment_feed_rank", "post_id", "ranking_score"),

        Index("idx_post_comment_feed_sort", "post_id", "sort_key"),

        Index("idx_post_comment_feed_pagination", "post_id", "sort_key", "created_at"),
    )