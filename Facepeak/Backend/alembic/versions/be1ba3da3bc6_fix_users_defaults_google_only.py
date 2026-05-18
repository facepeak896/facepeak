from alembic import op
import sqlalchemy as sa


revision = "fix_users_defaults_google_only"
down_revision = None  # AKO TI JE PRVA MIGRACIJA, INAČE STAVI PRETHODNI
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        ALTER TABLE users
        DROP COLUMN IF EXISTS password_hash
    """)

    op.execute("""
        UPDATE users
        SET is_active = true
        WHERE is_active IS NULL OR is_active = false
    """)

    op.execute("""
        UPDATE users
        SET is_banned = false
        WHERE is_banned IS NULL
    """)

    op.execute("""
        UPDATE users
        SET is_live = false
        WHERE is_live IS NULL
    """)

    op.execute("""
        UPDATE users
        SET has_seen_social_explainer = false
        WHERE has_seen_social_explainer IS NULL
    """)

    op.execute("""
        UPDATE users
        SET reach_target_percentile = 50
        WHERE reach_target_percentile IS NULL
    """)

    op.alter_column(
        "users",
        "is_active",
        existing_type=sa.Boolean(),
        nullable=False,
        server_default=sa.text("true"),
    )

    op.alter_column(
        "users",
        "is_banned",
        existing_type=sa.Boolean(),
        nullable=False,
        server_default=sa.text("false"),
    )

    op.alter_column(
        "users",
        "is_live",
        existing_type=sa.Boolean(),
        nullable=False,
        server_default=sa.text("false"),
    )

    op.alter_column(
        "users",
        "has_seen_social_explainer",
        existing_type=sa.Boolean(),
        nullable=False,
        server_default=sa.text("false"),
    )

    op.alter_column(
        "users",
        "reach_target_percentile",
        existing_type=sa.Integer(),
        nullable=False,
        server_default=sa.text("50"),
    )


def downgrade():
    pass