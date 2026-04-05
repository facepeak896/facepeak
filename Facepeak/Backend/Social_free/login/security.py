from jose import jwt, JWTError
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import os
import json
import logging

from Backend.Social_free.login.database import get_db
from Backend.Social_free.models.user import User
from Backend.Social_free.redis import redis_client

logger = logging.getLogger(__name__)

SECRET_KEY = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"

if not SECRET_KEY:
    raise RuntimeError("JWT_SECRET not set")

security = HTTPBearer()


def decode_token(token: str):
    try:
        return jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM],
            options={"verify_exp": True}
        )
    except JWTError:
        raise HTTPException(401, "INVALID_TOKEN")


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
):
    token = credentials.credentials
    payload = decode_token(token)

    # 🔥 TYPE CHECK
    if payload.get("type") != "access":
        raise HTTPException(401, "INVALID_TOKEN_TYPE")

    user_id = payload.get("sub")

    if not user_id:
        raise HTTPException(401, "INVALID_TOKEN_PAYLOAD")

    cache_key = f"user:{user_id}"

    # =========================
    # 🔥 CACHE CHECK (ONLY VALIDATION)
    # =========================
    try:
        cached = redis_client.get(cache_key)

        if cached:
            data = json.loads(cached)

            if not data.get("is_active", True):
                raise HTTPException(403, "USER_INACTIVE")

            if data.get("is_banned", False):
                raise HTTPException(403, "USER_BANNED")

    except Exception as e:
        logger.warning(f"[CACHE FAIL] {e}")

    # =========================
    # 🔥 DB (SOURCE OF TRUTH)
    # =========================
    try:
        result = await db.execute(
            select(User).where(User.id == int(user_id))
        )
        user = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"[DB ERROR] {e}")
        raise HTTPException(500, "DATABASE_ERROR")

    if not user:
        raise HTTPException(404, "USER_NOT_FOUND")

    if not user.is_active:
        raise HTTPException(403, "USER_INACTIVE")

    if getattr(user, "is_banned", False):
        raise HTTPException(403, "USER_BANNED")

    # =========================
    # 🔥 CACHE WRITE
    # =========================
    user_data = {
        "id": user.id,
        "email": user.email,
        "username": user.username,
        "bio": user.bio,
        "is_active": user.is_active,
        "is_banned": getattr(user, "is_banned", False),
    }

    try:
        redis_client.set(cache_key, json.dumps(user_data), ex=120)
    except Exception as e:
        logger.warning(f"[CACHE WRITE FAIL] {e}")

    # 🔥 CRITICAL FIX
    return user