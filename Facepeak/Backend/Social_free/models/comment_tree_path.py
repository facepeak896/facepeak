from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    DateTime,
    Boolean,
    Index,
    CheckConstraint
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship, backref

from database import Base


class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)

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

    content = Column(
        String(500),
        nullable=False
    )

    # materialized path
    tree_path = Column(
        String(255),
        nullable=False
    )

    depth = Column(
        Integer,
        nullable=False,
        default=0
    )

    # counters (UI performance)
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

    is_pinned = Column(
        Boolean,
        nullable=False,
        default=False
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )

    # relationships

    user = relationship(
        "User",
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

    stats = relationship(
        "CommentStats",
        back_populates="comment",
        uselist=False,
        cascade="all, delete-orphan"
    )

    __table_args__ = (

        # depth safety
        CheckConstraint(
            "depth >= 0 AND depth <= 10",
            name="check_comment_depth"
        ),

        # thread query
        Index("idx_comment_tree_path", "tree_path"),

        # comments per post ordered by thread
        Index("idx_comment_post_tree", "post_id", "tree_path"),

        # pinned comments
        Index("idx_comment_pinned", "post_id", "is_pinned"),

        # replies
        Index("idx_comment_parent", "parent_comment_id"),
    )