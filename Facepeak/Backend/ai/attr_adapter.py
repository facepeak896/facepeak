from pathlib import Path
import joblib
import numpy as np

MODEL_PATH = Path("models/attr_model.pkl")

_model = None
_attr_names = None


def load_attr_model():
    global _model, _attr_names

    if _model is None:
        bundle = joblib.load(MODEL_PATH)

        _model = bundle["model"]
        _attr_names = bundle["attributes"]

        print("ATTR MODEL LOADED")

    return _model, _attr_names


def predict_attributes(embedding):

    model, attr_names = load_attr_model()

    X = np.array([embedding], dtype=np.float32)

    preds = model.predict(X)[0]

    attrs = {}

    for i, name in enumerate(attr_names):
        attrs[name] = bool(preds[i])

    return attrs