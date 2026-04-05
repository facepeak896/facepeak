from sqlalchemy import Column, Integer, ForeignKey, DateTime, Float, text, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentStats(Base):
    __tablename__ = "comment_stats"

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        primary_key=True
    )

    likes_count = Column(Integer, nullable=False, server_default=text("0"))
    replies_count = Column(Integer, nullable=False, server_default=text("0"))
    reports_count = Column(Integer, nullable=False, server_default=text("0"))

    ranking_score = Column(Float, nullable=False, server_default=text("0"))

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    updated_at = Column(
        DateTime(timezone=True),
        onupdate=func.now()
    )

    comment = relationship(
        "Comment",
        back_populates="stats",
        uselist=False
    )

    __table_args__ = (
        Index("idx_comment_stats_rank", "ranking_score"),
    )