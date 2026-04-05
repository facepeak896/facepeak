from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from models.user_stats import UserStats
from models.profile_view import ProfileView
from models.user import User


class AnalyticsService:

    # =========================================================
    # GET ANALYTICS
    # =========================================================
    async def get_analytics(self, db: AsyncSession, user_id: int):

        # 🔹 STATS
        stats_result = await db.execute(
            select(UserStats).where(UserStats.user_id == user_id)
        )
        stats = stats_result.scalar_one_or_none()

        profile_views = stats.profile_views_count if stats else 0
        matches = getattr(stats, "matches_count", 0) if stats else 0

        # 🔹 RECENT VIEWS (last 10)
        views_result = await db.execute(
            select(ProfileView)
            .where(ProfileView.target_id == user_id)
            .order_by(desc(ProfileView.created_at))
            .limit(10)
        )

        views = views_result.scalars().all()

        # 🔹 MAP TO USER DATA
        recent_viewers = []

        for v in views:
            user_result = await db.execute(
                select(User).where(User.id == v.viewer_id)
            )
            viewer = user_result.scalar_one_or_none()

            if viewer:
                recent_viewers.append({
                    "id": viewer.id,
                    "username": viewer.username,
                    "image": viewer.image,
                    "viewed_at": v.created_at
                })

        # 🔹 STATUS MESSAGE
        message = self._build_message(profile_views)

        return {
            "profile_views": profile_views,
            "matches": matches,
            "recent_viewers": recent_viewers,
            "message": message
        }

    # =========================================================
    # STATUS MESSAGE (PSYCHOLOGY)
    # =========================================================
    def _build_message(self, views: int):

        if views == 0:
            return "No one has seen your profile yet"

        if views < 10:
            return "Your profile is starting to get attention"

        if views < 50:
            return "People are checking you out"

        if views < 200:
            return "You're getting noticed"

        return "Your profile is trending 🔥"