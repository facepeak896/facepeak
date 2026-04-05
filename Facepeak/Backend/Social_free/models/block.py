from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint, CheckConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class Block(Base):
    __tablename__ = "blocks"

    id = Column(Integer, primary_key=True)

    blocker_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    blocked_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True
    )

    blocker = relationship(
        "User",
        foreign_keys=[blocker_id],
        back_populates="blocks_made"
    )

    blocked = relationship(
        "User",
        foreign_keys=[blocked_id],
        back_populates="blocks_received"
    )

    __table_args__ = (
        UniqueConstraint("blocker_id", "blocked_id", name="uq_block_user"),
        CheckConstraint("blocker_id != blocked_id", name="check_no_self_block"),
    )