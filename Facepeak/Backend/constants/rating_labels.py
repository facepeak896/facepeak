"""
Rating / Presentation Labels (Store-safe)

Purpose:
- Human-readable descriptions for score ranges
- Used by frontend (tooltips, result cards, progress views)
- NO scoring logic
- NO comparison language
- NO judgment language
"""

from typing import List, Dict, TypedDict


class RatingLabel(TypedDict):
    key: str
    label: str
    description: str


# ============================================================
# GENERIC PRESENTATION LABELS
# (usable across PSL, Skin, Symmetry, Appeal, Hair, etc.)
# ============================================================

RATING_LABELS: List[RatingLabel] = [
    {
        "key": "developing",
        "label": "Developing consistency",
        "description": (
            "Results in this range often vary due to lighting, pose, or image quality. "
            "Retesting with another photo may provide a clearer picture."
        ),
    },
    {
        "key": "common",
        "label": "Within common range",
        "description": (
            "Measurements fall within commonly observed ranges for this type of analysis. "
            "Minor variation between photos is normal."
        ),
    },
    {
        "key": "balanced",
        "label": "Balanced presentation",
        "description": (
            "Several measured elements appear balanced and consistent in this capture. "
            "Results may still vary with different lighting or angles."
        ),
    },
    {
        "key": "refined",
        "label": "Refined consistency",
        "description": (
            "Multiple elements appear consistently aligned in this capture. "
            "This reflects stable presentation under the given conditions."
        ),
    },
    {
        "key": "exceptional",
        "label": "Exceptionally consistent",
        "description": (
            "Measurements appear unusually consistent in this capture. "
            "Confirming across multiple photos is recommended."
        ),
    },
]


# ============================================================
# FALLBACK
# ============================================================

DEFAULT_RATING_LABEL: RatingLabel = {
    "key": "neutral",
    "label": "Neutral result",
    "description": (
        "This result reflects a neutral measurement outcome for the selected analysis."
    ),
}