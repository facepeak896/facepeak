from sqlalchemy import Column, Integer, ForeignKey, DateTime, Index, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class ProfileView(Base):
    __tablename__ = "profile_views"

    id = Column(Integer, primary_key=True, index=True)

    viewer_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    viewed_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        index=True
    )

    # 🔥 RELATIONS
    viewer = relationship(
        "User",
        foreign_keys=[viewer_id],
        back_populates="views_made"
    )

    viewed = relationship(
        "User",
        foreign_keys=[viewed_id],
        back_populates="views_received"
    )

    _table_args_ = (
        # ⚡ FAST LOOKUPS (CRITICAL FOR PERFORMANCE)
        Index("idx_profile_view_viewer", "viewer_id"),
        Index("idx_profile_view_viewed", "viewed_id"),

        # ⚡ ANTI-DUPLICATE PER EXACT TIMESTAMP (OPTIONAL SAFETY)
        # omogućava više viewova ali sprječava dupli insert bug
        UniqueConstraint(
            "viewer_id",
            "viewed_id",
            "created_at",
            name="uq_profile_view_event"
        ),
    )