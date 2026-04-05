from __future__ import annotations

import json
import time
import secrets
from typing import Dict, Any, Optional

from Backend.services.redis_client import get_redis

# ============================================================
# CONFIG
# ============================================================

ANALYSIS_PREFIX = "analysis:"
DEFAULT_TTL = 86400  # 24h


# ============================================================
# INTERNAL
# ============================================================

def _key(analysis_id: str) -> str:
    return f"{ANALYSIS_PREFIX}{analysis_id}"


# ============================================================
# CREATE ANALYSIS
# ============================================================

def create_analysis(initial_payload: Dict[str, Any], ttl_seconds: int = DEFAULT_TTL) -> str:
    redis = get_redis()

    analysis_id = secrets.token_hex(16)

    payload = {
        "created_at": time.time(),
        **initial_payload,
    }

    redis.setex(
        _key(analysis_id),
        ttl_seconds,
        json.dumps(payload),
    )

    return analysis_id


# ============================================================
# GET FULL PAYLOAD
# ============================================================

def get_analysis_payload(analysis_id: str) -> Optional[Dict[str, Any]]:
    redis = get_redis()

    raw = redis.get(_key(analysis_id))
    if not raw:
        return None

    return json.loads(raw)


# ============================================================
# GET SINGLE PART
# ============================================================

def get_analysis_part(analysis_id: str, key: str):
    payload = get_analysis_payload(analysis_id)
    if not payload:
        return None
    return payload.get(key)


# ============================================================
# SAVE PART
# ============================================================

def save_analysis_part(
    analysis_id: str,
    payload: Dict[str, Any],
    key: str,
    value: Any,
):
    redis = get_redis()

    payload[key] = value

    redis.set(
        _key(analysis_id),
        json.dumps(payload),
    )


# ============================================================
# REQUIRE PARTS (optional safety)
# ============================================================

def require_parts(payload: Dict[str, Any], keys: list[str]):
    for k in keys:
        if k not in payload:
            raise Exception(f"MISSING_PART: {k}")


# ============================================================
# OWNER CHECK (basic)
# ============================================================

def assert_owner(payload: Dict[str, Any], guest_token: Optional[str]):
    stored = payload.get("guest_token")
    if stored and stored != guest_token:
        raise Exception("INVALID_OWNER")


# ============================================================
# 🔥 PROTECT ANALYSIS REQUEST (OVO TI FALI)
# ============================================================

def protect_analysis_request(
    request,
    analysis_id: str,
    guest_token: Optional[str],
):
    """
    Minimal protection:
    - session exists
    - guest_token matches
    - anti-spam (basic)
    """

    payload = get_analysis_payload(analysis_id)

    if not payload:
        raise Exception("ANALYSIS_NOT_FOUND")

    stored_token = payload.get("guest_token")

    if stored_token and stored_token != guest_token:
        raise Exception("INVALID_GUEST_TOKEN")

    # simple spam protection (optional)
    now = time.time()
    last = payload.get("last_request_ts")

    if last and now - last < 0.5:
        raise Exception("TOO_FAST")

    payload["last_request_ts"] = now

    redis = get_redis()
    redis.set(_key(analysis_id), json.dumps(payload))

    return payload


# ============================================================
# CHAT (stub da ne puca import)
# ============================================================

def rate_limit_chat(*args, **kwargs):
    return True


def build_chat_context(*args, **kwargs):
    return {}