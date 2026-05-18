# Backend/Social_free/services/test_push_service.py

from __future__ import annotations

import random
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.models.user import User
from Backend.Social_free.services.notification_service import NotificationService


class TestPushService:
    """
    TEST RETENTION PUSH SERVICE

    Sends smart retention pushes every 3 minutes
    to all active non-banned users.
    """

    SLOT_SECONDS = 180  # 3 minutes

    @staticmethod
    def _now() -> datetime:
        return datetime.now(timezone.utc)

    @classmethod
    def _slot_key(cls) -> str:
        slot = int(cls._now().timestamp() // cls.SLOT_SECONDS)
        return f"test:{slot}"

    @classmethod
    def _pick_push(cls) -> tuple[str, str]:
        pushes = [
            (
                "👀 Your profile is active",
                "Open FacePeak to check new activity.",
            ),
            (
                "🔥 Start getting matches",
                "Interact now to boost your profile.",
            ),
            (
                "📈 Your reach is moving",
                "See what changed on your profile.",
            ),
            (
                "✨ Your profile was noticed",
                "Open FacePeak to continue growing.",
            ),
            (
                "💎 Premium shows your potential",
                "Unlock deeper analysis and next moves.",
            ),
        ]

        return random.choice(pushes)

    @classmethod
    async def run(
        cls,
        db: AsyncSession,
    ) -> dict[str, Any]:

        result = await db.execute(
            select(User).where(
                User.is_active == True,
                User.is_banned == False,
            )
        )

        users = result.scalars().all()

        sent = 0
        skipped = 0
        failed = 0

        slot = cls._slot_key()

        for user in users:
            title, body = cls._pick_push()

            try:
                push = await NotificationService.send_now(
                    db=db,
                    user_id=user.id,
                    notification_type="test_smart_push",
                    dedupe_key=f"test_smart_push:{user.id}:{slot}",
                    title=title,
                    body=body,
                    data={
                        "type": "test_smart_push",
                        "screen": "social_live",
                    },
                    daily_limit=None,
                )

                status = push.get("status")

                if status == "sent":
                    sent += 1
                elif status == "skipped":
                    skipped += 1
                else:
                    failed += 1

            except Exception as e:
                print(f"❌ TEST PUSH ERROR user={user.id} -> {e}")
                failed += 1

        return {
            "status": "success",
            "mode": "3_min_test_push",
            "slot": slot,
            "users": len(users),
            "sent": sent,
            "skipped": skipped,
            "failed": failed,
        }