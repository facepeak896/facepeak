from __future__ import annotations

import json
import uuid
from typing import Optional, Dict, Any

import redis


redis_client = redis.Redis(
    host="localhost",
    port=6379,
    db=1,
    decode_responses=True,
)


class AnalysisCache:

    def put(self, payload: Dict[str, Any], ttl: Optional[int] = None) -> str:
        analysis_id = str(uuid.uuid4())

        if ttl:
            redis_client.setex(
                analysis_id,
                ttl,
                json.dumps(payload),
            )
        else:
            redis_client.set(
                analysis_id,
                json.dumps(payload),
            )

        return analysis_id

    def get(self, analysis_id: str) -> Optional[Dict[str, Any]]:
        raw = redis_client.get(analysis_id)

        if not raw:
            return None

        try:
            return json.loads(raw)
        except Exception:
            return None

    def update(self, analysis_id: str, payload: Dict[str, Any]) -> bool:
        if not redis_client.exists(analysis_id):
            return False

        redis_client.set(
            analysis_id,
            json.dumps(payload),
        )

        return True


cache = AnalysisCache()