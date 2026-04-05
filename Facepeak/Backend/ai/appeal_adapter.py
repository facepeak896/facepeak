

from dataclasses import dataclass
from typing import Dict, Tuple, Literal, Optional
import math

# ============================================================
# GLOBAL CONFIG
# ============================================================

MIN_ALLOWED_AGE = 13
SCORE_MIN = 0.0
SCORE_MAX = 10.0

Status = Literal["success", "error"]

# ============================================================
# ERROR COPY (USER SAFE)
# ============================================================

ERROR_MESSAGES = {
    "AGE_GATE": "This feature is available for users 13+ only.",
    "CONSENT_MISSING": "Please confirm all checkboxes to continue.",
    "INVALID_IMAGE": "The image could not be processed. Please try another photo.",
    "IMAGE_TOO_DARK": "The image is too dark. Try better lighting.",
    "IMAGE_TOO_BLURRY": "The image is blurry. Hold the camera steady and try again.",
    "FACE_TOO_SMALL": "The face appears too far from the camera.",
    "PROCESSING_FAILED": "Unable to analyze this image. Please try again.",
}

# ============================================================
# HELPERS
# ============================================================

def _clamp(x: float, lo: float = SCORE_MIN, hi: float = SCORE_MAX) -> float:
    return max(lo, min(hi, x))

def _mean(values):
    return sum(values) / len(values) if values else 0.0

# ============================================================
# ACCESS GATE
# ============================================================

def validate_access(
    *,
    user_age: Optional[int],
    confirm_age: bool,
    confirm_educational: bool,
    confirm_variability: bool,
) -> Tuple[bool, str]:
    if not (confirm_age and confirm_educational and confirm_variability):
        return False, "CONSENT_MISSING"
    if user_age is None or user_age < MIN_ALLOWED_AGE:
        return False, "AGE_GATE"
    return True, "OK"

# ============================================================
# IMAGE QUALITY (CV-READY PROXY)
# ============================================================

@dataclass(frozen=True)
class ImageQuality:
    brightness: float   # 0–1
    sharpness: float    # 0–1
    face_ratio: float   # face area / image area

def quality_gate(q: ImageQuality) -> Tuple[bool, str]:
    if q.brightness < 0.25:
        return False, "IMAGE_TOO_DARK"
    if q.sharpness < 0.35:
        return False, "IMAGE_TOO_BLURRY"
    if q.face_ratio < 0.08:
        return False, "FACE_TOO_SMALL"
    return True, "OK"

# ============================================================
# APPEAL METRICS (SURFACE-LEVEL ONLY)
# ============================================================

@dataclass(frozen=True)
class AppealMetrics:
    skin: float
    frame: float
    eyes: float
    lips: float
    nose_surface: float
    soft_symmetry: float
    cleanliness: float

def normalize_metrics(m: AppealMetrics) -> AppealMetrics:
    return AppealMetrics(
        skin=_clamp(m.skin),
        frame=_clamp(m.frame),
        eyes=_clamp(m.eyes),
        lips=_clamp(m.lips),
        nose_surface=_clamp(m.nose_surface),
        soft_symmetry=_clamp(m.soft_symmetry),
        cleanliness=_clamp(m.cleanliness),
    )

def validate_metrics(m: AppealMetrics) -> bool:
    for v in m.__dict__.values():
        if not isinstance(v, (int, float)):
            return False
        if not math.isfinite(v):
            return False
    return True

# ============================================================
# WEIGHTS (SKIN-FIRST)
# ============================================================

@dataclass(frozen=True)
class AppealWeights:
    skin: float = 0.30
    frame: float = 0.20
    eyes: float = 0.15
    lips: float = 0.10
    nose_surface: float = 0.05
    soft_symmetry: float = 0.10
    cleanliness: float = 0.10

# ============================================================
# CONFIDENCE RANGE (UX-FRIENDLY)
# ============================================================

def confidence_range(score: float, metrics: AppealMetrics) -> Tuple[float, float]:
    spread = math.sqrt(
       _mean([(v - score) ** 2 for v in metrics.__dict__.values()])
    )
    delta = _clamp(spread / 2.5, 0.4, 1.2)
    return (
        round(_clamp(score - delta), 2),
        round(_clamp(score + delta), 2),
    )

# ============================================================
# PRESENTATION BANDS (STORE SAFE)
# ============================================================

def presentation_band(score: float) -> Tuple[str, str]:
    if score < 4.0:
        return (
            "Low presentation consistency (this capture)",
            "Surface-level presentation appears affected by skin condition, grooming, or lighting."
        )
    if score < 5.5:
        return (
            "Developing presentation consistency",
            "Several elements fall within common ranges. Minor refinements may help."
        )
    if score < 7.0:
        return (
            "Clean and consistent presentation",
            "The face appears generally clean and well-presented in this image."
        )
    if score < 8.8:
        return (
            "Strong presentation consistency",
            "Multiple surface-level elements appear well maintained."
        )
    return (
        "Very high presentation consistency",
        "Surface-level presentation appears unusually consistent in this capture."
    )

# ============================================================
# CORE PIPELINE
# ============================================================

def run_appeal_adapter_insight(
    *,
    image_bytes: bytes,
    image_quality: ImageQuality,
    metrics: AppealMetrics,
    user_age: Optional[int],
    confirm_age: bool,
    confirm_educational: bool,
    confirm_variability: bool,
    weights: AppealWeights = AppealWeights(),
) -> Dict:

    # ---------- ACCESS ----------
    ok, code = validate_access(
        user_age=user_age,
        confirm_age=confirm_age,
        confirm_educational=confirm_educational,
        confirm_variability=confirm_variability,
    )
    if not ok:
        return _error(code)

    # ---------- IMAGE ----------
    if not isinstance(image_bytes, (bytes, bytearray)):
        return _error("INVALID_IMAGE")

    ok, code = quality_gate(image_quality)
    if not ok:
        return _error(code)

    # ---------- METRICS ----------
    if not validate_metrics(metrics):
        return _error("PROCESSING_FAILED")

    m = normalize_metrics(metrics)

    # ---------- SCORE ----------
    score = (
        m.skin * weights.skin +
        m.frame * weights.frame +
        m.eyes * weights.eyes +
        m.lips * weights.lips +
        m.nose_surface * weights.nose_surface +
        m.soft_symmetry * weights.soft_symmetry +
        m.cleanliness * weights.cleanliness
    )
    score = round(_clamp(score), 2)

    rmin, rmax = confidence_range(score, m)
    band, interpretation = presentation_band(score)

    return {
        "status": "success",
        "presentation_score": score,
        "score_range": {"min": rmin, "max": rmax},
        "band": band,
        "components": m.__dict__,
        "interpretation": interpretation,
        "notes": [
            "This analysis reflects surface-level facial presentation in one image.",
            "Lighting, pose, and grooming strongly influence results.",
            "Presentation can change without altering facial structure.",
        ],
        "disclaimer": (
            "Educational and informational tool only. "
            "Does not evaluate attractiveness, personal value, or identity."
        ),
    }

# ============================================================
# ERROR RESPONSE
# ============================================================

def _error(code: str) -> Dict:
    return {
        "status": "error",
        "error": code,
        "message": ERROR_MESSAGES.get(code, "An error occurred."),
    }
# Backwards-compatible alias
run_appeal_analysis = run_appeal_adapter_insight