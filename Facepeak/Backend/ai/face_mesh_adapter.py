# face_mesh_adapter_v3.py
# ==================================================
# Face Mesh Adapter v3
# - 6 perceptual signals
# - NO scoring
# - NO averaging
# - NO compression
# - UI / explanation layer only
# ==================================================

from typing import Dict, Optional, Any
import logging

logger = logging.getLogger(__name__)

# ==================================================
# CONFIG
# ==================================================

SIGNALS = [
    "bone",
    "face_shape",
    "appeal",
    "symmetry",
    "skin",
    "hair",
]

MIN_PRESENT_SIGNALS = 3

# ==================================================
# EXPLANATIONS (UI SAFE)
# ==================================================

SIGNAL_INFO: Dict[str, Dict[str, Any]] = {
    "bone": {
        "title": "Bone structure",
        "desc": [
            "Reflects the underlying skeletal support of the face.",
            "Stronger bone structure usually provides clearer definition and stability.",
            "This signal changes slowly over time and is mostly genetic."
        ],
    },
    "face_shape": {
        "title": "Face shape balance",
        "desc": [
            "Measures how balanced the overall face shape appears.",
            "Extreme elongation or compression reduces structural harmony.",
            "Balanced shapes tend to appear more stable across angles."
        ],
    },
    "appeal": {
        "title": "Visual appeal",
        "desc": [
            "Captures how visually engaging the face appears as a whole.",
            "This includes eye area presence and proportional flow.",
            "Appeal is perceptual and not tied to any single feature."
        ],
    },
    "symmetry": {
        "title": "Facial symmetry",
        "desc": [
            "Represents how evenly features align between left and right sides.",
            "Perfect symmetry is rare; small asymmetries are normal.",
            "Higher symmetry usually improves visual clarity."
        ],
    },
    "skin": {
        "title": "Skin quality",
        "desc": [
            "Estimates surface clarity and texture consistency.",
            "Lighting conditions can influence this signal.",
            "This is one of the most changeable factors over time."
        ],
    },
    "hair": {
        "title": "Hair presentation",
        "desc": [
            "Evaluates how well hair frames and supports the face.",
            "Density, contrast, and framing all contribute.",
            "This signal can change significantly with styling."
        ],
    },
}

# ==================================================
# HELPERS
# ==================================================

def _clamp01(x: float) -> float:
    return max(0.0, min(1.0, x))


def _normalize_0_10(v: float) -> float:
    """
    Defensive normalization.
    Input is expected to be 0–10.
    """
    return round(_clamp01(v / 10.0) * 10.0, 2)


# ==================================================
# MAIN ADAPTER
# ==================================================

def run_face_mesh_adapter(
    signals: Dict[str, Optional[float]]
) -> Dict[str, Any]:
    """
    Adapter for perceptual face signals.

    INPUT:
        signals: {
            bone: 0–10,
            face_shape: 0–10,
            appeal: 0–10,
            symmetry: 0–10,
            skin: 0–10,
            hair: 0–10
        }

    OUTPUT:
        - validated signals
        - per-signal explanations
        - presence + confidence (NOT attractiveness)
    """

    # ----------------------------------------------
    # FILTER PRESENT SIGNALS
    # ----------------------------------------------
    present = {
        k: v for k, v in signals.items()
        if k in SIGNALS and isinstance(v, (int, float))
    }

    if len(present) < MIN_PRESENT_SIGNALS:
        logger.info(
            "[face_mesh_adapter_v3] INVALID: insufficient signals "
            f"({len(present)}/{len(SIGNALS)})"
        )
        return {
            "status": "invalid",
            "reason": "INSUFFICIENT_SIGNALS",
            "message": "Not enough visual signals detected.",
        }

    # ----------------------------------------------
    # NORMALIZE (DEFENSIVE)
    # ----------------------------------------------
    norm = {
        k: _normalize_0_10(float(v))
        for k, v in present.items()
    }

    # ----------------------------------------------
    # CONFIDENCE (STABILITY, NOT BEAUTY)
    # ----------------------------------------------
    # Higher spread = lower capture stability
    mean = sum(norm.values()) / len(norm)
    variance = sum((v - mean) ** 2 for v in norm.values()) / len(norm)
    stability = _clamp01(1.0 - (variance / 18.0))

    confidence = round(0.55 + 0.45 * stability, 2)

    # ----------------------------------------------
    # BUILD UI BLOCK
    # ----------------------------------------------
    signal_blocks = {
        k: {
            "value": norm[k],
            "title": SIGNAL_INFO[k]["title"],
            "description": SIGNAL_INFO[k]["desc"],
        }
        for k in norm
    }

    return {
        "status": "success",
        "signals": signal_blocks,
        "confidence": confidence,
        "notes": [
            "This module explains visual signals only.",
            "It does not calculate a score.",
            "Results depend on image quality and capture conditions.",
        ],
        "disclaimer": (
            "This analysis describes visual and structural signals from a single image. "
            "It is not a judgment of personal value or worth."
        ),
    }