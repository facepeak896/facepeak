# Backend/ai/insightface_core.py

from typing import Dict, Optional, Any
import cv2
import numpy as np
import math
from insightface.app import FaceAnalysis

EPS = 1e-6
_APP: Optional[FaceAnalysis] = None


def _get_app() -> FaceAnalysis:
    global _APP
    if _APP is None:
        app = FaceAnalysis(name="buffalo_l")
        app.prepare(ctx_id=-1)  # CPU
        _APP = app
    return _APP


def clamp(x: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, x))


def dist(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.linalg.norm(a - b))


def _safe_img_from_bytes(image_bytes: bytes):
    return cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)


def gaussian_score(x: float, mu: float, sigma: float) -> float:
    t = (x - mu) / (sigma + EPS)
    return float(np.exp(-0.5 * t * t))


def _roll_correct(points: np.ndarray) -> np.ndarray:
    # points: [le, re, nose, ml, mr]
    l, r = points[0], points[1]
    roll = math.atan2(r[1] - l[1], r[0] - l[0])
    c = (l + r) * 0.5
    ca, sa = math.cos(-roll), math.sin(-roll)
    out = []
    for p in points:
        v = p - c
        out.append(np.array([v[0]*ca - v[1]*sa, v[0]*sa + v[1]*ca], dtype=np.float32) + c)
    return np.stack(out)


def run_insightface_core(image_bytes: bytes) -> Dict[str, Any]:
    """
    Core face detection + universal signals.
    Use this output as the base for PSL / Appeal / Symmetry adapters.
    """
    img = _safe_img_from_bytes(image_bytes)
    if img is None:
        return {}

    h, w, _ = img.shape
    if h < 80 or w < 80:
        return {}

    faces = _get_app().get(img)
    if not faces:
        return {}

    face = max(faces, key=lambda f: (f.bbox[2]-f.bbox[0])*(f.bbox[3]-f.bbox[1]))

    x1, y1, x2, y2 = [float(v) for v in face.bbox]
    face_w = max(EPS, x2 - x1)
    face_h = max(EPS, y2 - y1)

    kps = np.array(face.kps, dtype=np.float32)  # [5,2]
    kps = _roll_correct(kps)
    le, re, nose, ml, mr = kps

    ipd = dist(le, re)
    if ipd < max(42.0, w * 0.055):
        return {}

    mid_x = float((le[0] + re[0]) * 0.5)

    # --------------------
    # Quality-ish signals
    # --------------------
    reliability = clamp((ipd - 40.0) / 50.0, 0.0, 1.0)

    mouth_w = max(dist(ml, mr), ipd * 0.35)
    mouth_ratio = mouth_w / (ipd + EPS)
    width_ratio = face_w / (ipd + EPS)
    bbox_aspect = face_w / (face_h + EPS)

    mouth_y = abs(float(ml[1] - mr[1])) / (ipd + EPS)
    mouth_shift = abs(float(((ml + mr) * 0.5)[0] - mid_x)) / (ipd + EPS)
    eye_y = abs(float(le[1] - re[1])) / (ipd + EPS)

    expr = clamp(
        (mouth_y - 0.02) / 0.08 * 0.55 +
        (mouth_shift - 0.03) / 0.12 * 0.30 +
        (eye_y - 0.01) / 0.05 * 0.15,
        0.0, 1.0
    )

    pose = clamp(
        (eye_y - 0.012) / 0.05 * 0.60 +
        abs(bbox_aspect - 0.78) / 0.35 * 0.40,
        0.0, 1.0
    )

    # --------------------
    # Geometry features (reusable)
    # --------------------
    mouth_w_safe = max(mouth_w, ipd * 0.35)
    taper = face_w / (mouth_w_safe + EPS)

    chin = np.array([mid_x, y2], dtype=np.float32)
    lower_third = dist(nose, chin) / (face_h + EPS)

    # Symmetry (0..1)
    def mirror(p):
        return np.array([2.0 * mid_x - p[0], p[1]], dtype=np.float32)

    asym = (dist(le, mirror(re)) + dist(ml, mirror(mr))) / (2.0 * ipd + EPS)
    symmetry_01 = clamp(1.0 - (asym / 0.06), 0.0, 1.0)

    # Skin rough proxy (0..1) from face ROI std
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    xi1, yi1, xi2, yi2 = int(max(0, x1)), int(max(0, y1)), int(min(w, x2)), int(min(h, y2))
    face_gray = gray[yi1:yi2, xi1:xi2]
    if face_gray.size < 80:
        skin_std = 999.0
        skin_01 = 0.5
    else:
        skin_std = float(np.std(face_gray))
        # soft mapping (tune later)
        skin_01 = clamp(1.0 - (skin_std - 18.0) / 45.0, 0.0, 1.0)

    # A simple “presence” proxy (0..1) using spacing gaussian
    spacing = (ipd + EPS) / (face_w + EPS)
    presence_01 = clamp(gaussian_score(spacing, 0.46, 0.07), 0.0, 1.0)

    return {
        "bbox": [x1, y1, x2, y2],
        "kps": kps.tolist(),
        "ipd": float(ipd),
        "width_ratio": float(width_ratio),
        "mouth_ratio": float(mouth_ratio),
        "taper": float(taper),
        "lower_third": float(lower_third),

        "symmetry_01": float(symmetry_01),
        "skin_01": float(skin_01),
        "skin_std": float(skin_std),
        "presence_01": float(presence_01),

        "expr": float(expr),
        "pose": float(pose),
        "reliability": float(reliability),
    }