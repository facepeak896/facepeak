import uuid
import hashlib


# =========================
# HELPERS
# =========================

def generate_jti() -> str:
    return str(uuid.uuid4())


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()