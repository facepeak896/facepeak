from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import update, select
from sqlalchemy.sql import func  # 🔥 DODANO
import json
import random
import logging

from Backend.Social_free.models.user import User
from Backend.Social_free.models.user_stats import UserStats
from Backend.Social_free.services.psl_service import PSLService
from Backend.Social_free.redis import safe_set, safe_delete

logger = logging.getLogger(__name__)

CACHE_TTL = 300


class SocialActivationService:

    def __init__(self):
        self.psl_service = PSLService()

    # =========================
    # 🔥 GO LIVE (CORE)
    # =========================
    async def activate_live_profile(self, db: AsyncSession, user_id: int):

        # 1. 🔥 SET LIVE FLAG (idempotent)
        try:
            await db.execute(
                update(User)
                .where(User.id == user_id)
                .values(
                    is_live=True,                     # ✅ FIX
                    social_activated_at=func.now(),  # ✅ FIX
                )
            )
            await db.commit()
        except Exception as e:
            logger.error(f"[GO LIVE UPDATE ERROR] {e}")
            raise

        # 2. 🔥 GET USER + STATS
        result = await db.execute(
            select(User)
            .where(User.id == user_id)
        )
        user = result.scalar_one_or_none()

        if not user:
            return None

        stats = user.stats

        # 3. 🔥 PSL SNAPSHOT
        try:
            psl = await self.psl_service.get_latest_psl(db, user_id)
        except Exception as e:
            logger.warning(f"[PSL FAIL] {e}")
            psl = None

        snapshot = {
            "id": user.id,
            "username": user.username,
            "bio": user.bio,
            "profile_image_url": user.profile_image_url,

            "followers": stats.followers_count if stats else 0,
            "following": stats.following_count if stats else 0,
            "matches": stats.matches_count if stats else 0,
            "profile_views": stats.profile_views_count if stats else 0,

            "psl": psl,
            "is_live": True,
        }

        # 4. 🔥 CACHE INVALIDATION
        try:
            safe_delete(f"user:snapshot:{user_id}")
        except Exception as e:
            logger.warning(f"[CACHE DELETE FAIL] {e}")

        # 5. 🔥 CACHE WRITE (FAST PATH)
        try:
            safe_set(
                f"user:snapshot:{user_id}",
                json.dumps(snapshot),
                ex=CACHE_TTL + random.randint(0, 60),
            )
        except Exception as e:
            logger.warning(f"[CACHE WRITE FAIL] {e}")

        return snapshot

    # =========================
    # 🔥 EXPLAINER SEEN (UI STATE)
    # =========================
    async def mark_social_explainer_seen(self, db: AsyncSession, user_id: int):

        try:
            await db.execute(
                update(User)
                .where(User.id == user_id)
                .values()
            )
            await db.commit()
        except Exception as e:
            logger.error(f"[EXPLAINER UPDATE ERROR] {e}")
            return None

        return {
            "status": "success",
            "explainer_seen": True
        }