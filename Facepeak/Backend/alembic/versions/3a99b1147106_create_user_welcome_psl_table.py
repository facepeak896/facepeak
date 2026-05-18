"""create user_welcome_psl table

Revision ID: 3a99b1147106
Revises: 870c07fc1c9c
Create Date: 2026-05-17 17:18:35.607857

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '3a99b1147106'
down_revision: Union[str, Sequence[str], None] = '870c07fc1c9c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.create_table(
        "user_welcome_psl",

        sa.Column(
            "id",
            sa.Integer(),
            primary_key=True,
            nullable=False,
        ),

        # =================================================
        # OWNER
        # =================================================

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

        # =================================================
        # FLOW STATE
        # =================================================

        sa.Column(
            "welcome_loading_done",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),

        sa.Column(
            "welcome_access_chosen",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),

        sa.Column(
            "access_tier",
            sa.String(),
            nullable=True,
        ),

        # =================================================
        # PSL RESULT
        # =================================================

        sa.Column(
        "psl_result",
        postgresql.JSONB(),
    nullable=True,
),

        # =================================================
        # META
        # =================================================

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
    )

    # =====================================================
    # INDEX
    # =====================================================

    op.create_index(
        "ix_user_welcome_psl_user_id",
        "user_welcome_psl",
        ["user_id"],
        unique=True,
    )


# =========================================================
# DOWNGRADE
# =========================================================

def downgrade():
    op.drop_index(
        "ix_user_welcome_psl_user_id",
        table_name="user_welcome_psl",
    )

    op.drop_table("user_welcome_psl")