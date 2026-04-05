from typing import Dict, Optional
import cv2
import numpy as np

from .hair_ml_segmenter import run_hair_ml_analysis as _run_hair_ml_core


def run_hair_ml_analysis(image_bytes: bytes) -> Optional[Dict[str, float]]:
    if not image_bytes:
        return None

    img_bgr = cv2.imdecode(
        np.frombuffer(image_bytes, np.uint8),
        cv2.IMREAD_COLOR,
    )

    if img_bgr is None or img_bgr.size == 0:
        return None

    return _run_hair_ml_core(img_bgr)