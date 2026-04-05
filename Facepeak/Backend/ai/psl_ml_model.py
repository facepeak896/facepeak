from pathlib import Path
import joblib

ROOT_DIR = Path(__file__).resolve().parents[2]
MODEL_PATH = ROOT_DIR / "psl_xgb.pkl"

_model_pack = None


def load_psl_model():
    global _model_pack

    if _model_pack is None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(f"PSL model not found at {MODEL_PATH}")

        pack = joblib.load(MODEL_PATH)

        if not isinstance(pack, dict) or pack.get("type") != "psl_xgb_v10_ordinal":
            raise ValueError("Loaded PSL model is not ordinal v10 pack")

        _model_pack = pack
        print("✅ PSL ordinal model pack loaded")

    return _model_pack