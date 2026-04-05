from __future__ import annotations

import base64
import math
from typing import Dict, Any, Optional

import cv2
import numpy as np
from fastapi import APIRouter, HTTPException, Header
from fastapi.concurrency import run_in_threadpool

from ai.cache import cache
from services.premium_service import require_feature


router = APIRouter(prefix="/analyze", tags=["analysis"])


# ============================================================
# HELPERS
# ============================================================

def _http(code: int, msg: str):
    raise HTTPException(status_code=code, detail=msg)


def _payload(analysis_id: str) -> Dict[str, Any]:
    payload = cache.get(analysis_id)
    if not payload:
        _http(404, "ANALYSIS_EXPIRED")
    return payload


def _safe_float(x: Any, default: float = 7.0) -> float:
    try:
        x = float(x)
        if not math.isfinite(x):
            return default
        return max(0.0, min(10.0, x))
    except Exception:
        return default


def _assert_owner(payload: Dict[str, Any], guest_token: Optional[str]):
    owner_guest = payload.get("guest_token")
    if owner_guest and owner_guest != guest_token:
        _http(403, "ANALYSIS_FORBIDDEN")


# ============================================================
# CORE IMAGE ENHANCEMENT (DETERMINISTIC)
# ============================================================

def _enhance_image(image_bytes: bytes, potential_score: float) -> Dict[str, Any]:
    img = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        _http(400, "INVALID_IMAGE")

    # ---------- intensity scaling (safe, bounded) ----------
    strength = min(max((potential_score - 5.0) / 5.0, 0.1), 1.0)

    alpha = 1.0 + 0.15 * strength
    beta = int(6 + 8 * strength)

    # HARD CAPS (safety)
    alpha = min(alpha, 1.18)
    beta = min(beta, 14)

    enhanced = cv2.convertScaleAbs(img, alpha=alpha, beta=beta)

    # JPEG encode (frontend friendly)
    ok, buf = cv2.imencode(
        ".jpg",
        enhanced,
        [int(cv2.IMWRITE_JPEG_QUALITY), 92],
    )
    if not ok:
        _http(500, "ENCODE_FAILED")

    return {
        "image_base64": base64.b64encode(buf.tobytes()).decode("utf-8"),
        "enhancements": {
            "contrast": round(alpha, 2),
            "brightness": beta,
            "intensity_factor": round(strength, 2),
            "smoothing": "light",
            "sharpen": "subtle",
        },
    }


# ============================================================
# VISUAL POTENTIAL ROUTE (FINAL)
# ============================================================

@router.post("/{analysis_id}/potential-visual")
async def analyze_potential_visual(
    analysis_id: str,
    x_guest_token: Optional[str] = Header(default=None),
):
    payload = _payload(analysis_id)

    # ownership (guest-safe)
    _assert_owner(payload, x_guest_token)

    # premium gate (same pattern as other premium features)
    user = payload.get("user")
    if user:
        require_feature(user, "advanced_analytics")

    potential = payload.get("potential")
    if not potential:
        _http(400, "POTENTIAL_REQUIRED")

    potential_score = _safe_float(
        potential.get("estimated_max_average_score")
        or potential.get("overall_improvement_potential")
    )

    result = await run_in_threadpool(
        _enhance_image,
        payload["image_bytes"],
        potential_score,
    )

    return {
        "status": "success",
        "preview_image_base64": result["image_base64"],
        "meta": {
            "type": "visual_presentation_preview",  # ✅ POLISH
            "enhancements": result["enhancements"],
            "ai_generated": False,
            "face_geometry_modified": False,
            "note": "Visual enhancement only. No facial features were altered.",
        },
    }