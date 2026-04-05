from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentEditHistory(Base):
    __tablename__ = "comment_edit_history"

    id = Column(Integer, primary_key=True)

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False
    )

    editor_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

    old_content = Column(
        String(500),
        nullable=False
    )

    new_content = Column(
        String(500),
        nullable=False
    )

    edit_reason = Column(
        String(200),
        nullable=True
    )

    edit_type = Column(
        String(20),
        nullable=True
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    # relationships

    comment = relationship("Comment")
    editor = relationship("User")

    __table_args__ = (
        Index("idx_comment_edit_history_comment_time", "comment_id", "created_at"),
        Index("idx_comment_edit_history_editor", "editor_id"),
    )