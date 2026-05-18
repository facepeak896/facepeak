"""add seen_at to follows

Revision ID: d3745003af50
Revises: 3a99b1147106
Create Date: 2026-05-18 13:46:46.704591

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd3745003af50'
down_revision: Union[str, Sequence[str], None] = '3a99b1147106'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.add_column(
        "follows",
        sa.Column(
            "seen_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )


def downgrade():
    op.drop_column(
        "follows",
        "seen_at",
    )