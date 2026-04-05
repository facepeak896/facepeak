from fastapi import APIRouter
from typing import Dict, Any
import uuid
import time

router = APIRouter(prefix="/users", tags=["users"])

# ============================================================
# CONFIG
# ============================================================

_DEV_ONLY = True  # ⚠️ DEV ONLY — disable in production

_USERS: Dict[str, Dict[str, Any]] = {}


def _now() -> int:
    return int(time.time())


# ============================================================
# CREATE USER
# ============================================================

@router.post("/create")
async def create_user() -> Dict[str, Any]:
    """
    Creates an anonymous user.
    Frontend stores user_id locally.
    """

    user_id = uuid.uuid4().hex

    user = {
        "user_id": user_id,

        # identity
        "username": None,
        "age_confirmed": False,

        # monetization
        "is_premium": False,

        # UI / UX preferences
        "preferences": {
            "dark_mode": True,
            "show_confidence_scores": True,
            "show_potential": True,
            "language": "en",
        },

        # feature flags
        "features": {
            "looksmatch_enabled": False,
            "ai_chat_enabled": True,
            "advanced_analytics": False,
        },

        # meta
        "created_at": _now(),
        "last_active": _now(),

        # social (V3)
        "friends": [],
        "blocked_users": [],
    }

    _USERS[user_id] = user

    return {
        "status": "success",
        "user": user,
    }


# ============================================================
# GET USER
# ============================================================

@router.get("/{user_id}")
async def get_user(user_id: str) -> Dict[str, Any]:
    user = _USERS.get(user_id)
    if not user:
        return {
            "status": "error",
            "error": "USER_NOT_FOUND",
        }

    user["last_active"] = _now()

    return {
        "status": "success",
        "user": user,
    }


# ============================================================
# UPDATE USER (SAFE FIELDS ONLY)
# ============================================================

@router.post("/{user_id}/update")
async def update_user(
    user_id: str,
    data: Dict[str, Any],
) -> Dict[str, Any]:

    user = _USERS.get(user_id)
    if not user:
        return {
            "status": "error",
            "error": "USER_NOT_FOUND",
        }

    # -------- IDENTITY --------
    if "username" in data:
        user["username"] = str(data["username"])[:24]

    if "age_confirmed" in data:
        user["age_confirmed"] = bool(data["age_confirmed"])

    # -------- PREFERENCES --------
    prefs = data.get("preferences")
    if isinstance(prefs, dict):
        for k in user["preferences"]:
            if k in prefs:
                user["preferences"][k] = prefs[k]

    # -------- FEATURES (SAFE FLAGS ONLY) --------
    feats = data.get("features")
    if isinstance(feats, dict):
        for k in user["features"]:
            if k in feats:
                user["features"][k] = bool(feats[k])

    user["last_active"] = _now()

    return {
        "status": "success",
        "user": user,
    }


# ============================================================
# PREMIUM TOGGLE (DEV ONLY)
# ============================================================

@router.post("/{user_id}/set-premium")
async def set_premium(
    user_id: str,
    enabled: bool = True,
) -> Dict[str, Any]:
    """
    ⚠️ DEV ONLY
    In production this MUST be replaced with
    Stripe / Google Play server-side verification.
    """

    if not _DEV_ONLY:
        return {
            "status": "error",
            "error": "NOT_ALLOWED",
        }

    user = _USERS.get(user_id)
    if not user:
        return {
            "status": "error",
            "error": "USER_NOT_FOUND",
        }

    user["is_premium"] = enabled

    if enabled:
        user["features"]["looksmatch_enabled"] = True
        user["features"]["advanced_analytics"] = True

    return {
        "status": "success",
        "is_premium": user["is_premium"],
        "features": user["features"],
    }


# ============================================================
# LIGHTWEIGHT CONTEXT (FOR AI ROUTES)
# ============================================================

@router.get("/{user_id}/context")
async def get_user_context(user_id: str) -> Dict[str, Any]:
    """
    Small, fast payload for AI routes & chatbot.
    """

    user = _USERS.get(user_id)
    if not user:
        return {
            "status": "error",
            "error": "USER_NOT_FOUND",
        }

    return {
        "status": "success",
        "context": {
            "user_id": user["user_id"],
            "is_premium": user["is_premium"],
            "features": user["features"],
            "preferences": user["preferences"],
        },
    }