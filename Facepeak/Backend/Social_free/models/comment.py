from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    DateTime,
    Boolean,
    Index,
    text
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship, backref

from database import Base


class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)

    # -------------------------
    # core
    # -------------------------

    post_id = Column(
        Integer,
        ForeignKey("posts.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    parent_comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    # root thread (performance)
    thread_root_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    depth = Column(
        Integer,
        nullable=False,
        server_default="0"
    )

    content = Column(
        String(500),
        nullable=False
    )

    # -------------------------
    # state
    # -------------------------

    is_pinned = Column(
        Boolean,
        nullable=False,
        server_default=text("false")
    )

    # soft delete
    is_deleted = Column(
        Boolean,
        nullable=False,
        server_default=text("false"),
        index=True
    )

    deleted_at = Column(
        DateTime(timezone=True),
        nullable=True
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
        back_populates="comments",
        lazy="joined"
    )

    post = relationship(
        "Post",
        back_populates="comments"
    )

    parent_comment = relationship(
        "Comment",
        remote_side=[id],
        backref=backref("replies", lazy="selectin")
    )

    thread_root = relationship(
        "Comment",
        foreign_keys=[thread_root_id]
    )

    stats = relationship(
        "CommentStats",
        back_populates="comment",
        uselist=False,
        cascade="all, delete-orphan",
        lazy="joined"
    )

    likes = relationship(
        "CommentLike",
        back_populates="comment",
        cascade="all, delete-orphan"
    )

    reactions = relationship(
        "CommentReaction",
        back_populates="comment",
        cascade="all, delete-orphan"
    )

    mentions = relationship(
        "CommentMention",
        back_populates="comment",
        cascade="all, delete-orphan"
    )

    attachments = relationship(
        "CommentAttachment",
        back_populates="comment",
        cascade="all, delete-orphan"
    )

    bookmarks = relationship(
        "CommentBookmark",
        back_populates="comment",
        cascade="all, delete-orphan"
    )

    rank_logs = relationship(
        "CommentRankLog",
        back_populates="comment",
        cascade="all, delete-orphan"
    )

    edit_history = relationship(
        "CommentEditHistory",
        back_populates="comment",
        cascade="all, delete-orphan"
    )

    # -------------------------
    # indexes
    # -------------------------

    __table_args__ = (

        # fetch comments per post
        Index("idx_comment_post_created", "post_id", "created_at"),

        # replies
        Index("idx_comment_parent", "parent_comment_id"),

        # thread loading
        Index("idx_comment_thread_root", "thread_root_id"),

        # soft delete filter
        Index("idx_comment_post_active", "post_id", "is_deleted"),
    )