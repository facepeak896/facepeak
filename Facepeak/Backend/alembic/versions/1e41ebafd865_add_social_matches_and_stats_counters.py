"""add social matches and stats counters

Revision ID: 1e41ebafd865
Revises: f8181523fcf4
Create Date: 2026-05-02 11:12:08.173090

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1e41ebafd865'
down_revision: Union[str, Sequence[str], None] = 'f8181523fcf4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



def upgrade() -> None:
    # ======================
    # USER STATS COUNTERS
    # ======================
    op.add_column("user_stats", sa.Column("unread_messages_count", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("user_stats", sa.Column("message_requests_count", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("user_stats", sa.Column("match_requests_count", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("user_stats", sa.Column("notifications_count", sa.Integer(), nullable=False, server_default="0"))

    op.create_index("idx_user_stats_notifications", "user_stats", ["notifications_count"])
    op.create_index("idx_user_stats_followers", "user_stats", ["followers_count"])
    op.create_index("idx_user_stats_matches", "user_stats", ["matches_count"])

    # ======================
    # MATCH REQUESTS
    # ======================
    op.create_table(
        "match_requests",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("sender_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("receiver_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("sender_id", "receiver_id", name="unique_match_request"),
    )

    op.create_index("ix_match_requests_sender_id", "match_requests", ["sender_id"])
    op.create_index("ix_match_requests_receiver_id", "match_requests", ["receiver_id"])
    op.create_index("ix_match_requests_status", "match_requests", ["status"])
    op.create_index("ix_match_requests_created_at", "match_requests", ["created_at"])
    op.create_index(
        "idx_match_req_receiver_status_created",
        "match_requests",
        ["receiver_id", "status", "created_at"],
    )
    op.create_index(
        "idx_match_req_sender_status_created",
        "match_requests",
        ["sender_id", "status", "created_at"],
    )

    # ======================
    # MATCHES
    # ======================
    op.create_table(
        "matches",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user1_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user2_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("user1_id", "user2_id", name="unique_match_pair"),
    )

    op.create_index("ix_matches_user1_id", "matches", ["user1_id"])
    op.create_index("ix_matches_user2_id", "matches", ["user2_id"])
    op.create_index("idx_matches_user1_created", "matches", ["user1_id", "created_at"])
    op.create_index("idx_matches_user2_created", "matches", ["user2_id", "created_at"])


def downgrade() -> None:
    op.drop_index("idx_matches_user2_created", table_name="matches")
    op.drop_index("idx_matches_user1_created", table_name="matches")
    op.drop_index("ix_matches_user2_id", table_name="matches")
    op.drop_index("ix_matches_user1_id", table_name="matches")
    op.drop_table("matches")

    op.drop_index("idx_match_req_sender_status_created", table_name="match_requests")
    op.drop_index("idx_match_req_receiver_status_created", table_name="match_requests")
    op.drop_index("ix_match_requests_created_at", table_name="match_requests")
    op.drop_index("ix_match_requests_status", table_name="match_requests")
    op.drop_index("ix_match_requests_receiver_id", table_name="match_requests")
    op.drop_index("ix_match_requests_sender_id", table_name="match_requests")
    op.drop_table("match_requests")

    op.drop_index("idx_user_stats_matches", table_name="user_stats")
    op.drop_index("idx_user_stats_followers", table_name="user_stats")
    op.drop_index("idx_user_stats_notifications", table_name="user_stats")

    op.drop_column("user_stats", "notifications_count")
    op.drop_column("user_stats", "match_requests_count")
    op.drop_column("user_stats", "message_requests_count")
    op.drop_column("user_stats", "unread_messages_count")