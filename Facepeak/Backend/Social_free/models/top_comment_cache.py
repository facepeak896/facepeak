from sqlalchemy import Column, Integer, ForeignKey, DateTime, Float, UniqueConstraint, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class TopCommentCache(Base):
    __tablename__ = "top_comment_cache"

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

    # pozicija u top listi (1–10 npr.)
    position = Column(
        Integer,
        nullable=False
    )

    ranking_score = Column(
        Float,
        nullable=False
    )

    # optional denormalized fields (performance)
    author_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

    like_count = Column(
        Integer,
        nullable=False,
        default=0
    )

    reply_count = Column(
        Integer,
        nullable=False,
        default=0
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    updated_at = Column(
        DateTime(timezone=True),
        onupdate=func.now()
    )

    last_calculated_at = Column(
        DateTime(timezone=True),
        nullable=True
    )

    post = relationship("Post")
    comment = relationship("Comment")
    author = relationship("User")

    __table_args__ = (

        # sprječava duplikat komentara u cacheu
        UniqueConstraint(
            "post_id",
            "comment_id",
            name="uq_top_comment_cache"
        ),

        # sprječava duplikat pozicije
        UniqueConstraint(
            "post_id",
            "position",
            name="uq_top_comment_position"
        ),

        # brzi fetch top komentara
        Index(
            "idx_top_comment_cache_post_position",
            "post_id",
            "position"
        ),

        # ranking index
        Index(
            "idx_top_comment_cache_rank",
            "post_id",
            "ranking_score"
        ),

        # pagination index
        Index(
            "idx_top_comment_cache_post_rank_time",
            "post_id",
            "ranking_score",
            "created_at"
        ),
    )