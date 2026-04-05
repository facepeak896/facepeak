import time
import uuid
from typing import Any, Dict, Optional


class TTLCache:
    def __init__(self, default_ttl: int = 300):
        self.default_ttl = default_ttl
        self._store: Dict[str, Dict[str, Any]] = {}

    def put(self, value: Any, ttl: Optional[int] = None) -> str:
        analysis_id = uuid.uuid4().hex
        self._store[analysis_id] = {
            "t": time.time(),
            "ttl": ttl if ttl is not None else self.default_ttl,
            "v": value,
        }
        return analysis_id

    def get(self, analysis_id: str) -> Optional[Any]:
        item = self._store.get(analysis_id)
        if not item:
            return None

        if time.time() - item["t"] > item["ttl"]:
            self._store.pop(analysis_id, None)
            return None

        return item["v"]

    def update(self, analysis_id: str, value: Any) -> bool:
        if analysis_id not in self._store:
            return False
        self._store[analysis_id]["v"] = value
        return True

    def delete(self, analysis_id: str) -> None:
        self._store.pop(analysis_id, None)


cache = TTLCache(default_ttl=300)