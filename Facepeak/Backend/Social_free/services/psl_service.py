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
        percentile: float,
        confidence: float,
    ):
        # 🔥 normalize once (no double rounding later)
        score = round(score, 2)

        new_psl = UserPSL(
            user_id=user_id,
            psl_score=score,
            tier=tier,
            percentile=percentile,
            confidence=confidence,
        )

        db.add(new_psl)
        await db.commit()

        data = {
            "score": score,
            "tier": tier,
            "percentile": percentile,
            "confidence": confidence,
        }

        # 🔥 WRITE-THROUGH CACHE
        try:
            safe_set(
                f"psl:latest:{user_id}",
                json.dumps(data),
                ex=CACHE_TTL + random.randint(0, 60)
            )
            safe_delete(f"user:snapshot:{user_id}")
        except Exception as e:
            logger.warning(f"[CACHE WRITE FAIL] {e}")

        return data


    async def get_latest_psl(self, db: AsyncSession, user_id: int):

        cache_key = f"psl:latest:{user_id}"

        # 🔥 CACHE FAST PATH
        try:
            cached = safe_get(cache_key)
            if cached:
                return json.loads(cached)
        except Exception as e:
            logger.warning(f"[CACHE READ FAIL] {e}")

        # 🔥 LEAN QUERY
        result = await db.execute(
            select(
                UserPSL.psl_score,
                UserPSL.tier,
                UserPSL.percentile,
                UserPSL.confidence
            )
            .where(UserPSL.user_id == user_id)
            .order_by(UserPSL.created_at.desc())
            .limit(1)
        )

        row = result.first()

        if not row:
            return None

        # 🔥 CLEAN unpack (no row[0] shit)
        psl_score, tier, percentile, confidence = row

        data = {
            "score": psl_score,
            "tier": tier,
            "percentile": percentile,
            "confidence": confidence,
        }

        # 🔥 CACHE WRITE + JITTER
        try:
            safe_set(
                cache_key,
                json.dumps(data),
                ex=CACHE_TTL + random.randint(0, 60)
            )
        except Exception as e:
            logger.warning(f"[CACHE WRITE FAIL] {e}")

        return data