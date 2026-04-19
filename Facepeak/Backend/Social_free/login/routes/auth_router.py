from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
import logging
import json
import time

# DB
from Backend.Social_free.login.database import get_db

# AUTH
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.login.token_service import (
    create_access_token,
    create_refresh_token,
    decode_token,
)
from Backend.Social_free.login.auth_service import generate_jti

# MODELS
from Backend.Social_free.models.user import User

# SERVICES
from Backend.Social_free.services.user_service import UserService

# GOOGLE
from Backend.Social_free.login.google_verify import verify_firebase_token

# RATE LIMIT
from Backend.Social_free.auth_protection import protect_google_auth

# REDIS (ASYNC)
from Backend.Social_free.redis import safe_set, safe_getdel, safe_delete

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Auth"])

user_service = UserService()


# =========================
# SCHEMAS
# =========================

class GoogleAuthBody(BaseModel):
    id_token: str


class RefreshBody(BaseModel):
    refresh_token: str


# =========================
# 🔥 GOOGLE AUTH
# =========================

@router.post("/google")
async def google_auth(
    body: GoogleAuthBody,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    try:
        protect_google_auth(request)

        try:
            decoded = await verify_firebase_token(body.id_token)
        except Exception:
            raise HTTPException(401, "INVALID_GOOGLE_TOKEN")

        email = decoded.get("email")
        google_id = decoded.get("sub")

        if not email or not google_id:
            raise HTTPException(400, "INVALID_GOOGLE_PAYLOAD")

        user = await user_service.get_or_create_google_user(
            db=db,
            email=email,
            google_id=google_id,
        )

        jti = generate_jti()

        access = create_access_token(user.id)
        refresh = create_refresh_token(user.id, jti=jti)

        # 🔥 ASYNC REDIS
        await safe_set(
            f"refresh:{jti}",
            json.dumps({
                "user_id": user.id,
                "created_at": int(time.time()),
            }),
            ex=60 * 60 * 24 * 7
        )

        return {
            "status": "success",
            "access_token": access,
            "refresh_token": refresh,
            "user_id": user.id,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"[GOOGLE AUTH ERROR] {e}")
        raise HTTPException(500, "GOOGLE_AUTH_FAILED")


# =========================
# 🔥 REFRESH (ATOMIC ASYNC)
# =========================

@router.post("/refresh")
async def refresh(body: RefreshBody):
    try:
        payload = decode_token(body.refresh_token)

        if payload.get("type") != "refresh":
            raise HTTPException(401, "INVALID_TOKEN_TYPE")

        user_id = int(payload.get("sub"))
        jti = payload.get("jti")

        if not jti:
            raise HTTPException(401, "INVALID_TOKEN")

        # 🔥 ATOMIC ASYNC
        stored = await safe_getdel(f"refresh:{jti}")

        if not stored:
            raise HTTPException(401, "SESSION_EXPIRED")

        try:
            session_data = json.loads(stored)
        except Exception:
            raise HTTPException(401, "INVALID_SESSION")

        if session_data.get("user_id") != user_id:
            raise HTTPException(401, "INVALID_SESSION_OWNER")

        # 🔥 ROTATE
        new_jti = generate_jti()

        access = create_access_token(user_id)
        new_refresh = create_refresh_token(user_id, jti=new_jti)

        await safe_set(
            f"refresh:{new_jti}",
            json.dumps({
                "user_id": user_id,
                "created_at": int(time.time()),
            }),
            ex=60 * 60 * 24 * 7
        )

        return {
            "status": "success",
            "access_token": access,
            "refresh_token": new_refresh,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"[REFRESH ERROR] {e}")
        raise HTTPException(500, "REFRESH_FAILED")


# =========================
# 🔥 LOGOUT
# =========================

@router.post("/logout")
async def logout(body: RefreshBody):
    try:
        payload = decode_token(body.refresh_token)
        jti = payload.get("jti")

        if jti:
            await safe_delete(f"refresh:{jti}")

        return {"status": "success"}

    except Exception as e:
        logger.exception(f"[LOGOUT ERROR] {e}")
        return {"status": "success"}


# =========================
# 🔥 GET ME
# =========================

@router.get("/me")
async def get_me(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return await user_service.get_full_user_snapshot(
            db,
            current_user.id,
        )

    except Exception as e:
        logger.exception(f"[GET ME ERROR] {e}")
        raise HTTPException(500, "GET_ME_FAILED")