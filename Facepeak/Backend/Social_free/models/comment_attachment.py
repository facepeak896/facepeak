from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    DateTime,
    Enum,
    Index,
    CheckConstraint
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentAttachment(Base):
    __tablename__ = "comment_attachments"

    id = Column(Integer, primary_key=True)

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False
    )

    # storage
    storage_key = Column(
        String,
        nullable=False
    )

    cdn_url = Column(
        String,
        nullable=False
    )

    file_type = Column(
        Enum(
            "image",
            "gif",
            "video",
            "link",
            name="comment_attachment_type"
        ),
        nullable=False
    )

    # metadata
    file_size = Column(Integer)

    width = Column(Integer)

    height = Column(Integer)

    duration = Column(Integer)
    # video duration (seconds)

    position = Column(
        Integer,
        nullable=False,
        default=0
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    # relationships

    comment = relationship(
        "Comment"
    )

    __table_args__ = (

        # order attachments in comment
        Index(
            "idx_comment_attachment_comment_position",
            "comment_id",
            "position"
        ),

        # analytics / moderation
        Index(
            "idx_comment_attachment_type",
            "file_type"
        ),

        # CDN lookup
        Index(
            "idx_comment_attachment_storage",
            "storage_key"
        ),

        # basic sanity check
        CheckConstraint(
            "position >= 0",
            name="check_attachment_position"
        ),
    )