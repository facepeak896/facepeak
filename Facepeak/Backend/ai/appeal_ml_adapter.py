from typing import Dict
import numpy as np
import cv2
import math

import face_alignment


# -------------------------------------------------
# Lazy singleton (CPU)
# -------------------------------------------------
_FA = None

def _get_fa():
    global _FA
    if _FA is None:
        _FA = face_alignment.FaceAlignment(
            face_alignment.LandmarksType.TWO_D,
            device="cpu",
            flip_input=False,
        )
    return _FA


# -------------------------------------------------
# Helpers
# -------------------------------------------------
def clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


def dist(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.linalg.norm(a - b))


def gaussian(x: float, mu: float, sigma: float) -> float:
    return math.exp(-0.5 * ((x - mu) / (sigma + 1e-6)) ** 2)


# -------------------------------------------------
# MAIN
# -------------------------------------------------
def run_appeal_ml_analysis(image_bytes: bytes) -> Dict[str, float]:
    """
    Returns:
    appeal_ml_score: 0–10
    """

    # decode
    img = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        return {}

    h, w, _ = img.shape
    if h < 80 or w < 80:
        return {}

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    fa = _get_fa()
    landmarks_all = fa.get_landmarks(img_rgb)

    if landmarks_all is None or len(landmarks_all) == 0:
        return {}

    lm = landmarks_all[0]  # (68, 2)

    # -------------------------
    # Key points
    # -------------------------
    left_eye = lm[36:42].mean(axis=0)
    right_eye = lm[42:48].mean(axis=0)
    nose_tip = lm[33]
    mouth_l = lm[48]
    mouth_r = lm[54]
    chin = lm[8]

    ipd = dist(left_eye, right_eye)
    if ipd < w * 0.05:
        return {}

    face_h = dist(lm[27], chin)
    face_w = dist(lm[0], lm[16])

    # -------------------------
    # Appeal components
    # -------------------------

    # 1️⃣ Eye spacing harmony
    eye_spacing = ipd / (face_w + 1e-6)
    eye_q = gaussian(eye_spacing, mu=0.46, sigma=0.06)

    # 2️⃣ Mouth balance
    mouth_w = dist(mouth_l, mouth_r)
    mouth_ratio = mouth_w / (face_w + 1e-6)
    mouth_q = gaussian(mouth_ratio, mu=0.38, sigma=0.07)

    # 3️⃣ Vertical thirds (nose position)
    nose_pos = dist(lm[27], nose_tip) / (face_h + 1e-6)
    nose_q = gaussian(nose_pos, mu=0.33, sigma=0.06)

    # 4️⃣ Eye–mouth vertical harmony
    eye_line_y = (left_eye[1] + right_eye[1]) * 0.5
    em_ratio = (nose_tip[1] - eye_line_y) / (face_h + 1e-6)
    em_q = gaussian(em_ratio, mu=0.30, sigma=0.07)

    # -------------------------
    # Combine (appeal = harmony)
    # -------------------------
    raw = (
        0.35 * eye_q +
        0.30 * mouth_q +
        0.20 * nose_q +
        0.15 * em_q
    )

    appeal_ml = clamp(2.0 + raw * 8.0, 0.0, 10.0)

    return {
        "appeal_ml_score": round(float(appeal_ml), 2)
    }