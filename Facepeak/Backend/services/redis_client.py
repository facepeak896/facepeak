import os
import redis

# =====================================================
# REDIS CONFIG
# =====================================================

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))

# =====================================================
# REDIS CLIENT (SINGLETON)
# =====================================================

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=REDIS_DB,
    decode_responses=True,  # vraca stringove umjesto bytes
)

# =====================================================
# OPTIONAL: HEALTH CHECK
# =====================================================

def redis_ping() -> bool:
    try:
        return redis_client.ping()
    except Exception:
        return False


# =====================================================
# 🔥 DODAJ OVO (NE DIRAJ OSTALO)
# =====================================================

def get_redis():
    return redis_client