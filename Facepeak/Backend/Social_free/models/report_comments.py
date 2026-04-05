from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, UniqueConstraint, Index, text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentReport(Base):
    __tablename__ = "comment_reports"

    id = Column(Integer, primary_key=True)

    reporter_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    reason = Column(
        String(100),
        nullable=False,
        index=True
    )

    status = Column(
        String(50),
        nullable=False,
        server_default=text("'pending'"),
        index=True
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

    # relationships

    reporter = relationship("User")

    comment = relationship(
        "Comment",
        back_populates="reports"
    )

    __table_args__ = (
        UniqueConstraint(
            "reporter_id",
            "comment_id",
            name="uq_user_comment_report"
        ),
        Index("idx_comment_report_comment", "comment_id"),
        Index("idx_comment_report_status", "status"),
    )