from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from Backend.Social_free.models.user import User
from Backend.Social_free.services.psl_service import PSLService

from Backend.Social_free.redis import safe_get, safe_set

import json
import logging
import random

logger = logging.getLogger(__name__)

CACHE_TTL = 300


class UserService:

    def __init__(self):
        self.psl_service = PSLService()

    async def get_full_user_snapshot(self, db: AsyncSession, user_id: int):

        cache_key = f"user:snapshot:{user_id}"

        # 🔥 CACHE HOT PATH
        try:
            cached = safe_get(cache_key)
            if cached:
                return json.loads(cached)
        except Exception as e:
            logger.warning(f"[CACHE READ FAIL] {e}")

        # 🔥 USER QUERY
        result = await db.execute(
            select(User)
            .options(selectinload(User.stats))
            .where(User.id == user_id)
        )
        user = result.scalar_one_or_none()

        if not user:
            return None

        stats = user.stats

        # 🔥 PSL
        psl = await self.psl_service.get_latest_psl(db, user_id)

        snapshot = {
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "bio": user.bio,
            "profile_image_url": user.profile_image_url,
            "is_private": user.is_private,

            # 🔥 SOCIAL STATE
            "is_live": user.is_live,
            "social_activated_at": (
                user.social_activated_at.isoformat()
                if user.social_activated_at else None
            ),
            "has_seen_social_explainer": user.has_seen_social_explainer,

            # 🔥 COUNTERS
            "followers": stats.followers_count if stats else 0,
            "following": stats.following_count if stats else 0,
            "matches": stats.matches_count if stats else 0,
            "profile_views": stats.profile_views_count if stats else 0,

            "psl": psl
        }

        # 🔥 CACHE WRITE
        try:
            safe_set(
                cache_key,
                json.dumps(snapshot),
                ex=CACHE_TTL + random.randint(0, 60)
            )
        except Exception as e:
            logger.warning(f"[CACHE WRITE FAIL] {e}")

        return snapshot