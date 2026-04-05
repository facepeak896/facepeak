from typing import Dict, Any
import cv2
import numpy as np
import math

# ============================================================
# CONSTANTS
# ============================================================

EPS = 1e-6

EDGE_LOW = 0.015
EDGE_HIGH = 0.08

NOISE_LOW = 0.02
NOISE_HIGH = 0.10


# ============================================================
# HELPERS
# ============================================================

def _clamp(x: float, lo: float = 0.0, hi: float = 10.0) -> float:
    return max(lo, min(hi, x))

def _clamp01(x: float) -> float:
    return max(0.0, min(1.0, x))

def _map01(x: float, lo: float, hi: float) -> float:
    if hi <= lo:
        return 0.5
    return _clamp01((x - lo) / (hi - lo))

def _map10(x01: float) -> float:
    return round(_clamp01(x01) * 10.0, 2)

def _decode(image_bytes: bytes) -> np.ndarray:
    img = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError("Invalid image")
    return img


# ============================================================
# CORE ANALYSIS
# ============================================================

def run_hair_analysis(image_bytes: bytes) -> Dict[str, Any]:
    """
    Hair & hairline analysis (V2.1 polished).
    CV-based, store-safe, presentation-focused.
    """

    if not image_bytes:
        return {
            "status": "error",
            "error": "EMPTY_IMAGE",
            "message": "No image data provided."
        }

    try:
        img = _decode(image_bytes)
        h, w = img.shape[:2]

        if h < 120 or w < 120:
            return {
                "status": "error",
                "error": "IMAGE_TOO_SMALL",
                "message": "Image resolution too low."
            }

        # ---------- ROI (top head region with fallback) ----------
        roi_h = int(h * 0.45)
        roi_h = max(roi_h, int(h * 0.30))  # fallback for close-up shots

        roi = img[0:roi_h, int(w * 0.15):int(w * 0.85)]

        gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
        blur = cv2.GaussianBlur(gray, (5, 5), 0)

        # ---------- HAIR DENSITY ----------
        edges = cv2.Canny(blur, 60, 140)
        edge_density = float(np.mean(edges > 0))
        hair_density = _map10(_map01(edge_density, EDGE_LOW, EDGE_HIGH))

        # ---------- HAIR HEALTH (shine + uniformity) ----------
        y = cv2.cvtColor(roi, cv2.COLOR_BGR2YCrCb)[:, :, 0] / 255.0
        mean_y = float(np.mean(y))

        # Ideal brightness ~0.5 (penalize under/overexposure)
        shine_score = 1.0 - abs(mean_y - 0.5)
        shine_score = _clamp01(shine_score)

        noise = float(np.std(blur) / 255.0)
        uniformity = 1.0 - _map01(noise, NOISE_LOW, NOISE_HIGH)
        uniformity = _clamp01(uniformity)

        hair_health = _map10(0.6 * shine_score + 0.4 * uniformity)

        # ---------- GROOMING QUALITY ----------
        lap = cv2.Laplacian(gray, cv2.CV_64F)
        sharpness = float(lap.var() / 400.0)
        grooming_quality = _map10(_clamp01(sharpness))

        # ---------- HAIRLINE SHAPE ----------
        top_profile = np.mean(gray[:int(gray.shape[0] * 0.25)], axis=1)
        variation = float(np.std(top_profile) / 255.0)
        hairline_shape = _map10(1.0 - _map01(variation, 0.04, 0.12))

        # ---------- HAIRSTYLE FIT ----------
        hairstyle_fit = _map10(
            0.5 * (hair_density / 10.0) +
            0.3 * (grooming_quality / 10.0) +
            0.2 * (hair_health / 10.0)
        )

        # ---------- OVERALL SCORE ----------
        overall_score = round(
            hair_density * 0.30 +
            hairline_shape * 0.20 +
            hair_health * 0.20 +
            hairstyle_fit * 0.20 +
            grooming_quality * 0.10,
            2
        )

        # ---------- TIER ----------
        if overall_score < 5.5:
            tier = "Developing"
            interpretation = "Hair presentation currently limits overall visual impact."
        elif overall_score < 6.8:
            tier = "Balanced"
            interpretation = "Hair is within a common range and suits the face reasonably."
        elif overall_score < 8.2:
            tier = "Advanced"
            interpretation = "Hair complements facial structure and enhances presentation."
        else:
            tier = "Elite"
            interpretation = "Hair strongly enhances overall facial harmony."

        return {
            "status": "success",
            "overall_score": overall_score,
            "tier": tier,
            "metrics": {
                "hair_density": hair_density,
                "hairline_shape": hairline_shape,
                "hair_health": hair_health,
                "hairstyle_fit": hairstyle_fit,
                "grooming_quality": grooming_quality,
            },
            "interpretation": interpretation,
            "notes": [
                "Hair analysis uses texture, consistency, and lighting proxies.",
                "Lighting, hairstyle choice, and grooming influence results.",
            ],
            "disclaimer": (
                "Educational and informational analysis only. "
                "Not a judgment of appearance or personal value."
            ),
        }

    except Exception as e:
        return {
            "status": "error",
            "error": "HAIR_ANALYSIS_FAILED",
            "message": str(e),
        }