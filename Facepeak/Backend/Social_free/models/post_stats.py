from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class PostStats(Base):
    __tablename__ = "post_stats"

    post_id = Column(
        Integer,
        ForeignKey("posts.id", ondelete="CASCADE"),
        primary_key=True
    )

    likes_count = Column(Integer, nullable=False, server_default="0")
    views_count = Column(Integer, nullable=False, server_default="0")
    shares_count = Column(Integer, nullable=False, server_default="0")
    saves_count = Column(Integer, nullable=False, server_default="0")
    reports_count = Column(Integer, nullable=False, server_default="0")

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    updated_at = Column(
        DateTime(timezone=True),
        onupdate=func.now()
    )

    post = relationship(
        "Post",
        back_populates="stats",
        uselist=False
    )