from typing import Dict, List, Tuple
import math

# ============================================================
# CONFIG
# ============================================================

EPS = 1e-6
PHI = 1.618

# Defensive clamp for ratios (protect against bad poses / glitches)
RATIO_MIN = 0.2
RATIO_MAX = 4.0

# Weighting (importance of each proportion)
RATIO_WEIGHTS = {
    "face_length_to_width": 1.3,
    "eye_spacing_to_eye_width": 1.1,
    "nose_to_face": 1.0,
    "mouth_to_nose_width": 0.8,
    "lower_to_mid_face": 0.9,
}

Landmark = Tuple[float, float, float]  # (x,y,z) normalized MediaPipe


# ============================================================
# HELPERS
# ============================================================

def _clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))

def _ratio(a: float, b: float) -> float:
    r = a / (b + EPS)
    return _clamp(r, RATIO_MIN, RATIO_MAX)

def _phi_score(r: float) -> float:
    """
    Convert ratio deviation from PHI into 0–10 score.
    Lower deviation => higher score.
    """
    dev = abs(r - PHI)
    return max(0.0, 10.0 - dev * 20.0)


def _dist2(lm: List[Landmark], a: int, b: int) -> float:
    ax, ay, _ = lm[a]
    bx, by, _ = lm[b]
    return math.hypot(ax - bx, ay - by)


# ============================================================
# CORE
# ============================================================

def run_golden_ratio_analysis(
    *,
    landmarks: List[Landmark],
) -> Dict:
    """
    Golden Ratio (Phi) proportional analysis.
    Educational, neutral, store-safe.
    """

    if not landmarks or len(landmarks) < 400:
        return {
            "status": "error",
            "error": "NO_OR_INCOMPLETE_LANDMARKS",
            "message": "Face landmarks not detected clearly."
        }

    try:
        # ----------------------------------------------------
        # MEASUREMENTS (scale-free ratios)
        # ----------------------------------------------------

        face_height = _dist2(landmarks, 10, 152)
        face_width = _dist2(landmarks, 93, 323)

        eye_spacing = _dist2(landmarks, 133, 362)
        eye_width = _dist2(landmarks, 33, 133)

        nose_height = _dist2(landmarks, 1, 2)
        nose_width = _dist2(landmarks, 94, 331)

        mouth_width = _dist2(landmarks, 61, 291)

        mid_face = _dist2(landmarks, 1, 10)
        lower_face = _dist2(landmarks, 1, 152)

        ratios = {
            "face_length_to_width": _ratio(face_height, face_width),
            "eye_spacing_to_eye_width": _ratio(eye_spacing, eye_width),
            "nose_to_face": _ratio(nose_height, face_height),
            "mouth_to_nose_width": _ratio(mouth_width, nose_width),
            "lower_to_mid_face": _ratio(lower_face, mid_face),
        }

        # ----------------------------------------------------
        # WEIGHTED SCORE
        # ----------------------------------------------------

        weighted_sum = 0.0
        weight_total = 0.0

        for k, r in ratios.items():
            w = RATIO_WEIGHTS.get(k, 1.0)
            weighted_sum += _phi_score(r) * w
            weight_total += w

        overall_score = round(weighted_sum / (weight_total + EPS), 2)

        # ----------------------------------------------------
        # BANDS (neutral language)
        # ----------------------------------------------------

        if overall_score < 5.5:
            band = "lower_consistency"
            interpretation = "Facial proportions deviate from classical golden ratio ranges."
        elif overall_score < 6.8:
            band = "common_range"
            interpretation = "Several proportions fall within common golden ratio ranges."
        elif overall_score < 8.2:
            band = "balanced_consistency"
            interpretation = "Multiple proportions align well with golden ratio guidelines."
        else:
            band = "high_consistency"
            interpretation = "Proportions show unusually strong alignment with golden ratio relationships."

        # ----------------------------------------------------
        # OUTPUT
        # ----------------------------------------------------

        return {
            "status": "success",
            "golden_ratio_score": overall_score,
            "band": band,
            "ratios": {k: round(v, 3) for k, v in ratios.items()},
            "interpretation": interpretation,
            "notes": [
                "Golden ratio is a classical proportional guideline, not a strict rule.",
                "Accuracy decreases with head rotation and extreme facial expressions.",
                "Results may vary with pose, lighting, and image quality.",
            ],
            "disclaimer": (
                "Educational proportional analysis only. "
                "Not a judgment of appearance or personal value."
            ),
        }

    except Exception as e:
        return {
            "status": "error",
            "error": "GOLDEN_RATIO_ANALYSIS_FAILED",
            "message": str(e),
        }