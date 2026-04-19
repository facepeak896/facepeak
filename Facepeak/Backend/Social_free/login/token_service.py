from jose import jwt, JWTError, ExpiredSignatureError
from datetime import datetime, timedelta, timezone
import os
from fastapi import HTTPException

# =========================
# CONFIG
# =========================

SECRET_KEY = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"

ACCESS_EXPIRE_MIN = 15
REFRESH_EXPIRE_DAYS = 7
CLOCK_SKEW = 10  # seconds

ISSUER = "facepeak"
MIN_SECRET_LENGTH = 32

if not SECRET_KEY:
    raise RuntimeError("JWT_SECRET not set")

if len(SECRET_KEY) < MIN_SECRET_LENGTH:
    raise RuntimeError("JWT_SECRET too short")


# =========================
# INTERNAL HELPERS
# =========================

def _auth_error(detail: str):
    return HTTPException(
        status_code=401,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


def _now_utc() -> datetime:
    return datetime.now(timezone.utc)


def _base_payload(user_id: int, token_type: str) -> dict:
    now = _now_utc()

    return {
        "sub": str(user_id),
        "type": token_type,
        "iat": int(now.timestamp()),
        "nbf": int(now.timestamp()),
        "iss": ISSUER,
    }


def _validate_payload_shape(payload: dict):
    if not isinstance(payload, dict):
        raise _auth_error("INVALID_TOKEN")

    if "sub" not in payload:
        raise _auth_error("INVALID_TOKEN_PAYLOAD")

    if "type" not in payload:
        raise _auth_error("INVALID_TOKEN_PAYLOAD")

    token_type = payload.get("type")
    if token_type not in {"access", "refresh"}:
        raise _auth_error("INVALID_TOKEN_PAYLOAD")

    if "iss" not in payload or payload.get("iss") != ISSUER:
        raise _auth_error("INVALID_TOKEN_ISSUER")


# =========================
# CREATE TOKENS
# =========================

def create_access_token(user_id: int):
    now = _now_utc()
    payload = _base_payload(user_id, "access")

    payload["exp"] = int((now + timedelta(minutes=ACCESS_EXPIRE_MIN)).timestamp())

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(user_id: int, jti: str):
    if not jti or not isinstance(jti, str):
        raise ValueError("jti is required for refresh token")

    now = _now_utc()
    payload = _base_payload(user_id, "refresh")

    payload["jti"] = jti
    payload["exp"] = int((now + timedelta(days=REFRESH_EXPIRE_DAYS)).timestamp())

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# =========================
# DECODE TOKEN
# =========================

def decode_token(token: str):
    try:
        if not token or not isinstance(token, str):
            raise _auth_error("INVALID_TOKEN")

        payload = jwt.decode(
            token.strip(),
            SECRET_KEY,
            algorithms=[ALGORITHM],
            options={
                "verify_exp": True,
                "verify_nbf": True,
                "verify_iat": True,
            },
            issuer=ISSUER,
            leeway=CLOCK_SKEW,
        )

        _validate_payload_shape(payload)

        return payload

    except ExpiredSignatureError:
        raise _auth_error("TOKEN_EXPIRED")

    except JWTError:
        raise _auth_error("INVALID_TOKEN")


# =========================
# HELPERS
# =========================

def get_token_type(payload: dict):
    _validate_payload_shape(payload)
    return payload["type"]


def get_user_id(payload: dict):
    _validate_payload_shape(payload)

    try:
        return int(payload["sub"])
    except Exception:
        raise _auth_error("INVALID_TOKEN_PAYLOAD")


def get_jti(payload: dict):
    _validate_payload_shape(payload)

    token_type = payload["type"]
    if token_type == "refresh" and not payload.get("jti"):
        raise _auth_error("INVALID_TOKEN_PAYLOAD")

    return payload.get("jti")