import re

from sqlalchemy import select, desc, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlalchemy.sql import over

from Backend.Social_free.models.user import User
from Backend.Social_free.models.user_psl import UserPSL


class SocialSearchService:
    @staticmethod
    def safe_name(value: str | None) -> str:
        raw = (value or "").strip()
        cleaned = re.sub(r"[^A-Za-z0-9_]", "", raw)[:12]

        if not cleaned:
            return "User"

        return cleaned[0].upper() + cleaned[1:]

    async def list_live_users(
        self,
        db: AsyncSession,
        *,
        limit: int = 30,
        offset: int = 0,
    ) -> list[dict]:
        limit = max(1, min(limit, 50))
        offset = max(0, offset)

        result = await db.execute(
            select(User)
            .options(selectinload(User.stats))
            .where(User.is_live.is_(True))
            .order_by(desc(User.created_at), desc(User.id))
            .offset(offset)
            .limit(limit)
        )

        users = result.scalars().all()

        if not users:
            return []

        user_ids = [u.id for u in users]

        latest_psl_subq = (
            select(
                UserPSL.user_id.label("user_id"),
                UserPSL.psl_score.label("psl_score"),
                UserPSL.tier.label("tier"),
                UserPSL.percentile.label("percentile"),
                UserPSL.confidence.label("confidence"),
                over(
                    func.row_number(),
                    partition_by=UserPSL.user_id,
                    order_by=UserPSL.created_at.desc(),
                ).label("rn"),
            )
            .where(UserPSL.user_id.in_(user_ids))
            .subquery()
        )

        psl_result = await db.execute(
            select(latest_psl_subq).where(latest_psl_subq.c.rn == 1)
        )

        psl_by_user_id: dict[int, dict] = {}

        for row in psl_result.mappings().all():
            psl_by_user_id[int(row["user_id"])] = {
                "psl_score": row["psl_score"] or 0,
                "tier": row["tier"] or "",
                "percentile": row["percentile"] or 0,
                "confidence": row["confidence"] or 0.0,
            }

        items: list[dict] = []

        for user in users:
            stats = user.stats
            image = user.profile_image_url or ""

            latest_psl = psl_by_user_id.get(user.id)

            fallback_percentile = (
                getattr(user, "reach_target_percentile", 0) or 0
            )

            percentile = (
                latest_psl["percentile"]
                if latest_psl and latest_psl.get("percentile")
                else fallback_percentile
            )

            psl_score = (
                latest_psl["psl_score"]
                if latest_psl and latest_psl.get("psl_score")
                else 0
            )

            psl_payload = latest_psl or {
                "psl_score": psl_score,
                "tier": "",
                "percentile": percentile,
                "confidence": 0.0,
            }

            items.append(
                {
                    "id": user.id,
                    "username": self.safe_name(user.username),
                    "display_name": self.safe_name(user.username),
                    "profile_image_url": image,
                    "image": image,

                    "followers": stats.followers_count if stats else 0,
                    "following": stats.following_count if stats else 0,
                    "matches": getattr(stats, "matches_count", 0) if stats else 0,

                    "is_live": bool(user.is_live),

                    "reach_target_percentile": percentile,
                    "percentile": percentile,
                    "psl_score": psl_score,
                    "psl": psl_payload,
                }
            )

        return items

    async def list_live_users_page(
        self,
        db: AsyncSession,
        *,
        limit: int = 30,
        offset: int = 0,
    ) -> dict:
        limit = max(1, min(limit, 50))
        offset = max(0, offset)

        items = await self.list_live_users(
            db=db,
            limit=limit,
            offset=offset,
        )

        return {
            "items": items,
            "has_more": len(items) == limit,
            "next_offset": offset + len(items),
            "count": len(items),
        }