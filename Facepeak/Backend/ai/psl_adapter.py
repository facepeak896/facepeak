import joblib
import numpy as np
from pathlib import Path

from Backend.ai.psl_stabilizer import stabilize_psl

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
    1: {"name": "Needs improvement"},
    2: {"name": "Lower tier"},
    3: {"name": "Average"},
    4: {"name": "Above average"},
    5: {"name": "High tier"},
    6: {"name": "Chadlite"},
    7: {"name": "Chad"},
    8: {"name": "Elite"},
}


PERCENTILE_RANGES = {
    1: ("bottom", 80, 100),
    2: ("bottom", 51, 79),
    3: ("top", 41, 50),
    4: ("top", 21, 40),
    5: ("top", 10, 20),
    6: ("top", 5, 9),
    7: ("top", 2, 4),
    8: ("top", 0.0001, 0.00001),
}


def build_unique_percentile(final_score: int, raw_expected: float) -> str:
    style, low, high = PERCENTILE_RANGES[final_score]

    if final_score == 8:
        return "Top 1%"

    raw_min = final_score - 0.5
    raw_max = final_score + 0.499

    raw_clamped = max(raw_min, min(raw_expected, raw_max))
    normalized = (raw_clamped - raw_min) / (raw_max - raw_min)

    value = round(high - normalized * (high - low))
    value = max(low, min(high, value))

    if style == "top":
        return f"Top {value}%"
    return f"Bottom {value}%"


# =========================
# ORDINAL → CLASS PROBS
# =========================
def reconstruct_probs(pack, X):
    probs_gt = np.column_stack([
        pack["models"][f"gt_{thr}"].predict_proba(X)[:, 1]
        for thr in range(1, 8)
    ])

    n = probs_gt.shape[0]
    p = np.zeros((n, 8), dtype=np.float32)

    p[:, 0] = 1.0 - probs_gt[:, 0]

    for i in range(1, 7):
        p[:, i] = np.clip(probs_gt[:, i - 1] - probs_gt[:, i], 0.0, 1.0)

    p[:, 7] = probs_gt[:, 6]

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

    probs = reconstruct_probs(model_pack, X)

    raw_pred = int(np.argmax(probs[0]) + 1)
    raw_confidence = float(np.max(probs[0]))
    previous_score = extractor_output.get("previous_score")

    stable = stabilize_psl(
        probs=probs[0],
        raw_pred=raw_pred,
        raw_confidence=raw_confidence,
        previous_score=previous_score,
    )

    final_score = stable["stable_score_int"]

    # 🔥 HARD FLOOR — nikad ne pada ispod previous
    if previous_score is not None:
        final_score = max(final_score, int(round(previous_score)))

    tier_info = TIER_DATA.get(final_score, TIER_DATA[raw_pred])

    unique_percentile = build_unique_percentile(
        final_score=final_score,
        raw_expected=float(stable["raw_expected"]),
    )

    print("\n🎯 PSL ADAPTER FINAL")
    print("raw_pred:", raw_pred)
    print("raw_confidence:", round(raw_confidence, 3))
    print("previous_score:", previous_score)
    print("stable_score_float:", stable["stable_score_float"])
    print("final_score:", final_score)
    print("bonus_applied:", stable["bonus_applied"])
    print("raw_expected:", stable["raw_expected"])
    print("percentile:", unique_percentile)

    return {
        "status": "success",
        "psl": {
            "psl_score": final_score,
            "tier": tier_info.get("name"),
            "percentile": unique_percentile,
            "confidence": stable["confidence"],
            "stable_score_float": stable["stable_score_float"],
            "raw_expected": stable["raw_expected"],
            "bonus_applied": stable["bonus_applied"],
        },
    }