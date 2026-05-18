# Backend/services/free_psl_cooldown_service.py

from datetime import datetime, timezone, timedelta
from fastapi import HTTPException, Request

from Backend.Social_free.redis import safe_get, safe_set

import hashlib


FREE_PSL_LIMIT = 1
FREE_PSL_COOLDOWN_SECONDS = 24 * 60 * 60

# -------------------------
# LOGGED USER BURST GUARD
# -------------------------

USER_REQUEST_LIMIT = 8
USER_WINDOW_SECONDS = 10 * 60

# -------------------------
# GUEST/IP GUARDS
# -------------------------

GUEST_IP_LIMIT = 25
GUEST_IP_WINDOW_SECONDS = 60 * 60

GUEST_TOKEN_LIMIT = 5
GUEST_TOKEN_WINDOW_SECONDS = 10 * 60


def _hash(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


class FreePslCooldownService:
    @staticmethod
    def build_user_key(
        user=None,
        guest_token: str | None = None,
    ) -> str:
        # 🔥 PRIMARY: authenticated user
        if user is not None:
            return f"user:{user.id}"

        # fallback guest
        if guest_token:
            return f"guest:{_hash(guest_token)}"

        raise HTTPException(
            status_code=401,
            detail="MISSING_USER_OR_GUEST_TOKEN",
        )

    @staticmethod
    def cooldown_key(user_key: str) -> str:
        return f"psl:free:cooldown:{user_key}"

    @staticmethod
    def guest_token_guard_key(user_key: str) -> str:
        return f"psl:free:guard:token:{user_key}"

    @staticmethod
    def user_guard_key(user_key: str) -> str:
        return f"psl:free:guard:user:{user_key}"

    @staticmethod
    def ip_guard_key(ip: str) -> str:
        return f"psl:free:guard:ip:{_hash(ip)}"

    @staticmethod
    def client_ip(request: Request | None) -> str | None:
        if request is None:
            return None

        forwarded = request.headers.get("x-forwarded-for")

        if forwarded:
            return forwarded.split(",")[0].strip()

        real_ip = request.headers.get("x-real-ip")

        if real_ip:
            return real_ip.strip()

        if request.client:
            return request.client.host

        return None

    @staticmethod
    async def _increment_counter(
        key: str,
        window_seconds: int,
    ) -> int:
        raw = await safe_get(key)

        try:
            count = int(raw) if raw else 0
        except Exception:
            count = 0

        count += 1

        await safe_set(
            key,
            str(count),
            ex=window_seconds,
        )

        return count

    @staticmethod
    async def check_or_rate_limit(
        user_key: str,
        request: Request | None = None,
    ) -> dict | None:

        # -------------------------
        # COOLDOWN CHECK
        # -------------------------

        cooldown_until = await safe_get(
            FreePslCooldownService.cooldown_key(user_key)
        )

        if cooldown_until:
            return {
                "status": "rate_limited",
                "locked": True,
                "cooldown_until": cooldown_until,
                "free_attempts_used": FREE_PSL_LIMIT,
                "free_attempts_limit": FREE_PSL_LIMIT,
            }

        # -------------------------
        # USER BURST GUARD
        # protects backend spam
        # -------------------------

        user_count = await FreePslCooldownService._increment_counter(
            key=FreePslCooldownService.user_guard_key(user_key),
            window_seconds=USER_WINDOW_SECONDS,
        )

        if user_count > USER_REQUEST_LIMIT:
            raise HTTPException(
                status_code=429,
                detail="TOO_MANY_REQUESTS",
            )

        # -------------------------
        # GUEST EXTRA GUARDS
        # -------------------------

        if user_key.startswith("guest:"):

            token_count = await FreePslCooldownService._increment_counter(
                key=FreePslCooldownService.guest_token_guard_key(
                    user_key,
                ),
                window_seconds=GUEST_TOKEN_WINDOW_SECONDS,
            )

            if token_count > GUEST_TOKEN_LIMIT:
                raise HTTPException(
                    status_code=429,
                    detail="TOO_MANY_GUEST_ATTEMPTS",
                )

            ip = FreePslCooldownService.client_ip(request)

            if ip:
                ip_count = await FreePslCooldownService._increment_counter(
                    key=FreePslCooldownService.ip_guard_key(ip),
                    window_seconds=GUEST_IP_WINDOW_SECONDS,
                )

                if ip_count > GUEST_IP_LIMIT:
                    raise HTTPException(
                        status_code=429,
                        detail="TOO_MANY_REQUESTS_FROM_NETWORK",
                    )

        return None

    @staticmethod
    async def lock_after_success(
        user_key: str,
    ) -> dict:

        now = datetime.now(timezone.utc)

        cooldown_until = now + timedelta(
            seconds=FREE_PSL_COOLDOWN_SECONDS,
        )

        await safe_set(
            FreePslCooldownService.cooldown_key(user_key),
            cooldown_until.isoformat(),
            ex=FREE_PSL_COOLDOWN_SECONDS,
        )

        return {
            "locked": True,
            "cooldown_until": cooldown_until.isoformat(),
            "free_attempts_used": FREE_PSL_LIMIT,
            "free_attempts_limit": FREE_PSL_LIMIT,
        }