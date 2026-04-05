from typing import Dict
import cv2
import numpy as np

from Backend.ai.skin_ml_segmenter import segment_skin


def _clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


def run_skin_ml_analysis(image_bytes: bytes) -> Dict[str, float]:
    """
    Adapter:
    - poziva ML segmenter
    - računa score 0-10
    - vraća CLEAN payload
    """

    img = cv2.imdecode(
        np.frombuffer(image_bytes, np.uint8),
        cv2.IMREAD_COLOR
    )

    if img is None:
        return {
            "overall_score": 5.0,
            "confidence": 0.0,
        }

    mask = segment_skin(img)

    if mask is None or mask.size == 0:
        return {
            "overall_score": 5.0,
            "confidence": 0.0,
        }

    skin_pixels = float((mask > 0).sum())
    total_pixels = float(mask.size)

    coverage = skin_pixels / total_pixels if total_pixels > 0 else 0.0

    # REALISTIC mapping
    score = 3.0 + coverage * 8.0
    score = _clamp(score, 0.0, 9.5)

    return {
        "overall_score": round(score, 2),
        "confidence": round(coverage, 3),
    }