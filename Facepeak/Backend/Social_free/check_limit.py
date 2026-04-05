from fastapi import HTTPException
from Backend.Social_free.redis import redis_client
import time
import logging

logger = logging.getLogger(__name__)

WINDOW = 60


def check_limit(
    key: str,
    limit: int,
    *,
    ip: str | None = None,
    error: str = "TOO_MANY_ATTEMPTS",
    use_penalty: bool = False,
):
    """
    Enterprise rate limiter with:
    - atomic Redis INCR
    - TTL window
    - exponential penalty
    - global IP penalty support
    - safe fallback (user-first)
    """

    try:
        now = int(time.time())

        # =========================
        # 🔥 GLOBAL PENALTY (shared intelligence)
        # =========================

        if ip:
            global_penalty = redis_client.get(f"penalty:global:{ip}")
            if global_penalty and int(global_penalty) > now:
                raise HTTPException(429, error)

        # =========================
        # 🔥 LOCAL PENALTY
        # =========================

        if use_penalty:
            penalty_key = f"penalty:{key}"
            penalty_until = redis_client.get(penalty_key)

            if penalty_until and int(penalty_until) > now:
                raise HTTPException(429, error)

        # =========================
        # 🔥 ATOMIC COUNT
        # =========================

        count = redis_client.incr(key)

        # 🔥 set TTL only once
        if count == 1:
            redis_client.expire(key, WINDOW)

        # =========================
        # 🔥 LIMIT BREACH
        # =========================

        if count > limit:

            if use_penalty:
                # 🔥 exponential backoff (safe)
                overflow = count - limit
                penalty_seconds = min(45, 2 ** max(0, overflow - 1))

                redis_client.set(
                    f"penalty:{key}",
                    now + penalty_seconds,
                    ex=penalty_seconds
                )

            raise HTTPException(429, error)

    except HTTPException:
        raise

    except Exception as e:
        # 🔥 NEVER break user flow
        logger.warning(f"[RATE LIMIT ERROR] {e}")
        return