from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)

    user1_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    user2_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    user1 = relationship("User", foreign_keys=[user1_id])
    user2 = relationship("User", foreign_keys=[user2_id])

    __table_args__ = (
        UniqueConstraint("user1_id", "user2_id", name="unique_match_pair"),
        Index("idx_matches_user1_created", "user1_id", "created_at"),
        Index("idx_matches_user2_created", "user2_id", "created_at"),
    )