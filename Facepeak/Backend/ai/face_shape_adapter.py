from typing import Dict, List, Tuple
import math

Landmark = Tuple[float, float, float]


def _dist2(lm: List[Landmark], a: int, b: int) -> float:
    ax, ay, _ = lm[a]
    bx, by, _ = lm[b]
    return math.hypot(ax - bx, ay - by)


def _clamp01(x: float) -> float:
    return max(0.0, min(1.0, x))


def run_face_shape_analysis_from_landmarks(
    landmarks: List[Landmark],
) -> Dict:
    """
    Face Shape Analysis V2 (landmark-based).
    Deterministic, scale-free, store-safe.
    """

    if not landmarks or len(landmarks) < 400:
        return {
            "status": "error",
            "error": "NO_OR_INCOMPLETE_LANDMARKS",
            "message": "Face landmarks not detected clearly.",
        }

    try:
        forehead = 10
        chin = 152
        jaw_l = 172
        jaw_r = 397
        temple_l = 234
        temple_r = 454

        face_length = _dist2(landmarks, forehead, chin)
        face_width = _dist2(landmarks, temple_l, temple_r)
        jaw_width = _dist2(landmarks, jaw_l, jaw_r)

        length_ratio = face_length / (face_width + 1e-6)
        jaw_ratio = jaw_width / (face_width + 1e-6)

        # -------- SHAPE HEURISTICS --------
        if length_ratio > 1.25 and jaw_ratio < 0.85:
            dominant = "Rectangle"
        elif jaw_ratio > 0.95:
            dominant = "Square"
        elif length_ratio < 1.10:
            dominant = "Round"
        elif jaw_ratio < 0.80 and length_ratio > 1.20:
            dominant = "Heart"
        else:
            dominant = "Oval"

        # -------- HARMONY SCORE --------
        lr_score = _clamp01(1.0 - abs(length_ratio - 1.30) / 0.5)
        jr_score = _clamp01(1.0 - abs(jaw_ratio - 0.90) / 0.3)

        harmony_score = round((lr_score * 0.6 + jr_score * 0.4) * 10.0, 2)

        if harmony_score < 6.8:
            harmony_level = "Balanced"
        elif harmony_score < 7.8:
            harmony_level = "Advanced"
        else:
            harmony_level = "Elite"

        return {
            "status": "success",
            "dominant_shape": dominant,
            "harmony_score": harmony_score,
            "harmony_level": harmony_level,
            "ratios": {
                "length_to_width": round(length_ratio, 3),
                "jaw_to_width": round(jaw_ratio, 3),
            },
            "notes": [
                "Face shape reflects dominant geometric tendencies.",
                "Most individuals exhibit blended characteristics.",
                "Results depend on capture angle and expression.",
            ],
            "disclaimer": (
                "Educational face shape analysis only. "
                "Not a judgment of appearance or personal value."
            ),
        }

    except Exception as e:
        return {
            "status": "error",
            "error": "FACE_SHAPE_ANALYSIS_FAILED",
            "message": str(e),
        }