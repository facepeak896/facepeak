from datetime import datetime, timedelta, timezone
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.services.notification_service import NotificationService


SOCIAL_RESCORE_COOLDOWN_DAYS = 3


class SocialRescoreLimitService:

    @staticmethod
    def utcnow():
        return datetime.now(timezone.utc)

    @staticmethod
    def get_next_available_at(user):
        last = getattr(user, "last_social_rescore_at", None)

        if not last:
            return None

        if last.tzinfo is None:
            last = last.replace(tzinfo=timezone.utc)

        return last + timedelta(days=SOCIAL_RESCORE_COOLDOWN_DAYS)

    @staticmethod
    def build_state(user):
        next_available_at = (
            SocialRescoreLimitService.get_next_available_at(user)
        )

        if next_available_at is None:
            return {
                "allowed": True,
                "cooldown_active": False,
                "next_available_at": None,
                "remaining_seconds": 0,
            }

        now = SocialRescoreLimitService.utcnow()

        if now >= next_available_at:
            return {
                "allowed": True,
                "cooldown_active": False,
                "next_available_at": None,
                "remaining_seconds": 0,
            }

        remaining_seconds = int(
            (next_available_at - now).total_seconds()
        )

        return {
            "allowed": False,
            "cooldown_active": True,
            "next_available_at": next_available_at.isoformat(),
            "remaining_seconds": remaining_seconds,
        }

    @staticmethod
    def enforce(user):
        state = SocialRescoreLimitService.build_state(user)

        if not state["allowed"]:
            raise HTTPException(
                status_code=429,
                detail={
                    "code": "SOCIAL_RESCORE_COOLDOWN",
                    "message": "Social rescore cooldown active.",
                    **state,
                },
            )

        return state

    @staticmethod
    async def mark_success(
        db: AsyncSession,
        user,
    ):
        now = SocialRescoreLimitService.utcnow()

        user.last_social_rescore_at = now

        next_available_at = (
            now + timedelta(days=SOCIAL_RESCORE_COOLDOWN_DAYS)
        )

        try:
            await NotificationService.schedule_chat_limit_reset(
                db=db,
                user_id=user.id,
                reset_at=next_available_at,
            )
        except Exception as e:
            print("SOCIAL RESCORE RESET PUSH SCHEDULE ERROR:", e)

        return {
            "cooldown_active": True,
            "next_available_at": next_available_at.isoformat(),
            "remaining_seconds": int(
                timedelta(days=SOCIAL_RESCORE_COOLDOWN_DAYS).total_seconds()
            ),
        }