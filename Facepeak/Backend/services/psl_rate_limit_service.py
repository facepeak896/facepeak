from datetime import datetime
from Backend.services.redis_client import redis_client

# =====================================================
# CONFIG
# =====================================================

WELCOME_SPAM_COOLDOWN_SEC = 15

FREE_BASE_PSL = 2
FREE_AD_PSL = 2
PREMIUM_PSL = 25


# =====================================================
# KEY HELPERS
# =====================================================

def _today() -> str:
    return datetime.utcnow().strftime("%Y-%m-%d")


def _welcome_done_key(guest_key: str) -> str:
    return f"psl:welcome:done:{guest_key}"


def _welcome_cd_key(guest_key: str) -> str:
    return f"psl:welcome:cd:{guest_key}"


def _home_daily_key(user_id: str) -> str:
    return f"psl:home:daily:{user_id}:{_today()}"


# =====================================================
# SERVICE
# =====================================================

class PSLRateLimitService:
    """
    Rate limit + access gate for PSL.

    RULES:
    - Guest (welcome): exactly 1 PSL ever (per guest token)
    - Logged user (home): daily limits
    - Context is DERIVED from user, never from frontend
    """

    # =========================
    # CHECK
    # =========================
    def can_run(
        self,
        *,
        guest_key: str | None,
        user: dict | None,
        rewarded: bool,
    ) -> tuple[bool, str | None]:

        # ---------- WELCOME (GUEST) ----------
        if user is None:
            if not guest_key:
                return False, "GUEST_TOKEN_REQUIRED"

            if redis_client.exists(_welcome_done_key(guest_key)):
                return False, "WELCOME_ALREADY_DONE"

            if redis_client.exists(_welcome_cd_key(guest_key)):
                return False, "WELCOME_COOLDOWN"

            return True, None

        # ---------- HOME (LOGGED USER) ----------
        user_id = str(user["id"])
        used = int(redis_client.get(_home_daily_key(user_id)) or 0)

        if user.get("is_premium"):
            if used >= PREMIUM_PSL:
                return False, "PREMIUM_LIMIT"
            return True, None

        limit = FREE_BASE_PSL + (FREE_AD_PSL if rewarded else 0)
        if used >= limit:
            return False, "FREE_LIMIT"

        return True, None

    # =========================
    # SUCCESS
    # =========================
    def register_success(
        self,
        *,
        guest_key: str | None,
        user: dict | None,
    ) -> None:

        # ---------- WELCOME ----------
        if user is None:
            redis_client.set(_welcome_done_key(guest_key), 1)
            redis_client.delete(_welcome_cd_key(guest_key))
            return

        # ---------- HOME ----------
        user_id = str(user["id"])
        daily_key = _home_daily_key(user_id)

        pipe = redis_client.pipeline()
        pipe.incr(daily_key, 1)
        pipe.expire(daily_key, 26 * 3600)
        pipe.execute()

    # =========================
    # FAILURE (ANTI-SPAM)
    # =========================
    def register_failure(
        self,
        *,
        guest_key: str | None,
        user: dict | None,
    ) -> None:
        # Anti-spam applies ONLY to welcome
        if user is None and guest_key:
            redis_client.setex(
                _welcome_cd_key(guest_key),
                WELCOME_SPAM_COOLDOWN_SEC,
                1,
            )