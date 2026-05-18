from sqlalchemy import Column, Integer, ForeignKey, String, DateTime, Boolean, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)

    conversation_id = Column(
        Integer,
        ForeignKey("conversations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

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

    body = Column(String(500), nullable=False)

    is_deleted = Column(
        Boolean,
        nullable=False,
        default=False,
        server_default="false",
        index=True,
    )

    # REAL delivered:
    # None = receiver device has NOT acknowledged delivery yet
    # timestamp = receiver device acknowledged via WebSocket
    delivered_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )

    seen_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True,
    )

    conversation = relationship("Conversation", foreign_keys=[conversation_id])
    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

    __table_args__ = (
        Index("idx_messages_conversation_created", "conversation_id", "created_at"),
        Index("idx_messages_receiver_seen", "receiver_id", "seen_at"),
        Index("idx_messages_sender_created", "sender_id", "created_at"),
    )