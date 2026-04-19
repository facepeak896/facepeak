from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import json
import logging

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.token_service import decode_token
from Backend.Social_free.models.user import User
from Backend.Social_free.redis import redis_client

logger = logging.getLogger(__name__)

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
):
    token = credentials.credentials

    try:
        payload = decode_token(token)
    except:
        raise HTTPException(401, "INVALID_TOKEN")

    if payload.get("type") != "access":
        raise HTTPException(401, "INVALID_TOKEN_TYPE")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(401, "INVALID_TOKEN_PAYLOAD")

    try:
        user_id = int(user_id)
    except:
        raise HTTPException(401, "INVALID_TOKEN_PAYLOAD")

    cache_key = f"user:{user_id}"

    # 🔥 CACHE FIRST (RETURN EARLY)
    try:
        cached = redis_client.get(cache_key)
        if cached:
            data = json.loads(cached)

            if not data.get("is_active", True):
                raise HTTPException(403, "USER_INACTIVE")

            if data.get("is_banned", False):
                raise HTTPException(403, "USER_BANNED")

            return data  # 🔥 RETURN FROM CACHE
    except:
        pass

    # 🔥 DB FALLBACK
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
    except:
        pass

    return user_data