import os
import logging
import asyncio
import firebase_admin

from firebase_admin import auth, credentials

logger = logging.getLogger(__name__)

FIREBASE_CRED_PATH = os.getenv("FIREBASE_CREDENTIALS")

if not FIREBASE_CRED_PATH:
    raise RuntimeError("FIREBASE_CREDENTIALS not set")

try:
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate(FIREBASE_CRED_PATH)
    firebase_admin.initialize_app(cred)


async def verify_firebase_token(id_token: str) -> dict:
    try:
        return await asyncio.to_thread(auth.verify_id_token, id_token)
    except Exception as e:
        logger.warning(f"[FIREBASE VERIFY FAIL] {e}")
        raise Exception("INVALID_FIREBASE_TOKEN")