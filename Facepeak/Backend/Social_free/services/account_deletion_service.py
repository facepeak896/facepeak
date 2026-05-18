from sqlalchemy import delete, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from Backend.Social_free.models.user import User
from Backend.Social_free.models.user_stats import UserStats
from Backend.Social_free.models.user_psl import UserPSL
from Backend.Social_free.models.user_push_token import UserPushToken

from Backend.Social_free.models.follow import Follow
from Backend.Social_free.models.match_request import MatchRequest
from Backend.Social_free.models.match_table import Match

from Backend.Social_free.models.message_request import MessageRequest
from Backend.Social_free.models.message import Message
from Backend.Social_free.models.conversation import Conversation
from Backend.Social_free.models.conversation_hidden import ConversationHidden

from Backend.Social_free.models.user_block import UserBlock
from Backend.Social_free.models.user_report import UserReport

from Backend.Social_free.models.message_rate_limits import MessageRateLimit
from Backend.Social_free.models.notification_log import NotificationLog


class AccountDeletionService:

    @staticmethod
    async def permanently_delete_user(
        db: AsyncSession,
        user_id: int,
    ):
        # =========================
        # SIMPLE USER TABLES
        # =========================

        await db.execute(
            delete(UserStats).where(UserStats.user_id == user_id)
        )

        await db.execute(
            delete(UserPSL).where(UserPSL.user_id == user_id)
        )

        await db.execute(
            delete(UserPushToken).where(
                UserPushToken.user_id == user_id
            )
        )

        await db.execute(
            delete(MessageRateLimit).where(
                MessageRateLimit.user_id == user_id
            )
        )

        await db.execute(
            delete(NotificationLog).where(
                NotificationLog.user_id == user_id
            )
        )

        # =========================
        # SOCIAL GRAPH
        # =========================

        await db.execute(
            delete(Follow).where(
                or_(
                    Follow.follower_id == user_id,
                    Follow.following_id == user_id,
                )
            )
        )

        await db.execute(
            delete(MatchRequest).where(
                or_(
                    MatchRequest.sender_id == user_id,
                    MatchRequest.receiver_id == user_id,
                )
            )
        )

        await db.execute(
            delete(Match).where(
                or_(
                    Match.user1_id == user_id,
                    Match.user2_id == user_id,
                )
            )
        )

        # =========================
        # MESSAGE REQUESTS
        # =========================

        await db.execute(
            delete(MessageRequest).where(
                or_(
                    MessageRequest.sender_id == user_id,
                    MessageRequest.receiver_id == user_id,
                )
            )
        )

        # =========================
        # BLOCKS / REPORTS
        # =========================

        await db.execute(
            delete(UserBlock).where(
                or_(
                    UserBlock.blocker_id == user_id,
                    UserBlock.blocked_id == user_id,
                )
            )
        )

        await db.execute(
            delete(UserReport).where(
                or_(
                    UserReport.reporter_id == user_id,
                    UserReport.reported_id == user_id,
                )
            )
        )

        # =========================
        # CONVERSATIONS
        # =========================

        conversations = await db.execute(
            select(Conversation.id).where(
                or_(
                    Conversation.user1_id == user_id,
                    Conversation.user2_id == user_id,
                )
            )
        )

        conversation_ids = conversations.scalars().all()

        if conversation_ids:
            await db.execute(
                delete(Message).where(
                    Message.conversation_id.in_(conversation_ids)
                )
            )

            await db.execute(
                delete(ConversationHidden).where(
                    ConversationHidden.conversation_id.in_(conversation_ids)
                )
            )

            await db.execute(
                delete(Conversation).where(
                    Conversation.id.in_(conversation_ids)
                )
            )

        # =========================
        # FINAL USER DELETE
        # =========================

        await db.execute(
            delete(User).where(User.id == user_id)
        )

        await db.commit()