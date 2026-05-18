from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class UserBlock(Base):
    __tablename__ = "user_blocks"

    id = Column(Integer, primary_key=True, index=True)

    blocker_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    blocked_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    blocker = relationship("User", foreign_keys=[blocker_id])
    blocked = relationship("User", foreign_keys=[blocked_id])

    __table_args__ = (
        UniqueConstraint("blocker_id", "blocked_id", name="unique_user_block"),
        Index("idx_block_blocker_created", "blocker_id", "created_at"),
        Index("idx_block_blocked_created", "blocked_id", "created_at"),
    )