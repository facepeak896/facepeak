from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.models.message_rate_limits import MessageRateLimit
from Backend.Social_free.services.notification_service import NotificationService


class MessageRateLimitService:
    LIMIT = 15
    WINDOW_HOURS = 24

    @classmethod
    def _now(cls) -> datetime:
        return datetime.now(timezone.utc)

    @classmethod
    def _reset_at(cls, window_start: datetime) -> datetime:
        if window_start.tzinfo is None:
            window_start = window_start.replace(tzinfo=timezone.utc)

        return window_start + timedelta(hours=cls.WINDOW_HOURS)

    @classmethod
    async def get_status(cls, db: AsyncSession, user_id: int) -> dict:
        now = cls._now()

        result = await db.execute(
            select(MessageRateLimit).where(
                MessageRateLimit.user_id == user_id
            )
        )

        row = result.scalar_one_or_none()

        if row is None:
            return {
                "limit": cls.LIMIT,
                "remaining": cls.LIMIT,
                "used": 0,
                "allowed": True,
                "reset_at": (now + timedelta(hours=cls.WINDOW_HOURS)).isoformat(),
            }

        reset_at = cls._reset_at(row.window_start)

        if now >= reset_at:
            row.window_start = now
            row.messages_sent = 0
            await db.commit()
            await db.refresh(row)

            return {
                "limit": cls.LIMIT,
                "remaining": cls.LIMIT,
                "used": 0,
                "allowed": True,
                "reset_at": cls._reset_at(row.window_start).isoformat(),
            }

        used = int(row.messages_sent or 0)
        remaining = max(cls.LIMIT - used, 0)

        return {
            "limit": cls.LIMIT,
            "remaining": remaining,
            "used": used,
            "allowed": remaining > 0,
            "reset_at": reset_at.isoformat(),
        }

    @classmethod
    async def consume_or_raise(cls, db: AsyncSession, user_id: int) -> dict:
        now = cls._now()

        result = await db.execute(
            select(MessageRateLimit)
            .where(MessageRateLimit.user_id == user_id)
            .with_for_update()
        )

        row = result.scalar_one_or_none()

        if row is None:
            row = MessageRateLimit(
                user_id=user_id,
                window_start=now,
                messages_sent=0,
            )
            db.add(row)
            await db.flush()

        reset_at = cls._reset_at(row.window_start)

        if now >= reset_at:
            row.window_start = now
            row.messages_sent = 0
            await db.flush()

        if row.messages_sent >= cls.LIMIT:
            await db.rollback()

            raise HTTPException(
                status_code=429,
                detail={
                    "code": "DAILY_MESSAGE_LIMIT_REACHED",
                    "limit": cls.LIMIT,
                    "remaining": 0,
                    "reset_at": reset_at.isoformat(),
                },
            )

        row.messages_sent += 1
        await db.flush()

        reset_at = cls._reset_at(row.window_start)
        remaining = max(cls.LIMIT - row.messages_sent, 0)

        # 🔔 Schedule push only when user just used the last daily message.
        # NotificationService has dedupe_key, so this won't duplicate for same reset_at.
        if remaining == 0:
            try:
                await NotificationService.schedule_chat_limit_reset(
                    db=db,
                    user_id=user_id,
                    reset_at=reset_at,
                )
            except Exception:
                pass

        return {
            "limit": cls.LIMIT,
            "remaining": remaining,
            "used": row.messages_sent,
            "allowed": remaining > 0,
            "reset_at": reset_at.isoformat(),
        }