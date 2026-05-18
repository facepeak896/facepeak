import re

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from Backend.Social_free.models.user import User


class SocialUserProfileService:
    @staticmethod
    def safe_name(value: str | None) -> str:
        raw = (value or "").strip()
        cleaned = re.sub(r"[^A-Za-z0-9_]", "", raw)[:12]

        if not cleaned:
            return "User"

        return cleaned[0].upper() + cleaned[1:]

    async def get_public_profile(
        self,
        db: AsyncSession,
        *,
        user_id: int,
    ) -> dict | None:
        result = await db.execute(
            select(User)
            .options(selectinload(User.stats))
            .where(User.id == user_id)
        )

        user = result.scalar_one_or_none()

        if not user:
            return None

        stats = user.stats
        image = user.profile_image_url or ""
        percentile = user.reach_target_percentile or 50

        return {
            "id": user.id,
            "username": self.safe_name(user.username),
            "display_name": self.safe_name(user.username),
            "profile_image_url": image,
            "image": image,
            "followers": stats.followers_count if stats else 0,
            "following": stats.following_count if stats else 0,
            "matches": getattr(stats, "matches_count", 0) if stats else 0,
            "percentile": percentile,
            "reach_target_percentile": percentile,
            "is_live": bool(user.is_live),
        }