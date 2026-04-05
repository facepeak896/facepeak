from typing import Dict, Optional
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

def clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))

def dist(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.linalg.norm(a - b))

def _safe_img_from_bytes(image_bytes: bytes):
    return cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)

def z_norm(v: float, center: float, spread: float) -> float:
    return (v - center) / (spread + EPS)

def norm_0_10(z: float, slope: float = 2.3, clip: float = 2.3) -> float:
    z = clamp(z, -clip, clip)
    return clamp(5.0 + z * slope, 0.0, 10.0)

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

def run_insightface_detector(image_bytes: bytes) -> Dict[str, float]:
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

    kps = np.array(face.kps, dtype=np.float32)
    kps = _roll_correct(kps)

    le, re, nose, ml, mr = kps
    ipd = dist(le, re)

    # reliability / resolution gate (soft)
    # if too low, return empty to force NO_FACE upstream
    if ipd < max(42.0, w * 0.055):
        return {}

    mid_x = (le[0] + re[0]) * 0.5
    x1, y1, x2, y2 = [float(v) for v in face.bbox]
    face_w = max(EPS, x2 - x1)
    face_h = max(EPS, y2 - y1)

    # --------------------
    # STRUCTURE (bone / face_shape)
    # --------------------
    mouth_w = max(dist(ml, mr), ipd * 0.35)
    taper = face_w / (mouth_w + EPS)
    taper_s = norm_0_10(z_norm(taper, 2.05, 0.30), slope=2.0)

    chin = np.array([mid_x, y2], dtype=np.float32)
    lower_third = dist(nose, chin) / (face_h + EPS)
    lt_s = clamp(2.2 + 7.8 * gaussian_score(lower_third, 0.52, 0.085), 0.0, 10.0)

    bone = clamp(0.62 * taper_s + 0.38 * lt_s, 0.0, 10.0)
    face_shape = clamp(0.44 * taper_s + 0.56 * lt_s, 0.0, 10.0)

    # --------------------
    # SYMMETRY
    # --------------------
    def mirror(p):
        return np.array([2.0 * mid_x - p[0], p[1]], dtype=np.float32)

    asym = (dist(le, mirror(re)) + dist(ml, mirror(mr))) / (2.0 * ipd + EPS)
    symmetry = clamp(norm_0_10(-z_norm(asym, 0.022, 0.012), slope=2.6), 0.0, 10.0)

    # --------------------
    # EXPRESSION / POSE (for quality flags)
    # expr in [0..1], pose in [0..1]
    # --------------------
    mouth_y = abs(float(ml[1] - mr[1])) / (ipd + EPS)
    mouth_shift = abs(float(((ml + mr) * 0.5)[0] - mid_x)) / (ipd + EPS)
    eye_y = abs(float(le[1] - re[1])) / (ipd + EPS)

    expr = clamp(
        (mouth_y - 0.02) / 0.08 * 0.55 +
        (mouth_shift - 0.03) / 0.12 * 0.30 +
        (eye_y - 0.01) / 0.05 * 0.15,
        0.0, 1.0
    )

    # A gentler expr_cap (we cap tiers in PSL adapter)
    expr_cap = clamp(1.0 - expr * 0.45, 0.72, 1.0)

    # Pose proxy: eye vertical misalignment + bbox aspect weirdness
    bbox_aspect = face_w / (face_h + EPS)
    pose = clamp(
        (eye_y - 0.012) / 0.05 * 0.60 +
        abs(bbox_aspect - 0.78) / 0.35 * 0.40,
        0.0, 1.0
    )

    # --------------------
    # INFLATION DETECTOR (NOT "fat")
    # detects distortions from:
    # - hands pressing cheeks
    # - extreme expressions
    # - very close lens / wide-angle
    # Uses width_ratio and mouth_w context.
    # --------------------
    width_ratio = face_w / (ipd + EPS)
    mouth_ratio = mouth_w / (ipd + EPS)  # larger in smiles / open mouth

    # Inflation rises when face appears too wide relative to IPD, and mouth ratio suggests expression distortion.
    inflation = clamp(
        (width_ratio - 2.20) / 0.35 * 0.70 +
        (mouth_ratio - 0.55) / 0.25 * 0.30,
        0.0, 1.0
    )

    # Back-compat field name: fat_cap, but it's now a distortion cap.
    # Lower means more distortion risk.
    fat_cap = clamp(1.0 - inflation * 0.55, 0.55, 1.0)

    # --------------------
    # APPEAL (keep centered, avoid baseline-high)
    # --------------------
    spacing = (ipd + EPS) / (face_w + EPS)
    g = gaussian_score(spacing, 0.46, 0.07)  # 0..1
    appeal = clamp(4.0 + 4.8 * g, 0.0, 9.0)

    # --------------------
    # SKIN (face ROI only)
    # --------------------
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    xi1, yi1, xi2, yi2 = int(max(0, x1)), int(max(0, y1)), int(min(w, x2)), int(min(h, y2))
    face_gray = gray[yi1:yi2, xi1:xi2]

    if face_gray.size < 80:
        skin = 5.0
        skin_std = 999.0
    else:
        skin_std = float(np.std(face_gray))
        # less harsh; avoid murdering skin from noise
        skin = clamp(8.8 - skin_std / 22.0, 0.0, 9.0)

    # Hair left for ML adapter; keep baseline neutral
    hair = 5.0

    # Reliability score (0..1) for low-res, tiny face, etc.
    # You can expand this later (blur/brightness).
    reliability = clamp((ipd - 40.0) / 50.0, 0.0, 1.0)

    return {
        "bone": float(round(bone, 2)),
        "face_shape": float(round(face_shape, 2)),
        "symmetry": float(round(symmetry, 2)),
        "appeal": float(round(appeal, 2)),
        "skin": float(round(skin, 2)),
        "hair": float(round(hair, 2)),

        # quality / gating signals
        "expr": float(round(expr, 3)),
        "pose": float(round(pose, 3)),
        "inflation": float(round(inflation, 3)),
        "reliability": float(round(reliability, 3)),

        # caps (PSL will also cap via tier_cap)
        "expr_cap": float(round(expr_cap, 3)),
        "fat_cap": float(round(fat_cap, 3)),

        # debug signals
        "width_ratio": float(round(width_ratio, 3)),
        "spacing": float(round(spacing, 3)),
        "skin_std": float(round(skin_std, 2)),
        "ipd": float(round(ipd, 2)),
    }