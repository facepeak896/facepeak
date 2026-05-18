from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import update
from sqlalchemy.sql import func
import logging

from Backend.Social_free.models.user import User
from Backend.Social_free.redis import safe_delete
from Backend.Social_free.services.user_service import UserService

logger = logging.getLogger(__name__)


class SocialActivationService:
    def __init__(self):
        self.user_service = UserService()

    async def activate_live_profile(self, db: AsyncSession, user_id: int):
        try:
            await db.execute(
                update(User)
                .where(User.id == user_id)
                .values(
                    is_live=True,
                    social_activated_at=func.now(),
                )
            )
            await db.commit()
        except Exception as e:
            logger.error(f"[GO LIVE UPDATE ERROR] {e}")
            raise

        try:
            await safe_delete(f"user:snapshot:{user_id}")
        except Exception as e:
            logger.warning(f"[CACHE DELETE FAIL] {e}")

        return await self.user_service.get_full_user_snapshot(db, user_id)

    async def mark_social_explainer_seen(self, db: AsyncSession, user_id: int):
        try:
            await db.execute(
                update(User)
                .where(User.id == user_id)
                .values(has_seen_social_explainer=True)
            )
            await db.commit()
        except Exception as e:
            logger.error(f"[EXPLAINER UPDATE ERROR] {e}")
            return None

        return {
            "status": "success",
            "explainer_seen": True,
        }