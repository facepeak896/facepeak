from sqlalchemy import Column, Integer, ForeignKey, String, DateTime, UniqueConstraint, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class MatchRequest(Base):
    __tablename__ = "match_requests"

    id = Column(Integer, primary_key=True, index=True)

    sender_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    receiver_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    status = Column(
        String(30),
        default="pending",
        server_default="pending",
        nullable=False,
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

    __table_args__ = (
        UniqueConstraint("sender_id", "receiver_id", name="unique_match_request"),
        Index("idx_match_req_receiver_status_created", "receiver_id", "status", "created_at"),
        Index("idx_match_req_sender_status_created", "sender_id", "status", "created_at"),
    )