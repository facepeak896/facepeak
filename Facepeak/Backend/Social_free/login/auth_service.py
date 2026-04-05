from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException
from datetime import datetime, timedelta
import uuid
import hashlib

# MODELS
from Backend.Social_free.models.user import User
from Backend.Social_free.models.user_stats import UserStats

# SERVICES
from Backend.Social_free.login.password_service import (
    hash_password,
    verify_password,
)

from Backend.Social_free.login.token_service import (
    create_access_token,
    create_refresh_token,
    decode_token,
)

from Backend.Social_free.login.email_service import (
    send_reset_password_email,
)

from Backend.Social_free.redis import safe_set, safe_get, safe_delete


# =========================
# CONFIG
# =========================

REFRESH_TTL = 60 * 60 * 24 * 7


# =========================
# HELPERS
# =========================

def normalize_email(email: str) -> str:
    return email.lower().strip()


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def generate_jti():
    return str(uuid.uuid4())


# =========================
# SIGNUP
# =========================

async def signup_user(email: str, username: str, password: str, db: AsyncSession):

    email = normalize_email(email)

    if not email:
        raise HTTPException(400, "EMAIL_REQUIRED")

    if not username:
        raise HTTPException(400, "USERNAME_REQUIRED")

    if not password:
        raise HTTPException(400, "PASSWORD_REQUIRED")

    if len(password.encode("utf-8")) > 72:
        raise HTTPException(400, "PASSWORD_TOO_LONG")

    result = await db.execute(select(User).where(User.email == email))
    if result.scalar_one_or_none():
        raise HTTPException(400, "EMAIL_ALREADY_EXISTS")

    result = await db.execute(select(User).where(User.username == username))
    if result.scalar_one_or_none():
        raise HTTPException(400, "USERNAME_TAKEN")

    user = User(
        email=email,
        username=username,
        password_hash=hash_password(password),
        is_private=True,
    )

    db.add(user)
    await db.flush()

    db.add(UserStats(user_id=user.id))

    await db.commit()
    await db.refresh(user)

    # SESSION
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
        "user_id": user.id
    }


# =========================
# LOGIN
# =========================

async def login_user(email: str, password: str, db: AsyncSession):

    email = normalize_email(email)

    if not email or not password:
        raise HTTPException(400, "INVALID_CREDENTIALS")

    if len(password.encode("utf-8")) > 72:
        raise HTTPException(400, "INVALID_CREDENTIALS")

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(400, "INVALID_CREDENTIALS")

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
        "user_id": user.id
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


# =========================
# PASSWORD RESET
# =========================

async def request_password_reset(email: str, db: AsyncSession):

    email = normalize_email(email)

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user:
        return {"status": "success"}

    raw_token = str(uuid.uuid4())
    hashed = hash_token(raw_token)

    user.reset_password_token = hashed
    user.reset_password_expires = datetime.utcnow() + timedelta(minutes=15)

    await db.commit()

    send_reset_password_email(email, raw_token)

    return {
        "status": "success",
        "message": "RESET_EMAIL_SENT"
    }


async def reset_password(token: str, new_password: str, db: AsyncSession):

    hashed = hash_token(token)

    result = await db.execute(
        select(User).where(User.reset_password_token == hashed)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(400, "INVALID_TOKEN")

    if user.reset_password_expires < datetime.utcnow():
        raise HTTPException(400, "TOKEN_EXPIRED")

    user.password_hash = hash_password(new_password)
    user.reset_password_token = None
    user.reset_password_expires = None

    await db.commit()

    return {
        "status": "success",
        "message": "PASSWORD_RESET_SUCCESS"
    }