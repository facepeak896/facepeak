# Backend/Social_free/models/user_welcome_psl.py

from sqlalchemy import (
    Column,
    Integer,
    ForeignKey,
    Boolean,
    String,
    DateTime,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class UserWelcomePSL(Base):
    __tablename__ = "user_welcome_psl"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    # =====================================================
    # OWNER
    # =====================================================

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )

    user = relationship("User")

    # =====================================================
    # WELCOME FLOW STATE
    # =====================================================

    # user finished loading/analyze
    welcome_loading_done = Column(
        Boolean,
        default=False,
        nullable=False,
    )

    # user passed access choice screen
    welcome_access_chosen = Column(
        Boolean,
        default=False,
        nullable=False,
    )

    # "free" | "premium"
    access_tier = Column(
        String,
        nullable=True,
    )

    # =====================================================
    # CACHED PSL RESULT
    # =====================================================

    psl_result = Column(
        JSONB,
        nullable=True,
    )

    # =====================================================
    # META
    # =====================================================

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )