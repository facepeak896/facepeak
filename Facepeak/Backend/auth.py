# auth.py
from __future__ import annotations

from typing import Optional, Dict, Any
from fastapi import Header, HTTPException

# ============================================================
# TYPES
# ============================================================

User = Dict[str, Any]

# ============================================================
# CONFIG (JWT READY)
# ============================================================

JWT_ALGORITHM = "HS256"
JWT_ISSUER = "facepeak"
JWT_AUDIENCE = "facepeak-app"

# Secret ćeš kasnije držati u ENV varijabli
JWT_SECRET: Optional[str] = None  # e.g. os.getenv("JWT_SECRET")


# ============================================================
# TOKEN PARSING
# ============================================================

def _parse_bearer_token(auth_header: Optional[str]) -> Optional[str]:
    if not auth_header:
        return None

    if not auth_header.startswith("Bearer "):
        return None

    token = auth_header.split(" ", 1)[1].strip()
    return token or None   # 👈 polish: reject empty token


# ============================================================
# TOKEN VERIFICATION (JWT STUB)
# ============================================================

def _verify_token(token: str) -> Optional[User]:
    """
    JWT-ready verification.

    CURRENT (V2):
    - token is treated as user_id (safe stub)

    LATER (JWT):
    - decode JWT
    - verify signature
    - verify exp / iss / aud
    - extract user_id + claims
    """

    # ---------- STUB MODE ----------
    if JWT_SECRET is None:
        return {
            "id": token,
            "is_premium": False,
        }

    # ---------- JWT MODE (LATER) ----------
    # import jwt
    # try:
    #     payload = jwt.decode(
    #         token,
    #         JWT_SECRET,
    #         algorithms=[JWT_ALGORITHM],
    #         audience=JWT_AUDIENCE,
    #         issuer=JWT_ISSUER,
    #     )
    # except jwt.PyJWTError:
    #     return None
    #
    # return {
    #     "id": payload["sub"],
    #     "is_premium": payload.get("is_premium", False),
    # }


# ============================================================
# FASTAPI DEPENDENCY
# ============================================================

def get_current_user(
    authorization: Optional[str] = Header(default=None),
) -> Optional[User]:
    """
    Returns:
    - user dict if authenticated
    - None if guest
    """

    token = _parse_bearer_token(authorization)

    # Guest allowed
    if not token:
        return None

    user = _verify_token(token)

    if not user:
        raise HTTPException(status_code=401, detail="INVALID_TOKEN")

    return user