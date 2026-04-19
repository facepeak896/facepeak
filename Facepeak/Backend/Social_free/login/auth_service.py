from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException
import uuid
import hashlib

# FIREBASE
from firebase_admin import auth as firebase_auth

# MODELS
from Backend.Social_free.models.user import User
from Backend.Social_free.models.user_stats import UserStats

# SERVICES
from Backend.Social_free.login.token_service import (
    create_access_token,
    create_refresh_token,
    decode_token,
)

from Backend.Social_free.redis import safe_set, safe_get, safe_delete


# =========================
# CONFIG
# =========================

REFRESH_TTL = 60 * 60 * 24 * 7


# =========================
# HELPERS
# =========================

def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def generate_jti():
    return str(uuid.uuid4())


# =========================
# GOOGLE LOGIN
# =========================

async def google_login(id_token: str, db: AsyncSession):
    try:
        decoded = firebase_auth.verify_id_token(id_token)
    except Exception:
        raise HTTPException(401, "INVALID_GOOGLE_TOKEN")

    email = decoded.get("email")

    if not email:
        raise HTTPException(400, "NO_EMAIL")

    # 🔍 find user
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    # 🆕 create user if not exists
    if not user:
        username = email.split("@")[0]

        user = User(
            email=email,
            username=username,
            is_private=True,
            is_active=True,
        )

        db.add(user)
        await db.flush()

        db.add(UserStats(user_id=user.id))

        await db.commit()
        await db.refresh(user)

    # =========================
    # SESSION
    # =========================

    jti = generate_jti()

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id, jti=jti)

    try:
        safe_set(f"refresh:{jti}", hash_token(refresh_token), ex=REFRESH_TTL)
    except:
        pass

    return {
        "status": "success",
        "access_token": access_token,
        "refresh_token": refresh_token,
        "user_id": user.id,
    }


# =========================
# REFRESH
# =========================

async def refresh_user_token(refresh_token: str):

    payload = decode_token(refresh_token)

    if payload.get("type") != "refresh":
        raise HTTPException(401, "INVALID_TOKEN_TYPE")

    user_id = int(payload.get("sub"))
    jti = payload.get("jti")

    if not jti:
        raise HTTPException(401, "INVALID_REFRESH")

    stored = safe_get(f"refresh:{jti}")

    if not stored:
        raise HTTPException(401, "SESSION_EXPIRED")

    if stored != hash_token(refresh_token):
        raise HTTPException(401, "INVALID_REFRESH")

    new_jti = generate_jti()

    new_access = create_access_token(user_id)
    new_refresh = create_refresh_token(user_id, jti=new_jti)

    try:
        safe_delete(f"refresh:{jti}")
        safe_set(f"refresh:{new_jti}", hash_token(new_refresh), ex=REFRESH_TTL)
    except:
        pass

    return {
        "status": "success",
        "access_token": new_access,
        "refresh_token": new_refresh
    }


# =========================
# LOGOUT
# =========================

async def logout_user(refresh_token: str):

    payload = decode_token(refresh_token)
    jti = payload.get("jti")

    if not jti:
        return {"status": "success"}

    try:
        safe_delete(f"refresh:{jti}")
    except:
        pass

    return {
        "status": "success",
        "message": "LOGGED_OUT"
    }