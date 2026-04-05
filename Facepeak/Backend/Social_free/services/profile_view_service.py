from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, case
from datetime import datetime, timedelta

from models.profile_view import ProfileView
from models.profile_stats import ProfileStats
from models.user import User


class ProfileViewService:

    VIEW_COOLDOWN_MINUTES = 10

    # =========================
    # ADD VIEW (FINAL)
    # =========================
    async def add_view(
        self,
        db: AsyncSession,
        viewer_id: int,
        target_id: int,
    ):
        # ❌ SELF VIEW
        if viewer_id == target_id:
            return {"status": "ignored", "reason": "SELF_VIEW"}

        now = datetime.utcnow()
        cooldown_time = now - timedelta(minutes=self.VIEW_COOLDOWN_MINUTES)

        # 🔍 CHECK RECENT VIEW (ANTI-SPAM)
        result = await db.execute(
            select(ProfileView.created_at).where(
                ProfileView.viewer_id == viewer_id,
                ProfileView.viewed_id == target_id,
                ProfileView.created_at >= cooldown_time
            )
        )

        if result.scalar_one_or_none():
            return {"status": "ignored", "reason": "COOLDOWN"}

        # 🔥 CREATE RAW EVENT
        db.add(ProfileView(
            viewer_id=viewer_id,
            viewed_id=target_id,
        ))

        # =========================
        # 📊 GET OR CREATE STATS
        # =========================
        stats = await db.get(ProfileStats, target_id)

        if not stats:
            stats = ProfileStats(user_id=target_id)
            db.add(stats)
            await db.flush()

        # =========================
        # 🧠 DAILY RESET (FIXED)
        # =========================
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

        is_new_day = stats.last_updated is None or stats.last_updated < today_start

        if is_new_day:
            stats.daily_views = 0
            stats.unique_daily_views = 0

        # =========================
        # 🧠 UNIQUE DAILY CHECK
        # =========================
        unique_today_result = await db.execute(
            select(ProfileView.id).where(
                ProfileView.viewer_id == viewer_id,
                ProfileView.viewed_id == target_id,
                ProfileView.created_at >= today_start
            )
        )

        is_unique_today = unique_today_result.scalar_one_or_none() is None

        # =========================
        # ⚡ UPDATE STATS
        # =========================
        stats.total_views += 1
        stats.daily_views += 1

        if is_unique_today:
            stats.unique_daily_views += 1

        # =========================
        # ⚡ UPDATE USER COUNTER (SAFE)
        # =========================
        await db.execute(
            update(User)
            .where(User.id == target_id)
            .values(
                profile_views_count=User.profile_views_count + 1
            )
        )

        await db.commit()

        return {
            "status": "success",
            "delta": +1,
            "target_id": target_id,
            "unique": is_unique_today
        }

    # =========================
    # GET PROFILE STATS
    # =========================
    async def get_stats(
        self,
        db: AsyncSession,
        user_id: int,
    ):
        stats = await db.get(ProfileStats, user_id)

        if not stats:
            return {
                "total_views": 0,
                "daily_views": 0,
                "unique_daily_views": 0
            }

        return {
            "total_views": stats.total_views,
            "daily_views": stats.daily_views,
            "unique_daily_views": stats.unique_daily_views
        }

    # =========================
    # SAFE SILENT (NO CRASH)
    # =========================
    async def add_view_silent(
        self,
        db: AsyncSession,
        viewer_id: int,
        target_id: int,
    ):
        try:
            await self.add_view(db, viewer_id, target_id)
        except Exception:
            pass

    # =========================
    # CHECK CAN VIEW
    # =========================
    async def can_add_view(
        self,
        db: AsyncSession,
        viewer_id: int,
        target_id: int,
    ):
        if viewer_id == target_id:
            return False

        now = datetime.utcnow()
        cooldown_time = now - timedelta(minutes=self.VIEW_COOLDOWN_MINUTES)

        result = await db.execute(
            select(ProfileView.id).where(
                ProfileView.viewer_id == viewer_id,
                ProfileView.viewed_id == target_id,
                ProfileView.created_at >= cooldown_time
            )
        )

        return result.scalar_one_or_none() is None