from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.models.message_request import MessageRequest
from Backend.Social_free.models.match_request import MatchRequest
from Backend.Social_free.models.message import Message
from Backend.Social_free.models.follow import Follow


class SocialBadgeService:
    async def get_badges(
        self,
        db: AsyncSession,
        *,
        user_id: int,
    ) -> dict:
        message_requests = await db.scalar(
            select(func.count(MessageRequest.id)).where(
                MessageRequest.receiver_id == user_id,
                MessageRequest.status == "pending",
            )
        ) or 0

        match_requests = await db.scalar(
            select(func.count(MatchRequest.id)).where(
                MatchRequest.receiver_id == user_id,
                MatchRequest.status == "pending",
            )
        ) or 0

        dm_unread = await db.scalar(
            select(func.count(Message.id)).where(
                Message.receiver_id == user_id,
                Message.seen_at.is_(None),
                Message.is_deleted == False,
            )
        ) or 0

        follow_events = await db.scalar(
            select(func.count(Follow.id)).where(
                Follow.following_id == user_id,
                Follow.status == "accepted",
                Follow.seen_at.is_(None),
            )
        ) or 0

        total = (
            int(message_requests)
            + int(match_requests)
            + int(dm_unread)
            + int(follow_events)
        )

        return {
            "dm_unread": int(dm_unread),
            "message_requests": int(message_requests),
            "match_requests": int(match_requests),
            "follow_events": int(follow_events),
            "total": int(total),
        }