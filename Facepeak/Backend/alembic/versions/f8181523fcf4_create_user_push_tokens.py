"""create user push tokens

Revision ID: f8181523fcf4
Revises: fix_users_defaults_google_only
Create Date: 2026-05-01 21:58:04.444390

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f8181523fcf4'
down_revision: Union[str, Sequence[str], None] = 'fix_users_defaults_google_only'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



def upgrade() -> None:
    # 🔥 FIX: ako već postoji (jer si možda radio create_all)
    op.execute("DROP TABLE IF EXISTS user_push_tokens CASCADE")

    # ✅ CREATE TABLE
    op.create_table(
        "user_push_tokens",
        sa.Column("id", sa.Integer(), primary_key=True),

        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),

        sa.Column(
            "fcm_token",
            sa.String(length=512),
            nullable=False,
            unique=True,
        ),

        sa.Column(
            "platform",
            sa.String(length=30),
            nullable=False,
            server_default="android",
        ),

        sa.Column(
            "device_id",
            sa.String(length=255),
            nullable=True,
        ),

        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),

        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),

        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),

        sa.Column(
            "last_seen_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )

    # 🔥 INDEXES (bitni za performanse)
    op.create_index(
        "ix_push_user_id",
        "user_push_tokens",
        ["user_id"],
    )

    op.create_index(
        "ix_push_fcm_token",
        "user_push_tokens",
        ["fcm_token"],
        unique=True,
    )

    op.create_index(
        "ix_push_device_id",
        "user_push_tokens",
        ["device_id"],
    )

    op.create_index(
        "ix_push_is_active",
        "user_push_tokens",
        ["is_active"],
    )

    op.create_index(
        "ix_push_last_seen",
        "user_push_tokens",
        ["last_seen_at"],
    )

    # 🔥 composite indexes (kao u modelu)
    op.create_index(
        "idx_push_user_active",
        "user_push_tokens",
        ["user_id", "is_active"],
    )

    op.create_index(
        "idx_push_device",
        "user_push_tokens",
        ["user_id", "device_id"],
    )