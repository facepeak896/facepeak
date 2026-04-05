# -- coding: utf-8 --
from __future__ import annotations

import time
import random
from dataclasses import dataclass
from typing import Dict, Any, List, Optional, Tuple


# ============================================================
# CONFIG (V2)
# ============================================================

LOOKSMATCH_TTL_SECONDS = 60 * 60 * 24  # 24h
MAX_SCORE_DELTA = 0.8
MIN_SCORE = 3.5

PREMIUM_ONLY = True          # keep true for app store safety
TEST_MODE = False            # deterministic matching for tests


# Abuse guards
ENABLE_COOLDOWN_SECONDS = 30          # prevent spam enable/disable loops
FIND_RATE_LIMIT = 20                  # per window
FIND_RATE_WINDOW_SECONDS = 60


# ============================================================
# IN-MEMORY STATE (V2 - single process)
# ============================================================

@dataclass
class PoolItem:
    user_id: str
    psl: float
    appeal: float
    score: float
    joined_at: float

_LOOKSMATCH_POOL: Dict[str, PoolItem] = {}
_MATCH_HISTORY: Dict[str, List[str]] = {}
_LAST_ENABLE_TS: Dict[str, float] = {}
_FIND_HITS: Dict[str, List[float]] = {}


# ============================================================
# HELPERS
# ============================================================

def _now() -> float:
    return time.time()

def _clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))

def _compatibility(a: float, b: float) -> float:
    diff = abs(a - b)
    return _clamp(1.0 - (diff / MAX_SCORE_DELTA), 0.0, 1.0)

def _cleanup_pool(now: Optional[float] = None) -> None:
    now = now or _now()
    expired = [
        uid for uid, u in _LOOKSMATCH_POOL.items()
        if now - u.joined_at > LOOKSMATCH_TTL_SECONDS
    ]
    for uid in expired:
        _LOOKSMATCH_POOL.pop(uid, None)
        _MATCH_HISTORY.pop(uid, None)
        _LAST_ENABLE_TS.pop(uid, None)
        _FIND_HITS.pop(uid, None)

def _rate_limit_find(user_id: str) -> None:
    now = _now()
    window_start = now - FIND_RATE_WINDOW_SECONDS
    hits = [t for t in _FIND_HITS.get(user_id, []) if t > window_start]
    if len(hits) >= FIND_RATE_LIMIT:
        raise ValueError("RATE_LIMITED")
    hits.append(now)
    _FIND_HITS[user_id] = hits

def _cooldown_enable(user_id: str) -> None:
    now = _now()
    last = _LAST_ENABLE_TS.get(user_id)
    if last and (now - last) < ENABLE_COOLDOWN_SECONDS:
        raise ValueError("ENABLE_COOLDOWN")
    _LAST_ENABLE_TS[user_id] = now


# ============================================================
# INPUT EXTRACTION (DO NOT TRUST CLIENT)
# ============================================================

def extract_scores_from_analysis(payload: Dict[str, Any]) -> Tuple[float, float]:
    """
    Extract scores from analysis payload. This is the critical security piece:
    - we trust server computed analysis, not client input.
    """
    psl = payload.get("psl") or {}
    appeal = payload.get("appeal") or {}

    psl_score = psl.get("psl_score")
    appeal_score = appeal.get("presentation_score")

    if psl_score is None or appeal_score is None:
        raise ValueError("PSL_AND_APPEAL_REQUIRED")

    try:
        psl_f = float(psl_score)
        app_f = float(appeal_score)
    except Exception:
        raise ValueError("INVALID_SCORES")

    return psl_f, app_f


# ============================================================
# API
# ============================================================

def enable_looksmatch(
    *,
    user_id: str,
    is_premium: bool,
    psl_score: float,
    appeal_score: float,
) -> Dict[str, Any]:
    """
    Adds user to pool for 24h (V2 in-memory).
    """
    _cleanup_pool()

    if PREMIUM_ONLY and not is_premium:
        return {"status": "error", "error": "PREMIUM_REQUIRED"}

    if psl_score < MIN_SCORE or appeal_score < MIN_SCORE:
        return {"status": "error", "error": "SCORE_TOO_LOW"}

    try:
        _cooldown_enable(user_id)
    except ValueError as e:
        return {"status": "error", "error": str(e)}

    combined = round(psl_score * 0.55 + appeal_score * 0.45, 2)

    _LOOKSMATCH_POOL[user_id] = PoolItem(
        user_id=user_id,
        psl=float(psl_score),
        appeal=float(appeal_score),
        score=float(combined),
        joined_at=_now(),
    )

    _MATCH_HISTORY.setdefault(user_id, [])

    return {
        "status": "success",
        "looksmatch_enabled": True,
        "score": combined,
        "expires_in_seconds": LOOKSMATCH_TTL_SECONDS,
        "disclaimer": (
            "Looksmatch compares analysis similarity only. "
            "It does not imply attraction, compatibility, or ranking."
        ),
    }


def disable_looksmatch(*, user_id: str) -> Dict[str, Any]:
    _LOOKSMATCH_POOL.pop(user_id, None)
    _MATCH_HISTORY.pop(user_id, None)
    _LAST_ENABLE_TS.pop(user_id, None)
    _FIND_HITS.pop(user_id, None)
    return {"status": "success", "looksmatch_enabled": False}


def find_looksmatch(*, user_id: str) -> Dict[str, Any]:
    _cleanup_pool()

    if user_id not in _LOOKSMATCH_POOL:
        return {"status": "error", "error": "LOOKSMATCH_NOT_ENABLED"}

    try:
        _rate_limit_find(user_id)
    except ValueError:
        return {"status": "error", "error": "RATE_LIMITED"}

    user = _LOOKSMATCH_POOL[user_id]
    already = set(_MATCH_HISTORY.get(user_id, []))

    candidates: List[PoolItem] = []
    for other_id, other in _LOOKSMATCH_POOL.items():
        if other_id == user_id:
            continue
        if other_id in already:
            continue
        if abs(user.score - other.score) <= MAX_SCORE_DELTA:
            candidates.append(other)

    if not candidates:
        return {"status": "success", "match_found": False}

    if TEST_MODE:
        random.seed(user_id)

    match = random.choice(candidates)
    comp = _compatibility(user.score, match.score)

    _MATCH_HISTORY.setdefault(user_id, []).append(match.user_id)
    _MATCH_HISTORY.setdefault(match.user_id, []).append(user_id)

    return {
        "status": "success",
        "match_found": True,
        "compatibility": round(comp, 2),
        "match": {
            "match_user_id": match.user_id,
            "psl_score": match.psl,
            "appeal_score": match.appeal,
            "overall_score": match.score,
        },
        "disclaimer": (
            "Looksmatch is based solely on analysis similarity. "
            "All interactions are optional."
        ),
    }


def stats() -> Dict[str, Any]:
    _cleanup_pool()
    return {
        "pool_size": len(_LOOKSMATCH_POOL),
        "history_size": sum(len(v) for v in _MATCH_HISTORY.values()),
    }