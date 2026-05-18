"""add_notification_logs

Revision ID: 870c07fc1c9c
Revises: 9fdce94f9162
Create Date: 2026-05-11 01:11:09.436606

"""
from typing import Sequence, Union


from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '870c07fc1c9c'
down_revision: Union[str, Sequence[str], None] = '9fdce94f9162'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.create_table(
        "notification_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("type", sa.String(length=60), nullable=False),
        sa.Column("dedupe_key", sa.String(length=255), nullable=False),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("body", sa.String(length=255), nullable=False),
        sa.Column(
            "data",
            postgresql.JSONB(),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column(
            "status",
            sa.String(length=30),
            nullable=False,
            server_default=sa.text("'pending'"),
        ),
        sa.Column("send_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("skipped_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("failed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("error", sa.Text(), nullable=True),
        sa.Column(
            "attempts",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column(
            "max_attempts",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("3"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )

    op.create_unique_constraint(
        "uq_notification_logs_dedupe_key",
        "notification_logs",
        ["dedupe_key"],
    )

    op.create_index(
        "ix_notification_logs_user_id",
        "notification_logs",
        ["user_id"],
    )

    op.create_index(
        "ix_notification_logs_type",
        "notification_logs",
        ["type"],
    )

    op.create_index(
        "ix_notification_logs_status",
        "notification_logs",
        ["status"],
    )

    op.create_index(
        "ix_notification_logs_send_at",
        "notification_logs",
        ["send_at"],
    )

    op.create_index(
        "ix_notification_logs_sent_at",
        "notification_logs",
        ["sent_at"],
    )

    op.create_index(
        "ix_notification_logs_created_at",
        "notification_logs",
        ["created_at"],
    )

    op.create_index(
        "idx_notification_user_type_created",
        "notification_logs",
        ["user_id", "type", "created_at"],
    )

    op.create_index(
        "idx_notification_pending_send_at",
        "notification_logs",
        ["status", "send_at"],
    )

    op.create_index(
        "idx_notification_user_status",
        "notification_logs",
        ["user_id", "status"],
    )


def downgrade():
    op.drop_index("idx_notification_user_status", table_name="notification_logs")
    op.drop_index("idx_notification_pending_send_at", table_name="notification_logs")
    op.drop_index("idx_notification_user_type_created", table_name="notification_logs")
    op.drop_index("ix_notification_logs_created_at", table_name="notification_logs")
    op.drop_index("ix_notification_logs_sent_at", table_name="notification_logs")
    op.drop_index("ix_notification_logs_send_at", table_name="notification_logs")
    op.drop_index("ix_notification_logs_status", table_name="notification_logs")
    op.drop_index("ix_notification_logs_type", table_name="notification_logs")
    op.drop_index("ix_notification_logs_user_id", table_name="notification_logs")

    op.drop_constraint(
        "uq_notification_logs_dedupe_key",
        "notification_logs",
        type_="unique",
    )

    op.drop_table("notification_logs")