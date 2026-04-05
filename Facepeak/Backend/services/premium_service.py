from typing import Dict
import time
import math
# ============================================================
# CONFIG
# ============================================================

TRIAL_DURATION_SECONDS = 3 * 24 * 60 * 60  # 3 days

FREE_LIMITS = {
    "psl_free_per_day": 1,
    "psl_rewarded_per_day": 2,
    "appeal_total": 1,          # LIFETIME (ne resetira se)
    "ai_chat": False,
    "looksmatch": False,
}

PREMIUM_LIMITS = {
    "psl_free_per_day": 999,
    "psl_rewarded_per_day": 999,
    "appeal_total": 999,
    "ai_chat": True,
    "looksmatch": True,
}

# ============================================================
# HELPERS
# ============================================================

def _today() -> str:
    return time.strftime("%Y-%m-%d")


def init_usage() -> Dict:
    return {
        "date": _today(),
        "psl_free_used": 0,
        "psl_rewarded_used": 0,
        "appeal_used": 0,   # lifetime counter
    }


def _reset_daily_if_needed(user: Dict):
    # ---------- DEFENSIVE INIT ----------
    if "usage" not in user or not isinstance(user["usage"], dict):
        user["usage"] = init_usage()
        return

    if user["usage"].get("date") != _today():
        user["usage"]["date"] = _today()
        user["usage"]["psl_free_used"] = 0
        user["usage"]["psl_rewarded_used"] = 0
        # ⚠️ appeal_used se NAMJERNO ne resetira


# ============================================================
# 🔥 TRIAL LOGIC
# ============================================================

def is_trial_active(user: Dict) -> bool:
    started = user.get("trial_started_at")
    if not started:
        return False
    return (time.time() - started) < TRIAL_DURATION_SECONDS


def maybe_start_trial(user: Dict):
    if user.get("trial_consumed"):
        return
    if user.get("trial_started_at") is not None:
        return
    user["trial_started_at"] = time.time()


def finalize_trial_if_needed(user: Dict):
    if user.get("trial_started_at") and not is_trial_active(user):
        user["trial_consumed"] = True
        user["trial_started_at"] = None  # 🔧 FIX: cleanup ghost state


def _limits(user: Dict) -> Dict:
    if user.get("is_premium"):
        return PREMIUM_LIMITS

    if is_trial_active(user):
        return PREMIUM_LIMITS  # 🔥 trial = premium

    return FREE_LIMITS


# ============================================================
# PSL
# ============================================================

def can_run_psl(user: Dict) -> bool:
    _reset_daily_if_needed(user)
    finalize_trial_if_needed(user)

    limits = _limits(user)

    if user["usage"]["psl_free_used"] < limits["psl_free_per_day"]:
        return True

    if user["usage"]["psl_rewarded_used"] < limits["psl_rewarded_per_day"]:
        return True

    return False


def register_psl(user: Dict, rewarded: bool = False):
    _reset_daily_if_needed(user)

    maybe_start_trial(user)      # 🔥 START TRIAL
    finalize_trial_if_needed(user)

    if rewarded:
        user["usage"]["psl_rewarded_used"] += 1
    else:
        user["usage"]["psl_free_used"] += 1


# ============================================================
# APPEAL (LIFETIME)
# ============================================================

def can_run_appeal(user: Dict) -> bool:
    _reset_daily_if_needed(user)
    finalize_trial_if_needed(user)

    limits = _limits(user)
    return user["usage"]["appeal_used"] < limits["appeal_total"]


def register_appeal(user: Dict):
    _reset_daily_if_needed(user)
    finalize_trial_if_needed(user)

    user["usage"]["appeal_used"] += 1


# ============================================================
# FEATURE GATES
# ============================================================

def require_feature(user: Dict, feature: str):
    """
    feature = "ai_chat" | "looksmatch"
    """
    finalize_trial_if_needed(user)

    limits = _limits(user)
    if not limits.get(feature, False):
        raise PermissionError("PREMIUM_REQUIRED")


# ============================================================
# FRONTEND CONTEXT (UX GOLD)
# ============================================================

def get_usage_context(user: Dict) -> Dict:
    _reset_daily_if_needed(user)
    finalize_trial_if_needed(user)

    limits = _limits(user)

    trial_active = is_trial_active(user)
    trial_seconds_left = max(
        0,
        TRIAL_DURATION_SECONDS - (time.time() - user.get("trial_started_at", 0))
    ) if trial_active else 0

    return {
        "is_premium": user.get("is_premium", False),
        "trial_active": trial_active,
        "trial_days_left": math.ceil(trial_seconds_left / 86400),
        "limits": limits,
        "usage": user["usage"],
        "remaining": {
            "psl_free": max(
                0, limits["psl_free_per_day"] - user["usage"]["psl_free_used"]
            ),
            "psl_rewarded": max(
                0, limits["psl_rewarded_per_day"] - user["usage"]["psl_rewarded_used"]
            ),
            "appeal": max(
                0, limits["appeal_total"] - user["usage"]["appeal_used"]
            ),
        },
    }