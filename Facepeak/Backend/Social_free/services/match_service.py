from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timedelta

from models.match_request import MatchRequest
from models.match_table import Match
from models.user_stats import UserStats


class MatchService:

    COOLDOWN_SECONDS = 5

    async def send_match(
        self,
        db: AsyncSession,
        sender_id: int,
        receiver_id: int,
    ):
        # ❌ SELF MATCH
        if sender_id == receiver_id:
            return {"error": "invalid_action"}

        # 🔒 ORDER (bitno za Match table)
        user1_id = min(sender_id, receiver_id)
        user2_id = max(sender_id, receiver_id)

        # =========================================================
        # 1. CHECK: već postoji match (idempotent)
        # =========================================================
        existing_match = await db.execute(
            select(Match).where(
                and_(
                    Match.user1_id == user1_id,
                    Match.user2_id == user2_id,
                )
            )
        )
        if existing_match.scalar_one_or_none():
            return {"status": "already_matched"}

        # =========================================================
        # 2. COOLDOWN (anti spam)
        # =========================================================
        recent = await db.execute(
            select(MatchRequest).where(
                and_(
                    MatchRequest.sender_id == sender_id,
                    MatchRequest.receiver_id == receiver_id,
                    MatchRequest.created_at >= datetime.utcnow() - timedelta(seconds=self.COOLDOWN_SECONDS),
                )
            )
        )
        if recent.scalar_one_or_none():
            return {"status": "cooldown"}

        # =========================================================
        # 3. CHECK REVERSE REQUEST (auto match)
        # =========================================================
        reverse = await db.execute(
            select(MatchRequest).where(
                and_(
                    MatchRequest.sender_id == receiver_id,
                    MatchRequest.receiver_id == sender_id,
                    MatchRequest.status == "pending",
                )
            )
        )
        reverse = reverse.scalar_one_or_none()

        if reverse:
            reverse.status = "accepted"

            new_match = Match(
                user1_id=user1_id,
                user2_id=user2_id,
            )
            db.add(new_match)

            # 🔥 update stats za oba usera
            await self._increment_matches(db, sender_id)
            await self._increment_matches(db, receiver_id)

            await db.commit()

            return {"status": "matched"}

        # =========================================================
        # 4. CHECK SAME DIRECTION
        # =========================================================
        existing = await db.execute(
            select(MatchRequest).where(
                and_(
                    MatchRequest.sender_id == sender_id,
                    MatchRequest.receiver_id == receiver_id,
                )
            )
        )
        existing = existing.scalar_one_or_none()

        if existing:
            return {"status": existing.status}

        # =========================================================
        # 5. CREATE NEW REQUEST
        # =========================================================
        new_request = MatchRequest(
            sender_id=sender_id,
            receiver_id=receiver_id,
            status="pending",
        )

        db.add(new_request)
        await db.commit()

        return {"status": "pending"}

    # =========================================================
    # LIST MATCHES
    # =========================================================
    async def get_matches(self, db: AsyncSession, user_id: int):
        result = await db.execute(
            select(Match).where(
                (Match.user1_id == user_id) |
                (Match.user2_id == user_id)
            )
        )

        matches = result.scalars().all()

        return matches

    # =========================================================
    # HELPER: UPDATE STATS
    # =========================================================
    async def _increment_matches(self, db: AsyncSession, user_id: int):
        stats = await db.execute(
            select(UserStats).where(UserStats.user_id == user_id)
        )
        stats = stats.scalar_one_or_none()

        if stats:
            stats.matches_count = (stats.matches_count or 0) + 1