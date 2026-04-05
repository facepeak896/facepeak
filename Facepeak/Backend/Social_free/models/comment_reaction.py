from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, UniqueConstraint, Index, text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from database import Base


class CommentReaction(Base):
    __tablename__ = "comment_reactions"

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

    reaction_type = Column(
        String(20),
        nullable=False
    )
    # like, laugh, fire, heart, clap

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    updated_at = Column(
        DateTime(timezone=True),
        onupdate=func.now()
    )

    # relationships

    user = relationship(
        "User",
        lazy="joined"
    )

    comment = relationship(
        "Comment",
        back_populates="reactions"
    )

    __table_args__ = (

        # user može imati samo jednu reakciju po komentaru
        UniqueConstraint(
            "user_id",
            "comment_id",
            name="uq_comment_reaction_user"
        ),

        # count reakcija za komentar
        Index(
            "idx_comment_reaction_comment_type",
            "comment_id",
            "reaction_type"
        ),

        # sve reakcije usera
        Index(
            "idx_comment_reaction_user",
            "user_id"
        ),

        # check je li user reagirao
        Index(
            "idx_comment_reaction_pair",
            "user_id",
            "comment_id"
        ),
    )