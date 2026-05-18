"""make delivered_at nullable

Revision ID: abd2efedf90a
Revises: 5958439c1870
Create Date: 2026-05-05 21:42:14.789263

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'abd2efedf90a'
down_revision: Union[str, Sequence[str], None] = '5958439c1870'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.alter_column(
        "messages",
        "delivered_at",
        existing_type=sa.DateTime(timezone=True),
        nullable=True,
        server_default=None,
    )

def downgrade():
    op.alter_column(
        "messages",
        "delivered_at",
        existing_type=sa.DateTime(timezone=True),
        nullable=False,
        server_default=sa.text("now()"),
    )