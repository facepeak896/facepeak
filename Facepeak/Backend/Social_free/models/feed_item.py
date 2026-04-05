from sqlalchemy import Column, Integer, ForeignKey, DateTime, Float, String, Index, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class FeedItem(Base):
    __tablename__ = "feed_items"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    post_id = Column(
        Integer,
        ForeignKey("posts.id", ondelete="CASCADE"),
        nullable=False
    )

    score = Column(
        Float,
        nullable=True
    )

    source = Column(
        String,
        nullable=True
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    user = relationship("User")
    post = relationship("Post")

    __table_args__ = (
        # sprječava duple postove u feedu
        UniqueConstraint("user_id", "post_id", name="uq_feed_user_post"),

        # glavni feed query (ranking + pagination)
        Index("idx_feed_user_score_created", "user_id", "score", "created_at"),

        # operacije poput delete/count
        Index("idx_feed_user", "user_id"),
    )