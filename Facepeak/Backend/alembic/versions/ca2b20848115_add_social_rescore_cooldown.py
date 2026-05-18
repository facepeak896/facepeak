"""add social rescore cooldown

Revision ID: ca2b20848115
Revises: e803cc3f8666
Create Date: 2026-05-10 01:12:57.041417

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ca2b20848115'
down_revision: Union[str, Sequence[str], None] = 'e803cc3f8666'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.add_column(
        "users",
        sa.Column(
            "last_social_rescore_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    op.create_index(
        "idx_user_last_social_rescore",
        "users",
        ["last_social_rescore_at"],
    )


def downgrade():
    op.drop_index(
        "idx_user_last_social_rescore",
        table_name="users",
    )

    op.drop_column(
        "users",
        "last_social_rescore_at",
    )