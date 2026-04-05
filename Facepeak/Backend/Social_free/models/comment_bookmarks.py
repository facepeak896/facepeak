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


class CommentBookmark(Base):
    __tablename__ = "comment_bookmarks"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    # relationships

    user = relationship(
        "User"
    )

    comment = relationship(
        "Comment"
    )

    __table_args__ = (

        # sprječava dupli bookmark
        UniqueConstraint(
            "user_id",
            "comment_id",
            name="uq_comment_bookmark"
        ),

        # fetch bookmarks za usera
        Index(
            "idx_comment_bookmark_user",
            "user_id"
        ),

        # fetch bookmarka za komentar
        Index(
            "idx_comment_bookmark_comment",
            "comment_id"
        ),

        # feed bookmarka
        Index(
            "idx_comment_bookmark_user_created",
            "user_id",
            "created_at"
        ),
    )