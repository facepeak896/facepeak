import numpy as np
import cv2
from insightface.app import FaceAnalysis

_embedding_app = None


def load_embedding_model():
    global _embedding_app

    if _embedding_app is None:
        app = FaceAnalysis(name="buffalo_l")

        # bolja detekcija
        app.prepare(ctx_id=-1, det_size=(640, 640))

        _embedding_app = app
        print("✅ buffalo_l loaded (CPU)")

    return _embedding_app


def _biggest_face(faces):
    return max(
        faces,
        key=lambda f: (f.bbox[2] - f.bbox[0]) * (f.bbox[3] - f.bbox[1])
    )


def extract_embedding(image_bytes: bytes):

    app = load_embedding_model()

    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        return None

    # zaštita od ogromnih slika
    h, w = img.shape[:2]
    if h > 2000 or w > 2000:
        img = cv2.resize(img, (1024, 1024))

    faces = app.get(img)

    if not faces:
        return None

    face = _biggest_face(faces)

    emb = face.embedding.astype(np.float32)

    # L2 normalizacija (mora biti ista kao u datasetu)
    emb /= (np.linalg.norm(emb) + 1e-9)

    yaw, pitch, roll = 0.0, 0.0, 0.0

    if hasattr(face, "pose") and face.pose is not None:
        try:
            yaw = float(face.pose[0])
            pitch = float(face.pose[1])
            roll = float(face.pose[2])
        except Exception:
            pass

    return {
        "embedding": emb.tolist(),  # JSON safe
        "yaw": yaw,
        "pitch": pitch,
        "roll": roll,
    }