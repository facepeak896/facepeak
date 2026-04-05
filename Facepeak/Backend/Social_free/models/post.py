from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    ForeignKey,
    DateTime,
    Boolean,
    Index,
    text
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class Post(Base):
    _tablename_ = "posts"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    image_url = Column(String, nullable=False)

    caption = Column(String, nullable=True)

    psl_score = Column(Float)

    # -------------------------
    # engagement counters
    # -------------------------

    like_count = Column(
        Integer,
        nullable=False,
        server_default=text("0")
    )

    comment_count = Column(
        Integer,
        nullable=False,
        server_default=text("0")
    )

    share_count = Column(
        Integer,
        nullable=False,
        server_default=text("0")
    )

    # -------------------------
    # state
    # -------------------------

    is_deleted = Column(
        Boolean,
        nullable=False,
        server_default=text("false"),
        index=True
    )

    # -------------------------
    # timestamps
    # -------------------------

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True
    )

    updated_at = Column(
        DateTime(timezone=True),
        onupdate=func.now()
    )

    # -------------------------
    # relationships
    # -------------------------

    user = relationship(
        "User",
        back_populates="posts"
    )

    stats = relationship(
        "PostStats",
        back_populates="post",
        cascade="all, delete-orphan",
        uselist=False
    )

    views = relationship(
        "PostView",
        back_populates="post",
        cascade="all, delete-orphan",
        lazy="selectin"
    )

    likes = relationship(
        "Like",
        back_populates="post",
        cascade="all, delete-orphan",
        lazy="selectin"
    )

    saved_by = relationship(
        "SavedPost",
        back_populates="post",
        cascade="all, delete-orphan",
        lazy="selectin"
    )

    reports = relationship(
        "Report",
        back_populates="target_post",
        cascade="all, delete-orphan"
    )

    notifications = relationship(
        "Notification",
        back_populates="post",
        cascade="all, delete-orphan"
    )

    comments = relationship(
        "Comment",
        back_populates="post",
        cascade="all, delete-orphan",
        lazy="selectin"
    )

    __table_args__ = (

        # feed queries
        Index("idx_post_user_created", "user_id", "created_at"),

        # active posts
        Index("idx_post_active_created", "is_deleted", "created_at"),
    )