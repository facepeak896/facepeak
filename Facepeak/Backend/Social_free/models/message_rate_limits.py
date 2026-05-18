from sqlalchemy import Column, Integer, DateTime, ForeignKey, Index, text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class MessageRateLimit(Base):
    __tablename__ = "message_rate_limits"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )

    window_start = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        index=True,
    )

    messages_sent = Column(
        Integer,
        nullable=False,
        default=0,
        server_default=text("0"),
    )

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    user = relationship("User")

    __table_args__ = (
        Index("idx_message_rate_user_window", "user_id", "window_start"),
    )