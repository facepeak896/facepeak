from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentLike(Base):
    __tablename__ = "comment_likes"

    id = Column(Integer, primary_key=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    comment_id = Column(
        Integer,
        ForeignKey("comments.id", ondelete="CASCADE"),
        nullable=False
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    # relationships
    user = relationship("User", lazy="joined")
    comment = relationship("Comment", lazy="joined")

    __table_args__ = (
        # sprječava da user lajka isti komentar više puta
        UniqueConstraint("user_id", "comment_id", name="uq_user_comment_like"),

        # ubrzava query: svi likeovi komentara
        Index("idx_comment_like_comment", "comment_id"),

        # ubrzava query: sve što je user lajkao
        Index("idx_comment_like_user", "user_id"),

        # ubrzava check: je li user lajkao komentar
        Index("idx_comment_like_pair", "user_id", "comment_id"),
    )