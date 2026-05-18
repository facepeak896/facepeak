"""add_follow_counts

Revision ID: 4c4ec67e4c4d
Revises: ade60f18df87
Create Date: 2026-05-03 23:03:48.304825

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '4c4ec67e4c4d'
down_revision: Union[str, Sequence[str], None] = 'ade60f18df87'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    tables = inspector.get_table_names()
    columns = [c["name"] for c in inspector.get_columns("user_stats")]

    if "followers_count" not in columns:
        op.add_column(
            "user_stats",
            sa.Column("followers_count", sa.Integer(), nullable=False, server_default="0"),
        )

    if "following_count" not in columns:
        op.add_column(
            "user_stats",
            sa.Column("following_count", sa.Integer(), nullable=False, server_default="0"),
        )

    if "follows" not in tables:
        return

    op.execute("""
        UPDATE user_stats us
        SET followers_count = sub.count
        FROM (
            SELECT following_id, COUNT(*) as count
            FROM follows
            WHERE status = 'accepted'
            GROUP BY following_id
        ) sub
        WHERE us.user_id = sub.following_id
    """)

    op.execute("""
        UPDATE user_stats us
        SET following_count = sub.count
        FROM (
            SELECT follower_id, COUNT(*) as count
            FROM follows
            WHERE status = 'accepted'
            GROUP BY follower_id
        ) sub
        WHERE us.user_id = sub.follower_id
    """)
def downgrade():
    op.drop_column("user_stats", "followers_count")
    op.drop_column("user_stats", "following_count")