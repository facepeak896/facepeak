"""add_updated_at_to_follows

Revision ID: e803cc3f8666
Revises: abd2efedf90a
Create Date: 2026-05-07 23:25:14.438863

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e803cc3f8666'
down_revision: Union[str, Sequence[str], None] = 'abd2efedf90a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.add_column(
        "follows",
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )


def downgrade():
    op.drop_column("follows", "updated_at")