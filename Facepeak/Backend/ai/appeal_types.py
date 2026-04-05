# Backend/ai/appeal_types.py
from dataclasses import dataclass

# =============================
# IMAGE QUALITY (CV CONTEXT)
# =============================

@dataclass
class ImageQuality:
    brightness: float   # 0–1
    sharpness: float    # 0–1
    face_ratio: float   # 0–1

    def confidence(self) -> float:
        # conservative aggregate
        return (
            0.4 * self.sharpness +
            0.4 * self.face_ratio +
            0.2 * self.brightness
        )


# =============================
# RAW APPEAL SIGNALS
# (EXTRACTOR → ADAPTER CONTRACT)
# =============================

@dataclass
class AppealRawSignals:
    # facial features (0–1)
    eyes: float
    nose: float
    mouth: float

    # structure & balance
    symmetry_soft: float
    bone_hint: float

    # skin / surface quality
    skin: float

    # face mass (0 = lean, 1 = obese)
    face_fullness: float

    # photo context (already normalized 0–1)
    photo_quality: float     # lighting + sharpness
    face_scale: float        # relative face size in frame