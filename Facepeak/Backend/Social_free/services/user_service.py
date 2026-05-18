from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from Backend.Social_free.models.user import User
from Backend.Social_free.models.user_stats import UserStats
from Backend.Social_free.services.psl_service import PSLService
from Backend.Social_free.redis import safe_get, safe_set

import json
import logging
import random
import re

logger = logging.getLogger(__name__)

CACHE_TTL = 300


class UserService:
    def __init__(self):
        self.psl_service = PSLService()

    async def get_or_create_google_user(
        self,
        db: AsyncSession,
        email: str | None,
        google_id: str,
    ):
        result = await db.execute(
            select(User)
            .options(selectinload(User.stats))
            .where(User.google_id == google_id)
        )
        user = result.scalar_one_or_none()

        if user:
            changed = False

            if email and user.email != email:
                user.email = email
                changed = True

            if changed:
                await db.commit()
                await db.refresh(user)

            if not user.stats:
                stats = UserStats(user_id=user.id)
                db.add(stats)
                await db.commit()
                await db.refresh(user)

            return user

        if email:
            result = await db.execute(
                select(User)
                .options(selectinload(User.stats))
                .where(User.email == email)
            )
            user = result.scalar_one_or_none()

            if user:
                user.google_id = google_id
                await db.commit()
                await db.refresh(user)

                if not user.stats:
                    stats = UserStats(user_id=user.id)
                    db.add(stats)
                    await db.commit()
                    await db.refresh(user)

                return user

        user = User(
            google_id=google_id,
            email=email,
        )

        db.add(user)
        await db.flush()

        stats = UserStats(user_id=user.id)
        db.add(stats)

        await db.commit()
        await db.refresh(user)

        return user

    async def get_full_user_snapshot(self, db: AsyncSession, user_id: int):
        cache_key = f"user:snapshot:{user_id}"

        try:
            cached = await safe_get(cache_key)
            if cached:
                try:
                    return json.loads(cached)
                except Exception:
                    pass
        except Exception as e:
            logger.warning(f"[CACHE READ FAIL] {e}")

        result = await db.execute(
            select(User)
            .options(selectinload(User.stats))
            .where(User.id == user_id)
        )
        user = result.scalar_one_or_none()

        if not user:
            return None

        stats = user.stats

        raw_psl = await self.psl_service.get_latest_psl(db, user_id)

        psl = {
            "psl_score": 0,
            "tier": "",
            "percentile": 0,
            "confidence": 0.0,
        }

        if raw_psl:
            psl = {
                "psl_score": raw_psl.get("psl_score", 0),
                "tier": raw_psl.get("tier", ""),
                "percentile": raw_psl.get("percentile", 0),
                "confidence": raw_psl.get("confidence", 0.0),
            }

        raw_username = user.username or ""
        cleaned = re.sub(r"[^A-Za-z]", "", raw_username.strip())[:8]

        if cleaned:
            username = cleaned[0].upper() + cleaned[1:].lower()
        else:
            username = "User"

        profile_image_url = user.profile_image_url or ""

        snapshot = {
            "id": user.id,
            "google_id": user.google_id,
            "email": user.email,
            "username": username,
            "display_name": username,
            "bio": user.bio or "",
            "profile_image_url": profile_image_url,
            "image": profile_image_url,
            "weekly_potential_range": user.weekly_potential_range or "",
            "reach_target_percentile": user.reach_target_percentile or 50,
            "is_live": user.is_live,
            "followers": stats.followers_count if stats else 0,
            "following": stats.following_count if stats else 0,
            "matches": stats.matches_count if stats else 0,
            "profile_views": stats.profile_views_count if stats else 0,
            "psl": psl,
        }

        try:
            await safe_set(
                cache_key,
                json.dumps(snapshot),
                ex=CACHE_TTL + random.randint(0, 60),
            )
        except Exception as e:
            logger.warning(f"[CACHE WRITE FAIL] {e}")

        return snapshot