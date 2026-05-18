from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class Conversation(Base):
    __tablename__ = "conversations"

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

    last_message_id = Column(
        Integer,
        ForeignKey("messages.id", ondelete="SET NULL"),
        nullable=True,
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
        index=True,
    )

    user1 = relationship("User", foreign_keys=[user1_id])
    user2 = relationship("User", foreign_keys=[user2_id])

    last_message = relationship("Message", foreign_keys=[last_message_id], post_update=True)

    __table_args__ = (
        UniqueConstraint("user1_id", "user2_id", name="unique_conversation_pair"),
        Index("idx_conversation_user1_updated", "user1_id", "updated_at"),
        Index("idx_conversation_user2_updated", "user2_id", "updated_at"),
    )