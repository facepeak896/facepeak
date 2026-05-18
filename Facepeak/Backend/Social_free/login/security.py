from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import json
import logging
import re

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.token_service import decode_token
from Backend.Social_free.models.user import User
from Backend.Social_free.redis import safe_get, safe_set

logger = logging.getLogger(__name__)

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
):
    token = credentials.credentials if credentials else None

    try:
        payload = decode_token(token)
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(401, "INVALID_TOKEN")

    if payload.get("type") != "access":
        raise HTTPException(401, "INVALID_TOKEN_TYPE")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(401, "INVALID_TOKEN_PAYLOAD")

    try:
        user_id = int(user_id)
    except Exception:
        raise HTTPException(401, "INVALID_TOKEN_PAYLOAD")

    cache_key = f"user:{user_id}"

    try:
        cached = await safe_get(cache_key)
        if cached:
            data = json.loads(cached)

            if not data.get("is_active", True):
                raise HTTPException(403, "USER_INACTIVE")

            if data.get("is_banned", False):
                raise HTTPException(403, "USER_BANNED")
    except HTTPException:
        raise
    except Exception as e:
        logger.warning(f"[SECURITY CACHE READ FAIL] {e}")

    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(404, "USER_NOT_FOUND")

    if not user.is_active:
        raise HTTPException(403, "USER_INACTIVE")

    if getattr(user, "is_banned", False):
        raise HTTPException(403, "USER_BANNED")

    raw_username = getattr(user, "username", None)

    if raw_username:
        cleaned_username = re.sub(r"[^A-Za-z]", "", raw_username.strip())[:8]
        username = (
            cleaned_username[0].upper() + cleaned_username[1:].lower()
            if cleaned_username
            else "User"
        )
    else:
        username = "User"

    user_data = {
        "id": user.id,
        "email": user.email,
        "google_id": getattr(user, "google_id", None),
        "username": username,
        "bio": user.bio,
        "is_active": user.is_active,
        "is_banned": getattr(user, "is_banned", False),
    }

    try:
        await safe_set(cache_key, json.dumps(user_data), ex=120)
    except Exception as e:
        logger.warning(f"[SECURITY CACHE WRITE FAIL] {e}")

    return user