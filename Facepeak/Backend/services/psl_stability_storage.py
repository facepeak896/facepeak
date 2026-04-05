import json
import time
from typing import Optional, Dict, Any

from Backend.services.redis_client import get_redis

# =====================================================
# CONFIG
# =====================================================

REDIS_PREFIX = "psl:stability:"
TTL_SECONDS = 60 * 60 * 24 * 7  # 7 dana (idealno za monetizaciju)

# =====================================================
# INTERNAL KEY BUILDER
# =====================================================

def _key(guest_token: str) -> str:
    return f"{REDIS_PREFIX}{guest_token}"


# =====================================================
# GET STABILITY STATE
# =====================================================

def get_stability_state(guest_token: Optional[str]) -> Optional[Dict[str, Any]]:
    if not guest_token:
        return None

    try:
        redis = get_redis()
        raw = redis.get(_key(guest_token))
        if not raw:
            return None

        return json.loads(raw)

    except Exception:
        # Nikad ne rušimo PSL ako Redis faila
        return None


# =====================================================
# GET PREVIOUS SCORE (SAFE WRAPPER)
# =====================================================

def get_previous_score(guest_token: Optional[str]) -> Optional[int]:
    state = get_stability_state(guest_token)
    if not state:
        return None

    return state.get("previous_score")


# =====================================================
# SAVE STABILITY STATE
# =====================================================

def save_stability_state(
    guest_token: Optional[str],
    score: int,
    confidence: float,
):
    if not guest_token:
        return

    try:
        redis = get_redis()

        payload = {
            "previous_score": int(score),
            "confidence": float(confidence),
            "updated_at": int(time.time()),
        }

        redis.setex(
            _key(guest_token),
            TTL_SECONDS,
            json.dumps(payload),
        )

    except Exception:
        # Ne želimo crash ako Redis pukne
        pass