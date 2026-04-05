class SelectionCooldownService:
    def __init__(self, redis):
        self.redis = redis

    def _key(self, subject_id: str) -> str:
        return f"selection:window:{subject_id}"

    # =================================================
    # ▶️ START WINDOW (ON FIRST TAP)
    # Frontend zove SAMO kad krene krug
    # =================================================
    def start(self, subject_id: str, seconds: int) -> None:
        """
        Pasivan backend.
        Ako window već postoji → ne dira ništa.
        """
        if self.redis.exists(self._key(subject_id)):
            return

        self.redis.set(
            self._key(subject_id),
            "active",
            ex=seconds,
        )

    # =================================================
    # 🔍 GET STATE (READ-ONLY)
    # Frontend koristi za refresh / sync
    # =================================================
    def get(self, subject_id: str) -> dict:
        key = self._key(subject_id)

        if not self.redis.exists(key):
            return {
                "active": False,
                "remaining_seconds": 0,
            }

        ttl = self.redis.ttl(key)

        return {
            "active": True,
            "remaining_seconds": max(ttl, 0),
        }

    # =================================================
    # 🧹 RESET (WHEN TIMER ENDS)
    # Frontend zove kad krug istekne
    # =================================================
    def reset(self, subject_id: str) -> None:
        self.redis.delete(self._key(subject_id))