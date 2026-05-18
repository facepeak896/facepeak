"""add conversation hidden

Revision ID: ade60f18df87
Revises: 38af7fb3eee0
Create Date: 2026-05-03 19:28:32.537151

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ade60f18df87'
down_revision: Union[str, Sequence[str], None] = '38af7fb3eee0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



def upgrade():
    op.create_table(
        "conversation_hidden",
        sa.Column("id", sa.Integer(), primary_key=True, index=True),
        sa.Column(
            "conversation_id",
            sa.Integer(),
            sa.ForeignKey("conversations.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.UniqueConstraint(
            "conversation_id",
            "user_id",
            name="unique_conversation_hidden_user",
        ),
    )

    op.create_index(
        "idx_conversation_hidden_user",
        "conversation_hidden",
        ["user_id", "conversation_id"],
    )


def downgrade():
    op.drop_index(
        "idx_conversation_hidden_user",
        table_name="conversation_hidden",
    )

    op.drop_table("conversation_hidden")