"""add report severity admin note unique

Revision ID: 38af7fb3eee0
Revises: 0c46b9797829
Create Date: 2026-05-03 18:51:01.561070

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '38af7fb3eee0'
down_revision: Union[str, Sequence[str], None] = '0c46b9797829'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



def upgrade():
    op.add_column(
        "user_reports",
        sa.Column("severity", sa.Integer(), nullable=False, server_default="1"),
    )
    op.add_column(
        "user_reports",
        sa.Column("admin_note", sa.String(length=500), nullable=True),
    )
    op.create_unique_constraint(
        "unique_user_report",
        "user_reports",
        ["reporter_id", "reported_id"],
    )


def downgrade():
    op.drop_constraint("unique_user_report", "user_reports", type_="unique")
    op.drop_column("user_reports", "admin_note")
    op.drop_column("user_reports", "severity")