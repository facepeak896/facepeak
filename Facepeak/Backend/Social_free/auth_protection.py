from fastapi import HTTPException, Request
from Backend.Social_free.redis import redis_client
import time
import logging

logger = logging.getLogger(__name__)

WINDOW = 60
GLOBAL_LIMIT = 350


def check_limit(
    key: str,
    limit: int,
    error: str = "TOO_MANY_ATTEMPTS",
    use_penalty: bool = False,
    ip: str | None = None,   # 🔥 NOVO
):
    try:
        now = int(time.time())

        # =========================
        # 🔥 GLOBAL PENALTY (CLEAN)
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
        # 🔥 COUNT
        # =========================
        count = redis_client.incr(key)

        if count == 1:
            redis_client.expire(key, WINDOW)

        # =========================
        # 🔥 LIMIT HIT
        # =========================
        if count > limit:

            if use_penalty:
                penalty_seconds = min(45, 2 ** (count - limit - 1))

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
        return  # user-first fallback


# =========================
# GLOBAL
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
        ip=ip,  # 🔥 FIX
    )


# =========================
# LOGIN
# =========================

def protect_login(request: Request, email: str):

    global_limit(request)

    ip = request.client.host
    email = email.lower().strip()
    now = int(time.time()) // WINDOW

    check_limit(
        key=f"login:ip:{ip}:{now}",
        limit=15,
        error="TOO_MANY_ATTEMPTS",
        use_penalty=True,
        ip=ip,  # 🔥 FIX
    )

    check_limit(
        key=f"login:email:{email}:{now}",
        limit=7,
        error="TOO_MANY_ATTEMPTS",
        use_penalty=True,
        ip=ip,  # 🔥 FIX
    )


# =========================
# SIGNUP
# =========================

def protect_signup(request: Request, email: str):

    global_limit(request)

    ip = request.client.host
    email = email.lower().strip()
    now = int(time.time()) // WINDOW

    check_limit(
        key=f"signup:ip:{ip}:{now}",
        limit=7,
        error="TOO_MANY_ATTEMPTS",
        use_penalty=True,
        ip=ip,  # 🔥 FIX
    )

    check_limit(
        key=f"signup:email:{email}:{now}",
        limit=4,
        error="TOO_MANY_ATTEMPTS",
        use_penalty=True,
        ip=ip,  # 🔥 FIX
    )