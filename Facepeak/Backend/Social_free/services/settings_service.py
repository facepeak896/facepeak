from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.user_settings import UserSettings
from models.user import User


class SettingsService:

    # =========================================================
    # GET SETTINGS
    # =========================================================
    async def get_settings(self, db: AsyncSession, user_id: int):
        result = await db.execute(
            select(UserSettings).where(UserSettings.user_id == user_id)
        )
        settings = result.scalar_one_or_none()

        if not settings:
            # 🆕 AUTO CREATE (importantno)
            settings = UserSettings(user_id=user_id)
            db.add(settings)
            await db.commit()
            await db.refresh(settings)

        return {
            "is_private": settings.is_private,
            "notifications_enabled": settings.notifications_enabled
        }

    # =========================================================
    # TOGGLE PRIVACY
    # =========================================================
    async def toggle_privacy(
        self,
        db: AsyncSession,
        user_id: int,
        make_public: bool
    ):
        result = await db.execute(
            select(UserSettings).where(UserSettings.user_id == user_id)
        )
        settings = result.scalar_one_or_none()

        if not settings:
            settings = UserSettings(user_id=user_id)
            db.add(settings)

        # 🔥 CORE LOGIKA
        settings.is_private = not make_public

        await db.commit()
        await db.refresh(settings)

        return {
            "status": "updated",
            "is_private": settings.is_private
        }

    # =========================================================
    # SET NOTIFICATIONS (OPTIONAL)
    # =========================================================
    async def toggle_notifications(
        self,
        db: AsyncSession,
        user_id: int,
        enabled: bool
    ):
        result = await db.execute(
            select(UserSettings).where(UserSettings.user_id == user_id)
        )
        settings = result.scalar_one_or_none()

        if not settings:
            settings = UserSettings(user_id=user_id)
            db.add(settings)

        settings.notifications_enabled = enabled

        await db.commit()
        await db.refresh(settings)

        return {
            "status": "updated",
            "notifications_enabled": settings.notifications_enabled
        }