from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class ConversationHidden(Base):
    __tablename__ = "conversation_hidden"

    id = Column(Integer, primary_key=True, index=True)

    conversation_id = Column(
        Integer,
        ForeignKey("conversations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    user_id = Column(
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

    conversation = relationship("Conversation")
    user = relationship("User")

    __table_args__ = (
        UniqueConstraint(
            "conversation_id",
            "user_id",
            name="unique_conversation_hidden_user",
        ),
        Index("idx_conversation_hidden_user", "user_id", "conversation_id"),
    )