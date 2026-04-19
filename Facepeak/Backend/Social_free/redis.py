import os
import logging
import redis.asyncio as redis

logger = logging.getLogger(__name__)

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=REDIS_DB,
    decode_responses=True,
    max_connections=100,            # 🔥 više za concurrency
    socket_timeout=2,
    socket_connect_timeout=2,
)

# =========================
# SAFE WRAPPERS (ASYNC)
# =========================

async def safe_get(key: str):
    try:
        return await redis_client.get(key)
    except Exception as e:
        logger.error(f"[REDIS GET ERROR] {e}")
        return None


async def safe_set(key: str, value: str, ex: int | None = None):
    try:
        await redis_client.set(key, value, ex=ex)
    except Exception as e:
        logger.error(f"[REDIS SET ERROR] {e}")


async def safe_delete(key: str):
    try:
        await redis_client.delete(key)
    except Exception as e:
        logger.error(f"[REDIS DELETE ERROR] {e}")


# =========================
# 🔥 ATOMIC GETDEL
# =========================

async def safe_getdel(key: str):
    try:
        return await redis_client.execute_command("GETDEL", key)
    except Exception as e:
        logger.error(f"[REDIS GETDEL ERROR] {e}")
        return None


async def redis_ping() -> bool:
    try:
        return await redis_client.ping()
    except Exception:
        return False