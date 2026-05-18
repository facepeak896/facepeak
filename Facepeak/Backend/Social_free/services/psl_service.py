from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from Backend.Social_free.models.user_psl import UserPSL
from Backend.Social_free.redis import safe_get, safe_set, safe_delete

import json
import logging
import random

logger = logging.getLogger(__name__)

CACHE_TTL = 300


class PSLService:

    async def save_psl_result(
        self,
        db: AsyncSession,
        user_id: int,
        score: float,
        tier: str,
        percentile,
        confidence: float,
    ):
        score = round(float(score or 0), 2)
        percentile = self._normalize_percentile(percentile)

        new_psl = UserPSL(
            user_id=user_id,
            psl_score=score,
            tier=tier,
            percentile=percentile,
            confidence=confidence or 0.0,
        )

        db.add(new_psl)
        await db.commit()

        data = {
            "psl_score": score,
            "tier": tier or "",
            "percentile": percentile or 0,
            "confidence": confidence or 0.0,
        }

        try:
            await safe_set(
                f"psl:latest:{user_id}",
                json.dumps(data),
                ex=CACHE_TTL + random.randint(0, 60),
            )
            await safe_delete(f"user:snapshot:{user_id}")
        except Exception as e:
            logger.warning(f"[CACHE WRITE FAIL] {e}")

        return data

    async def get_latest_psl(self, db: AsyncSession, user_id: int):

        cache_key = f"psl:latest:{user_id}"

        try:
            cached = await safe_get(cache_key)
            if cached:
                try:
                    return json.loads(cached)
                except:
                    pass
        except Exception as e:
            logger.warning(f"[CACHE READ FAIL] {e}")

        result = await db.execute(
            select(
                UserPSL.psl_score,
                UserPSL.tier,
                UserPSL.percentile,
                UserPSL.confidence,
            )
            .where(UserPSL.user_id == user_id)
            .order_by(UserPSL.created_at.desc())
            .limit(1)
        )

        row = result.first()

        if not row:
            return None

        psl_score, tier, percentile, confidence = row

        data = {
            "psl_score": psl_score or 0,
            "tier": tier or "",
            "percentile": percentile or 0,
            "confidence": confidence or 0.0,
        }

        try:
            await safe_set(
                cache_key,
                json.dumps(data),
                ex=CACHE_TTL + random.randint(0, 60),
            )
        except Exception as e:
            logger.warning(f"[CACHE WRITE FAIL] {e}")

        return data

    def _normalize_percentile(self, percentile):
        if percentile is None:
            return None

        if isinstance(percentile, int):
            return max(1, min(100, percentile))

        if isinstance(percentile, float):
            return max(1, min(100, int(round(percentile))))

        text = str(percentile)
        digits = "".join(ch for ch in text if ch.isdigit())

        if not digits:
            return None

        return max(1, min(100, int(digits)))