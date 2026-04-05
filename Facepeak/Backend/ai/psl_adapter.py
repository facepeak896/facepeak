import joblib
import numpy as np
from pathlib import Path

MODEL_PATH = Path("psl_xgb.pkl")

_model_pack = None


# =========================
# LOAD MODEL
# =========================
def load_psl_model():
    global _model_pack

    if _model_pack is None:
        _model_pack = joblib.load(MODEL_PATH)
        print("✅ PSL ordinal model pack loaded")

    return _model_pack


# =========================
# TIER SYSTEM (UI + DATA)
# =========================
TIER_DATA = {
    1: {"name": "Needs improvement", "percentile": "Bottom 90%"},
    2: {"name": "Lower tier", "percentile": "Bottom 70%"},
    3: {"name": "Average", "percentile": "Top 50%"},
    4: {"name": "Above average", "percentile": "Top 30%"},
    5: {"name": "High tier", "percentile": "Top 15%"},
    6: {"name": "Chadlite", "percentile": "Top 5%"},
    7: {"name": "Chad", "percentile": "Top 1%"},
    8: {"name": "Elite", "percentile": "Top 0.1%"},
}


# =========================
# ORDINAL → CLASS PROBS
# =========================
def reconstruct_probs(pack, X):
    probs_gt = np.column_stack([
        pack["models"][f"gt_{thr}"].predict_proba(X)[:, 1]
        for thr in range(1, 8)
    ])

    N = probs_gt.shape[0]
    p = np.zeros((N, 8), dtype=np.float32)

    p[:, 0] = 1.0 - probs_gt[:, 0]

    for i in range(1, 7):
        p[:, i] = np.clip(probs_gt[:, i - 1] - probs_gt[:, i], 0.0, 1.0)

    p[:, 7] = probs_gt[:, 6]

    # normalize
    s = p.sum(axis=1, keepdims=True)
    s = np.where(s <= 1e-6, 1.0, s)

    return p / s


# =========================
# MAIN
# =========================
def run_psl_adapter(extractor_output):

    embedding = extractor_output.get("embedding")

    if embedding is None:
        return {"status": "error", "reason": "NO_EMBEDDING"}

    model_pack = load_psl_model()

    X = np.array([embedding], dtype=np.float32)

    # ------------------------
    # PROBS
    # ------------------------
    probs = reconstruct_probs(model_pack, X)

    pred = int(np.argmax(probs[0]) + 1)
    confidence = float(np.max(probs[0]))

    # ------------------------
    # OPTIONAL STABILITY
    # ------------------------
    prev = extractor_output.get("previous_score")

    if prev is not None:
        # smoothing (da score ne skače)
        pred = int(round((pred + prev) / 2))

    # ------------------------
    # TIER DATA
    # ------------------------
    tier_info = TIER_DATA.get(pred, {})

    return {
        "status": "success",
        "psl": {
            "psl_score": pred,
            "tier": tier_info.get("name"),
            "percentile": tier_info.get("percentile"),
            "confidence": round(confidence, 3),
        }
    }