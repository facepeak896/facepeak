"""add dm conversations messages safety

Revision ID: 9516db920132
Revises: 1e41ebafd865
Create Date: 2026-05-02 22:14:30.308888

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9516db920132'
down_revision: Union[str, Sequence[str], None] = '1e41ebafd865'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



def upgrade() -> None:
    # ======================
    # MESSAGE REQUESTS
    # ======================
    op.create_table(
        "message_requests",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("sender_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("receiver_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("sender_id", "receiver_id", name="unique_message_request"),
    )

    op.create_index("ix_message_requests_sender_id", "message_requests", ["sender_id"])
    op.create_index("ix_message_requests_receiver_id", "message_requests", ["receiver_id"])
    op.create_index("ix_message_requests_status", "message_requests", ["status"])
    op.create_index("ix_message_requests_created_at", "message_requests", ["created_at"])
    op.create_index(
        "idx_msg_req_receiver_status_created",
        "message_requests",
        ["receiver_id", "status", "created_at"],
    )
    op.create_index(
        "idx_msg_req_sender_status_created",
        "message_requests",
        ["sender_id", "status", "created_at"],
    )

    # ======================
    # CONVERSATIONS
    # ======================
    op.create_table(
        "conversations",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user1_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user2_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("last_message_id", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("user1_id", "user2_id", name="unique_conversation_pair"),
    )

    op.create_index("ix_conversations_user1_id", "conversations", ["user1_id"])
    op.create_index("ix_conversations_user2_id", "conversations", ["user2_id"])
    op.create_index("ix_conversations_last_message_id", "conversations", ["last_message_id"])
    op.create_index("ix_conversations_created_at", "conversations", ["created_at"])
    op.create_index("ix_conversations_updated_at", "conversations", ["updated_at"])
    op.create_index("idx_conversation_user1_updated", "conversations", ["user1_id", "updated_at"])
    op.create_index("idx_conversation_user2_updated", "conversations", ["user2_id", "updated_at"])

    # ======================
    # MESSAGES
    # ======================
    op.create_table(
        "messages",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("conversation_id", sa.Integer(), sa.ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("sender_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("receiver_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("body", sa.String(length=500), nullable=False),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("delivered_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("seen_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_index("ix_messages_conversation_id", "messages", ["conversation_id"])
    op.create_index("ix_messages_sender_id", "messages", ["sender_id"])
    op.create_index("ix_messages_receiver_id", "messages", ["receiver_id"])
    op.create_index("ix_messages_is_deleted", "messages", ["is_deleted"])
    op.create_index("ix_messages_delivered_at", "messages", ["delivered_at"])
    op.create_index("ix_messages_seen_at", "messages", ["seen_at"])
    op.create_index("ix_messages_created_at", "messages", ["created_at"])
    op.create_index("idx_messages_conversation_created", "messages", ["conversation_id", "created_at"])
    op.create_index("idx_messages_receiver_seen", "messages", ["receiver_id", "seen_at"])
    op.create_index("idx_messages_sender_created", "messages", ["sender_id", "created_at"])

    # Add FK conversations.last_message_id -> messages.id after messages exists
    op.create_foreign_key(
        "fk_conversations_last_message_id_messages",
        "conversations",
        "messages",
        ["last_message_id"],
        ["id"],
        ondelete="SET NULL",
    )

    # ======================
    # USER BLOCKS
    # ======================
    op.create_table(
        "user_blocks",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("blocker_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("blocked_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("blocker_id", "blocked_id", name="unique_user_block"),
    )

    op.create_index("ix_user_blocks_blocker_id", "user_blocks", ["blocker_id"])
    op.create_index("ix_user_blocks_blocked_id", "user_blocks", ["blocked_id"])
    op.create_index("ix_user_blocks_created_at", "user_blocks", ["created_at"])
    op.create_index("idx_block_blocker_created", "user_blocks", ["blocker_id", "created_at"])
    op.create_index("idx_block_blocked_created", "user_blocks", ["blocked_id", "created_at"])

    # ======================
    # USER REPORTS
    # ======================
    op.create_table(
        "user_reports",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("reporter_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("reported_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("reason", sa.String(length=80), nullable=False),
        sa.Column("details", sa.String(length=500), nullable=True),
        sa.Column("status", sa.String(length=30), nullable=False, server_default="open"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_index("ix_user_reports_reporter_id", "user_reports", ["reporter_id"])
    op.create_index("ix_user_reports_reported_id", "user_reports", ["reported_id"])
    op.create_index("ix_user_reports_status", "user_reports", ["status"])
    op.create_index("ix_user_reports_created_at", "user_reports", ["created_at"])
    op.create_index(
        "idx_reports_reported_status_created",
        "user_reports",
        ["reported_id", "status", "created_at"],
    )
    op.create_index(
        "idx_reports_reporter_created",
        "user_reports",
        ["reporter_id", "created_at"],
    )


def downgrade() -> None:
    # USER REPORTS
    op.drop_index("idx_reports_reporter_created", table_name="user_reports")
    op.drop_index("idx_reports_reported_status_created", table_name="user_reports")
    op.drop_index("ix_user_reports_created_at", table_name="user_reports")
    op.drop_index("ix_user_reports_status", table_name="user_reports")
    op.drop_index("ix_user_reports_reported_id", table_name="user_reports")
    op.drop_index("ix_user_reports_reporter_id", table_name="user_reports")
    op.drop_table("user_reports")

    # USER BLOCKS
    op.drop_index("idx_block_blocked_created", table_name="user_blocks")
    op.drop_index("idx_block_blocker_created", table_name="user_blocks")
    op.drop_index("ix_user_blocks_created_at", table_name="user_blocks")
    op.drop_index("ix_user_blocks_blocked_id", table_name="user_blocks")
    op.drop_index("ix_user_blocks_blocker_id", table_name="user_blocks")
    op.drop_table("user_blocks")

    # CONVERSATIONS FK
    op.drop_constraint(
        "fk_conversations_last_message_id_messages",
        "conversations",
        type_="foreignkey",
    )

    # MESSAGES
    op.drop_index("idx_messages_sender_created", table_name="messages")
    op.drop_index("idx_messages_receiver_seen", table_name="messages")
    op.drop_index("idx_messages_conversation_created", table_name="messages")
    op.drop_index("ix_messages_created_at", table_name="messages")
    op.drop_index("ix_messages_seen_at", table_name="messages")
    op.drop_index("ix_messages_delivered_at", table_name="messages")
    op.drop_index("ix_messages_is_deleted", table_name="messages")
    op.drop_index("ix_messages_receiver_id", table_name="messages")
    op.drop_index("ix_messages_sender_id", table_name="messages")
    op.drop_index("ix_messages_conversation_id", table_name="messages")
    op.drop_table("messages")

    # CONVERSATIONS
    op.drop_index("idx_conversation_user2_updated", table_name="conversations")
    op.drop_index("idx_conversation_user1_updated", table_name="conversations")
    op.drop_index("ix_conversations_updated_at", table_name="conversations")
    op.drop_index("ix_conversations_created_at", table_name="conversations")
    op.drop_index("ix_conversations_last_message_id", table_name="conversations")
    op.drop_index("ix_conversations_user2_id", table_name="conversations")
    op.drop_index("ix_conversations_user1_id", table_name="conversations")
    op.drop_table("conversations")

    # MESSAGE REQUESTS
    op.drop_index("idx_msg_req_sender_status_created", table_name="message_requests")
    op.drop_index("idx_msg_req_receiver_status_created", table_name="message_requests")
    op.drop_index("ix_message_requests_created_at", table_name="message_requests")
    op.drop_index("ix_message_requests_status", table_name="message_requests")
    op.drop_index("ix_message_requests_receiver_id", table_name="message_requests")
    op.drop_index("ix_message_requests_sender_id", table_name="message_requests")
    op.drop_table("message_requests")