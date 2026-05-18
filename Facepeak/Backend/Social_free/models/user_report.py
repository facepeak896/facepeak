from sqlalchemy import Column, Integer, ForeignKey, String, DateTime, Index, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class UserReport(Base):
    __tablename__ = "user_reports"

    id = Column(Integer, primary_key=True, index=True)

    reporter_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    reported_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    reason = Column(String(80), nullable=False)
    details = Column(String(500), nullable=True)

    status = Column(
        String(30),
        nullable=False,
        default="open",
        server_default="open",
        index=True,
    )
    # open / reviewed / dismissed / actioned

    severity = Column(
        Integer,
        nullable=False,
        default=1,
        server_default="1",
    )
    # 1-5

    admin_note = Column(String(500), nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    reporter = relationship("User", foreign_keys=[reporter_id])
    reported = relationship("User", foreign_keys=[reported_id])

    __table_args__ = (
        UniqueConstraint(
            "reporter_id",
            "reported_id",
            name="unique_user_report",
        ),
        Index(
            "idx_reports_reported_status_created",
            "reported_id",
            "status",
            "created_at",
        ),
        Index(
            "idx_reports_reporter_created",
            "reporter_id",
            "created_at",
        ),
    )