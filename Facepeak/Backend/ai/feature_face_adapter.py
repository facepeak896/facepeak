from typing import Dict, Any, List
import math


def run_feature_face_from_top10(top10: Dict[str, Any]) -> Dict[str, Any]:
    """
    Feature Face Adapter (V2.1 – Polished)

    - Presentation-only adapter
    - Uses Top10 output directly
    - Defensive against malformed data
    - Store-safe & AI-chatbot friendly
    """

    if not isinstance(top10, dict):
        return {
            "status": "error",
            "error": "INVALID_INPUT",
            "message": "Top10 result must be a dictionary."
        }

    top_features: List[Dict[str, Any]] = top10.get("top_features", [])
    weak_features: List[Dict[str, Any]] = top10.get("improvement_opportunities", [])

    if not top_features and not weak_features:
        return {
            "status": "error",
            "error": "NO_FEATURE_DATA",
            "message": "Top10 result does not contain feature data."
        }

    # UX-optimal: top 3 strongest + top 3 weakest
    strongest = top_features[:3]
    weakest = weak_features[:3]

    def _format(f: Dict[str, Any]) -> Dict[str, Any]:
        # --- defensive score parsing ---
        try:
            score = float(f.get("score", 0.0))
            if not math.isfinite(score):
                score = 0.0
        except Exception:
            score = 0.0

        return {
            "feature": f.get("feature"),
            "score": round(score, 2),
            "level": f.get("level", "Balanced"),
            "category": f.get("category", "presentation"),  # fallback-safe
        }

    strongest_fmt = [_format(f) for f in strongest]
    weakest_fmt = [_format(f) for f in weakest]

    interpretation = (
        "Certain facial features stand out as strong contributors, "
        "while others offer room for improvement."
        if strongest_fmt else
        "Facial features appear generally balanced in this capture."
    )

    return {
        "status": "success",
        "strongest_features": strongest_fmt,
        "areas_to_improve": weakest_fmt,
        "interpretation": interpretation,
        "notes": [
            "Feature highlights are derived from overall analysis results.",
            "Results reflect this specific capture and may vary across photos.",
        ],
        "disclaimer": (
            "Feature highlights are educational summaries only and "
            "are not judgments of appearance or personal value."
        ),
    }