"""add_message_rate_limits_table

Revision ID: 9fdce94f9162
Revises: ca2b20848115
Create Date: 2026-05-11 00:29:58.759219

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9fdce94f9162'
down_revision: Union[str, Sequence[str], None] = 'ca2b20848115'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.create_table(
        "message_rate_limits",

        sa.Column(
            "id",
            sa.Integer(),
            primary_key=True,
        ),

        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey(
                "users.id",
                ondelete="CASCADE",
            ),
            nullable=False,
            unique=True,
        ),

        sa.Column(
            "window_start",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),

        sa.Column(
            "messages_sent",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),

        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    op.create_index(
        "idx_message_rate_user_window",
        "message_rate_limits",
        ["user_id", "window_start"],
    )

    op.create_index(
        "ix_message_rate_limits_user_id",
        "message_rate_limits",
        ["user_id"],
    )

    op.create_index(
        "ix_message_rate_limits_window_start",
        "message_rate_limits",
        ["window_start"],
    )


def downgrade():
    op.drop_index(
        "ix_message_rate_limits_window_start",
        table_name="message_rate_limits",
    )

    op.drop_index(
        "ix_message_rate_limits_user_id",
        table_name="message_rate_limits",
    )

    op.drop_index(
        "idx_message_rate_user_window",
        table_name="message_rate_limits",
    )

    op.drop_table("message_rate_limits")