from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.models.user_push_token import UserPushToken


class PushTokenService:
    async def save_token(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        fcm_token: str,
        platform: str = "android",
        device_id: str | None = None,
    ) -> dict:
        token = (fcm_token or "").strip()

        if not token or len(token) < 20:
            raise ValueError("INVALID_FCM_TOKEN")

        platform = (platform or "android").strip().lower()[:30]
        device_id = (device_id or "").strip() or None

        now = datetime.now(timezone.utc)

        result = await db.execute(
            select(UserPushToken).where(UserPushToken.fcm_token == token)
        )
        existing = result.scalar_one_or_none()

        if existing:
            existing.user_id = user_id
            existing.platform = platform
            existing.device_id = device_id
            existing.is_active = True
            existing.last_seen_at = now
            await db.commit()
            await db.refresh(existing)

            return {
                "id": existing.id,
                "status": "updated",
                "is_active": existing.is_active,
            }

        push_token = UserPushToken(
            user_id=user_id,
            fcm_token=token,
            platform=platform,
            device_id=device_id,
            is_active=True,
            last_seen_at=now,
        )

        db.add(push_token)
        await db.commit()
        await db.refresh(push_token)

        return {
            "id": push_token.id,
            "status": "created",
            "is_active": push_token.is_active,
        }

    async def deactivate_token(
        self,
        db: AsyncSession,
        *,
        fcm_token: str,
    ) -> bool:
        token = (fcm_token or "").strip()
        if not token:
            return False

        result = await db.execute(
            select(UserPushToken).where(UserPushToken.fcm_token == token)
        )
        existing = result.scalar_one_or_none()

        if not existing:
            return False

        existing.is_active = False
        existing.last_seen_at = datetime.now(timezone.utc)

        await db.commit()
        return True