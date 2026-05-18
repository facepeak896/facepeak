"""create_follows_table

Revision ID: 5958439c1870
Revises: 4c4ec67e4c4d
Create Date: 2026-05-03 23:16:05.349429

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5958439c1870'
down_revision: Union[str, Sequence[str], None] = '4c4ec67e4c4d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.create_table(
        "follows",
        sa.Column("id", sa.Integer(), primary_key=True),

        sa.Column("follower_id", sa.Integer(), nullable=False),
        sa.Column("following_id", sa.Integer(), nullable=False),

        sa.Column(
            "status",
            sa.String(20),
            nullable=False,
            server_default="accepted",
        ),

        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),

        sa.ForeignKeyConstraint(
            ["follower_id"], ["users.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["following_id"], ["users.id"], ondelete="CASCADE"
        ),

        sa.UniqueConstraint(
            "follower_id",
            "following_id",
            name="uq_user_follow",
        ),

        sa.CheckConstraint(
            "follower_id != following_id",
            name="check_no_self_follow",
        ),
    )

    op.create_index("idx_follow_follower", "follows", ["follower_id"])
    op.create_index("idx_follow_following", "follows", ["following_id"])
def downgrade():
    op.drop_index("idx_follow_following", table_name="follows")
    op.drop_index("idx_follow_follower", table_name="follows")
    op.drop_table("follows")