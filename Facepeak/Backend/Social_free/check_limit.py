from fastapi import HTTPException
from Backend.Social_free.redis import redis_client
import time
import logging

logger = logging.getLogger(__name__)

WINDOW = 60


async def check_limit(
    key: str,
    limit: int,
    *,
    ip: str | None = None,
    error: str = "TOO_MANY_ATTEMPTS",
    use_penalty: bool = False,
):
    try:
        now = int(time.time())

        # =========================
        # 🔥 GLOBAL PENALTY
        # =========================
        if ip:
            global_penalty = await redis_client.get(f"penalty:global:{ip}")
            if global_penalty and int(global_penalty) > now:
                raise HTTPException(429, error)

        # =========================
        # 🔥 LOCAL PENALTY
        # =========================
        if use_penalty:
            penalty_key = f"penalty:{key}"
            penalty_until = await redis_client.get(penalty_key)

            if penalty_until and int(penalty_until) > now:
                raise HTTPException(429, error)

        # =========================
        # 🔥 ATOMIC COUNT
        # =========================
        count = await redis_client.incr(key)

        # 🔥 TTL samo prvi put
        if count == 1:
            await redis_client.expire(key, WINDOW)

        # =========================
        # 🔥 LIMIT BREACH
        # =========================
        if count > limit:
            if use_penalty:
                overflow = count - limit
                penalty_seconds = min(45, 2 ** max(0, overflow - 1))

                await redis_client.set(
                    f"penalty:{key}",
                    now + penalty_seconds,
                    ex=penalty_seconds
                )

            raise HTTPException(429, error)

    except HTTPException:
        raise

    except Exception as e:
        logger.warning(f"[RATE LIMIT ERROR] {e}")
        return  # 🔥 fail-safe