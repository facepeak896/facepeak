import jwt
from datetime import datetime, timedelta
import os
from fastapi import HTTPException

# =========================
# CONFIG
# =========================

SECRET_KEY = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"

ACCESS_EXPIRE_MIN = 15
REFRESH_EXPIRE_DAYS = 7

# 🔥 clock skew tolerance (production safe)
CLOCK_SKEW = 10  # seconds

if not SECRET_KEY:
    raise RuntimeError("JWT_SECRET not set")


# =========================
# CREATE TOKENS
# =========================

def create_access_token(user_id: int):
    now = datetime.utcnow()

    payload = {
        "sub": str(user_id),
        "type": "access",
        "iat": now,
        "exp": now + timedelta(minutes=ACCESS_EXPIRE_MIN),
    }

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(user_id: int, jti: str):
    now = datetime.utcnow()

    payload = {
        "sub": str(user_id),
        "type": "refresh",
        "jti": jti,  # 🔥 session identifier
        "iat": now,
        "exp": now + timedelta(days=REFRESH_EXPIRE_DAYS),
    }

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# =========================
# DECODE TOKEN
# =========================

def decode_token(token: str):
    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM],
            options={"verify_exp": True},
            leeway=CLOCK_SKEW,  # 🔥 clock sync tolerance
        )
        return payload

    except jwt.ExpiredSignatureError:
        raise HTTPException(401, "TOKEN_EXPIRED")

    except jwt.InvalidTokenError:
        raise HTTPException(401, "INVALID_TOKEN")


# =========================
# HELPERS
# =========================

def get_token_type(payload: dict):
    return payload.get("type")


def get_user_id(payload: dict):
    try:
        return int(payload.get("sub"))
    except:
        raise HTTPException(401, "INVALID_TOKEN_PAYLOAD")


def get_jti(payload: dict):
    return payload.get("jti")