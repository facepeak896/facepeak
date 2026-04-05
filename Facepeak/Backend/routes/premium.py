from fastapi import APIRouter, HTTPException
from typing import Dict, Any

from Backend.services.premium_service import (
    can_run_psl,
    can_run_appeal,
    require_feature,
    get_usage_context,
)

router = APIRouter(prefix="/premium", tags=["premium"])


# ============================================================
# ⚠️ DEV-ONLY USER STORE (V2.5)
# In V3 replace with DB repository (routes stay the same)
# ============================================================

from Backend.routes.users import _USERS  # OK for V2.5 / single instance


def _get_user_or_404(user_id: str) -> Dict[str, Any]:
    user = _USERS.get(user_id)
    if not user:
        raise HTTPException(404, "USER_NOT_FOUND")
    return user


# ============================================================
# PREMIUM / USAGE CONTEXT (frontend gold)
# ============================================================

@router.get("/context/{user_id}")
async def premium_context(user_id: str) -> Dict[str, Any]:
    user = _get_user_or_404(user_id)

    return {
        "status": "success",
        "premium": get_usage_context(user),
    }


# ============================================================
# PSL CHECK (NO REGISTRATION HERE)
# Actual register_psl() is called in analysis route
# ============================================================

@router.post("/{user_id}/psl/check")
async def check_psl(user_id: str) -> Dict[str, Any]:
    user = _get_user_or_404(user_id)

    return {
        "status": "success",
        "allowed": can_run_psl(user),
        "usage": get_usage_context(user),
    }


# ============================================================
# APPEAL CHECK (NO REGISTRATION HERE)
# Actual register_appeal() is called in analysis route
# ============================================================

@router.post("/{user_id}/appeal/check")
async def check_appeal(user_id: str) -> Dict[str, Any]:
    user = _get_user_or_404(user_id)

    return {
        "status": "success",
        "allowed": can_run_appeal(user),
        "usage": get_usage_context(user),
    }


# ============================================================
# FEATURE GATES (AI chat, looksmatch, etc.)
# ============================================================

@router.post("/{user_id}/feature/{feature}")
async def check_feature(user_id: str, feature: str) -> Dict[str, Any]:
    user = _get_user_or_404(user_id)

    try:
        require_feature(user, feature)
        enabled = True
    except PermissionError:
        enabled = False

    return {
        "status": "success",
        "feature": feature,
        "enabled": enabled,
    }