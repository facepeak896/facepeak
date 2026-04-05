from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey, Index, desc
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from Backend.Social_free.login.database import Base


class UserPSL(Base):
    __tablename__ = "user_psl"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    # 🔥 OSTAVLJAMO FLOAT (kako si tražio)
    psl_score = Column(Float, nullable=False)
    tier = Column(String, nullable=True)
    percentile = Column(Float, nullable=True)
    confidence = Column(Float, nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    # 🔥 CLEAN RELATION (explicit > backref)
    user = relationship("User", back_populates="psl_history")

    __table_args__ = (
        # 🔥 JEDINI INDEX KOJI TI TREBA
        Index(
            "idx_user_psl_user_created_desc",
            "user_id",
            desc("created_at")
        ),
    )