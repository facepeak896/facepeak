# Backend/services/auth/password_service.py

from passlib.context import CryptContext
from fastapi import HTTPException
from starlette.concurrency import run_in_threadpool
import logging

logger = logging.getLogger(__name__)


# =========================
# HASH CONFIG
# =========================

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)


# =========================
# VALIDATION
# =========================

def validate_password(password: str):
    if not password:
        raise HTTPException(400, "PASSWORD_REQUIRED")

    if len(password) < 6:
        raise HTTPException(400, "PASSWORD_TOO_SHORT")

    if len(password.encode("utf-8")) > 72:  # 🔥 bcrypt safe limit
        raise HTTPException(400, "PASSWORD_TOO_LONG")


# =========================
# HASH PASSWORD (ASYNC SAFE)
# =========================

async def hash_password(password: str) -> str:
    validate_password(password)

    try:
        return await run_in_threadpool(pwd_context.hash, password)
    except Exception as e:
        logger.exception("HASH ERROR")
        raise HTTPException(500, "PASSWORD_HASH_FAILED")


# =========================
# VERIFY PASSWORD (ASYNC SAFE)
# =========================

async def verify_password(plain_password: str, hashed_password: str) -> bool:
    if not plain_password:
        raise HTTPException(400, "PASSWORD_REQUIRED")

    if not hashed_password:
        raise HTTPException(500, "HASH_MISSING")

    try:
        return await run_in_threadpool(
            pwd_context.verify,
            plain_password,
            hashed_password
        )
    except Exception as e:
        logger.exception("VERIFY ERROR")
        raise HTTPException(500, "PASSWORD_VERIFY_FAILED")