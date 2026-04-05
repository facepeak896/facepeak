# Backend/services/auth/email_service.py

from fastapi import HTTPException
from starlette.concurrency import run_in_threadpool
from pydantic import EmailStr
import resend
import os
from dotenv import load_dotenv
import logging
import asyncio
import time

from Backend.Social_free.redis import redis_client

load_dotenv()

logger = logging.getLogger(__name__)

RESEND_API_KEY = os.getenv("RESEND_API_KEY")

if not RESEND_API_KEY:
    raise RuntimeError("RESEND_API_KEY nije postavljen")

resend.api_key = RESEND_API_KEY


# =========================
# CONFIG
# =========================

BASE_URL = os.getenv("BASE_URL", "http://localhost:8000")
FROM_EMAIL = os.getenv("FROM_EMAIL", "noreply@yourdomain.com")

EMAIL_WINDOW = 300  # 5 min
EMAIL_LIMIT = 3     # per email
IP_LIMIT = 10       # per IP


# =========================
# VALIDATION
# =========================

def normalize_email(email: str) -> str:
    return email.lower().strip()


def validate_email_input(email: str):
    try:
        EmailStr(email)
    except Exception:
        raise HTTPException(400, "INVALID_EMAIL")


# =========================
# 🔥 RATE LIMIT (EMAIL + IP)
# =========================

def check_email_limit(email: str, ip: str):
    try:
        now = int(time.time()) // EMAIL_WINDOW

        # EMAIL LIMIT
        email_key = f"email:limit:{email}:{now}"
        email_count = redis_client.incr(email_key)

        if email_count == 1:
            redis_client.expire(email_key, EMAIL_WINDOW)

        if email_count > EMAIL_LIMIT:
            raise HTTPException(429, "TOO_MANY_EMAIL_REQUESTS")

        # IP LIMIT
        ip_key = f"email:ip:{ip}:{now}"
        ip_count = redis_client.incr(ip_key)

        if ip_count == 1:
            redis_client.expire(ip_key, EMAIL_WINDOW)

        if ip_count > IP_LIMIT:
            raise HTTPException(429, "TOO_MANY_REQUESTS_FROM_IP")

    except HTTPException:
        raise
    except Exception as e:
        logger.warning(f"[EMAIL LIMIT FAIL] {e}")
        return  # fail-safe


# =========================
# CORE SEND (ASYNC SAFE)
# =========================

async def send_email(payload: dict):
    try:
        return await run_in_threadpool(resend.Emails.send, payload)
    except Exception:
        logger.exception("EMAIL SEND FAILED")
        return None


# =========================
# BACKGROUND WRAPPER
# =========================

def send_email_background(payload: dict):
    try:
        asyncio.create_task(send_email(payload))
    except Exception as e:
        logger.warning(f"[EMAIL BG FAIL] {e}")


# =========================
# VERIFY EMAIL
# =========================

async def send_verification_email(email: str, token: str, ip: str):
    email = normalize_email(email)
    validate_email_input(email)

    # 🔥 FULL PROTECTION
    check_email_limit(email, ip)

    verify_link = f"{BASE_URL}/api/v1/auth/verify-email?token={token}"

    payload = {
        "from": FROM_EMAIL,
        "to": email,
        "subject": "Verify your account",
        "html": f"""
            <h2>Verify your account</h2>
            <p>Klikni link ispod:</p>
            <a href="{verify_link}">
                Verify Email
            </a>
        """
    }

    send_email_background(payload)

    return True


# =========================
# RESET PASSWORD
# =========================

async def send_reset_password_email(email: str, token: str, ip: str):
    email = normalize_email(email)
    validate_email_input(email)

    # 🔥 FULL PROTECTION
    check_email_limit(email, ip)

    reset_link = f"{BASE_URL}/reset-password?token={token}"

    payload = {
        "from": FROM_EMAIL,
        "to": email,
        "subject": "Reset your password",
        "html": f"""
            <h2>Reset Password</h2>
            <p>Klikni link ispod:</p>
            <a href="{reset_link}">
                Reset Password
            </a>
        """
    }

    send_email_background(payload)

    return True