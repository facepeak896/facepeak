from fastapi import HTTPException, Request
from Backend.Social_free.redis import redis_client
import time
import logging

logger = logging.getLogger(__name__)

WINDOW = 60
GLOBAL_LIMIT = 350


# =========================
# CORE LIMITER
# =========================

def check_limit(
    key: str,
    limit: int,
    error: str = "TOO_MANY_ATTEMPTS",
    use_penalty: bool = False,
    ip: str | None = None,
):
    try:
        now = int(time.time())

        # 🔥 GLOBAL PENALTY
        if ip:
            global_penalty = redis_client.get(f"penalty:global:{ip}")
            if global_penalty and int(global_penalty) > now:
                raise HTTPException(429, error)

        # 🔥 LOCAL PENALTY
        if use_penalty:
            penalty_key = f"penalty:{key}"
            penalty_until = redis_client.get(penalty_key)

            if penalty_until and int(penalty_until) > now:
                raise HTTPException(429, error)

        # 🔥 COUNT
        count = redis_client.incr(key)

        if count == 1:
            redis_client.expire(key, WINDOW)

        # 🔥 LIMIT BREACH
        if count > limit:

            if use_penalty:
                penalty_seconds = min(45, 2 ** max(0, count - limit - 1))

                redis_client.set(
                    f"penalty:{key}",
                    now + penalty_seconds,
                    ex=penalty_seconds
                )

            raise HTTPException(429, error)

    except HTTPException:
        raise
    except Exception as e:
        logger.warning(f"[RATE LIMIT FAIL] {e}")
        return  # 🔥 fail-safe (user-first)


# =========================
# GLOBAL LIMIT
# =========================

def global_limit(request: Request):

    if hasattr(request.state, "rate_checked"):
        return

    request.state.rate_checked = True

    ip = request.client.host
    now = int(time.time()) // WINDOW

    check_limit(
        key=f"global:{ip}:{now}",
        limit=GLOBAL_LIMIT,
        error="TOO_MANY_REQUESTS",
        use_penalty=False,
        ip=ip,
    )


# =========================
# GOOGLE AUTH (🔥 CORE)
# =========================

def protect_google_auth(request: Request):

    global_limit(request)

    ip = request.client.host
    now = int(time.time()) // WINDOW

    check_limit(
        key=f"google_auth:ip:{ip}:{now}",
        limit=20,
        error="TOO_MANY_ATTEMPTS",
        use_penalty=True,
        ip=ip,
    )


# =========================
# ANALYSIS TRIGGER (🔥 CRITICAL)
# =========================

def protect_analysis(request: Request):

    global_limit(request)

    ip = request.client.host
    now = int(time.time()) // WINDOW

    check_limit(
        key=f"analysis:ip:{ip}:{now}",
        limit=10,
        error="TOO_MANY_ANALYSIS_REQUESTS",
        use_penalty=True,
        ip=ip,
    )