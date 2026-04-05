import os
import redis
import logging

logger = logging.getLogger(__name__)

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=REDIS_DB,
    decode_responses=True,
)

# =========================
# SAFE WRAPPERS (NE RUŠI APP)
# =========================

def safe_get(key: str):
    try:
        return redis_client.get(key)
    except Exception as e:
        logger.error(f"[REDIS GET ERROR] {e}")
        return None


def safe_set(key: str, value: str, ex: int | None = None):
    try:
        redis_client.set(key, value, ex=ex)
    except Exception as e:
        logger.error(f"[REDIS SET ERROR] {e}")


def safe_delete(key: str):
    try:
        redis_client.delete(key)
    except Exception as e:
        logger.error(f"[REDIS DELETE ERROR] {e}")


def redis_ping() -> bool:
    try:
        return redis_client.ping()
    except Exception:
        return False