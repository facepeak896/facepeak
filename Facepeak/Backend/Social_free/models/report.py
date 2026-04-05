from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, UniqueConstraint, CheckConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class Report(Base):
    __tablename__ = "reports"

    id = Column(Integer, primary_key=True)

    reporter_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    target_user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    target_post_id = Column(
        Integer,
        ForeignKey("posts.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    report_type = Column(String, nullable=False, index=True)

    reason = Column(String, nullable=False, index=True)

    status = Column(String, nullable=False, default="pending", index=True)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True
    )

    reporter = relationship("User", foreign_keys=[reporter_id])
    target_user = relationship("User", foreign_keys=[target_user_id])
    target_post = relationship("Post")

    __table_args__ = (
        UniqueConstraint("reporter_id", "target_post_id", name="uq_report_post"),
        UniqueConstraint("reporter_id", "target_user_id", name="uq_report_user"),
        CheckConstraint(
            "target_user_id IS NOT NULL OR target_post_id IS NOT NULL",
            name="check_report_target"
        ),
    )