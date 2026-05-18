"""add messaging + notifications stats

Revision ID: 0c46b9797829
Revises: 9516db920132
Create Date: 2026-05-02 22:47:42.047554

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0c46b9797829'
down_revision: Union[str, Sequence[str], None] = '9516db920132'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



def upgrade():
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    columns = [c["name"] for c in inspector.get_columns("user_stats")]

    if "unread_messages_count" not in columns:
        op.add_column(
            "user_stats",
            sa.Column("unread_messages_count", sa.Integer(), nullable=False, server_default="0"),
        )

    if "message_requests_count" not in columns:
        op.add_column(
            "user_stats",
            sa.Column("message_requests_count", sa.Integer(), nullable=False, server_default="0"),
        )

    if "match_requests_count" not in columns:
        op.add_column(
            "user_stats",
            sa.Column("match_requests_count", sa.Integer(), nullable=False, server_default="0"),
        )

    if "notifications_count" not in columns:
        op.add_column(
            "user_stats",
            sa.Column("notifications_count", sa.Integer(), nullable=False, server_default="0"),
        )
def downgrade():
    op.drop_column("user_stats", "notifications_count")
    op.drop_column("user_stats", "match_requests_count")
    op.drop_column("user_stats", "message_requests_count")
    op.drop_column("user_stats", "unread_messages_count")