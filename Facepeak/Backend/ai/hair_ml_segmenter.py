from typing import Dict
import cv2
import numpy as np
import torch
import segmentation_models_pytorch as smp

# ======================================================
# MODEL (lazy load)
# ======================================================

_MODEL = None
_DEVICE = torch.device("cpu")

def _get_model():
    global _MODEL
    if _MODEL is None:
        # Generic UNet – radi OK bez custom traininga
        _MODEL = smp.Unet(
            encoder_name="resnet18",
            encoder_weights="imagenet",
            in_channels=3,
            classes=1,
            activation=None,
        )
        _MODEL.to(_DEVICE)
        _MODEL.eval()
    return _MODEL


# ======================================================
# HELPERS
# ======================================================

def _preprocess(img_bgr: np.ndarray) -> torch.Tensor:
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    img_rgb = cv2.resize(img_rgb, (256, 256))
    img = img_rgb.astype(np.float32) / 255.0
    img = np.transpose(img, (2, 0, 1))
    return torch.from_numpy(img).unsqueeze(0).to(_DEVICE)


def _sigmoid(x: np.ndarray) -> np.ndarray:
    return 1.0 / (1.0 + np.exp(-x))


def _clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


# ======================================================
# MAIN
# ======================================================

def run_hair_ml_analysis(image_bgr: np.ndarray) -> Dict[str, float]:
    """
    Returns:
    - hair_score (0–10)
    - coverage (0–1)
    - density (0–1)
    """

    if image_bgr is None or image_bgr.size == 0:
        return {"hair_score": 5.0, "coverage": 0.0, "density": 0.0}

    model = _get_model()

    with torch.no_grad():
        x = _preprocess(image_bgr)
        logits = model(x)[0, 0].cpu().numpy()

    prob = _sigmoid(logits)
    mask = (prob > 0.5).astype(np.uint8)

    # ==================================================
    # METRICS
    # ==================================================

    h, w = mask.shape
    area = float(h * w)
    hair_pixels = float(mask.sum())

    coverage = hair_pixels / area if area > 0 else 0.0

    # density proxy (koliko je mask "puna", a ne šuplja)
    kernel = np.ones((5, 5), np.uint8)
    filled = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    density = (
        hair_pixels / float(filled.sum())
        if filled.sum() > 0
        else 0.0
    )

    # ==================================================
    # SCORE MAPPING (REALNO, NE PRETJERANO)
    # ==================================================

    # coverage: 0.05–0.35 je realan range
    cov_score = _clamp((coverage - 0.05) / 0.30, 0.0, 1.0)

    # density: 0.4–0.9
    den_score = _clamp((density - 0.4) / 0.5, 0.0, 1.0)

    hair_score = 3.5 + (cov_score * 4.0) + (den_score * 2.5)
    hair_score = _clamp(hair_score, 0.0, 9.2)

    return {
        "hair_score": round(float(hair_score), 2),
        "coverage": round(float(coverage), 3),
        "density": round(float(density), 3),
    }