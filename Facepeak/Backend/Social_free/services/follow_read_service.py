from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from models.follow import Follow
from models.user import User


class FollowReadService:

    # =========================
    # GET FOLLOWERS (who follows me)
    # =========================
    async def get_followers(
        self,
        db: AsyncSession,
        user_id: int,
        limit: int = 20,
        offset: int = 0,
    ):
        result = await db.execute(
            select(User)
            .join(Follow, Follow.follower_id == User.id)
            .where(Follow.following_id == user_id)
            .order_by(desc(Follow.created_at))
            .limit(limit)
            .offset(offset)
        )

        users = result.scalars().all()

        return [
            {
                "id": u.id,
                "username": u.username,
                "image": u.image,
            }
            for u in users
        ]

    # =========================
    # GET FOLLOWING (who I follow)
    # =========================
    async def get_following(
        self,
        db: AsyncSession,
        user_id: int,
        limit: int = 20,
        offset: int = 0,
    ):
        result = await db.execute(
            select(User)
            .join(Follow, Follow.following_id == User.id)
            .where(Follow.follower_id == user_id)
            .order_by(desc(Follow.created_at))
            .limit(limit)
            .offset(offset)
        )

        users = result.scalars().all()

        return [
            {
                "id": u.id,
                "username": u.username,
                "image": u.image,
            }
            for u in users
        ]

    # =========================
    # COUNT FOLLOWERS
    # =========================
    async def get_followers_count(
        self,
        db: AsyncSession,
        user_id: int,
    ):
        result = await db.execute(
            select(func.count()).where(
                Follow.following_id == user_id
            )
        )
        return result.scalar() or 0

    # =========================
    # COUNT FOLLOWING
    # =========================
    async def get_following_count(
        self,
        db: AsyncSession,
        user_id: int,
    ):
        result = await db.execute(
            select(func.count()).where(
                Follow.follower_id == user_id
            )
        )
        return result.scalar() or 0

    # =========================
    # IS FOLLOWING (for UI button)
    # =========================
    async def is_following(
        self,
        db: AsyncSession,
        user_id: int,
        target_id: int,
    ):
        if user_id == target_id:
            return False

        result = await db.execute(
            select(Follow.id).where(
                Follow.follower_id == user_id,
                Follow.following_id == target_id
            )
        )

        return result.scalar_one_or_none() is not None

    # =========================
    # BULK FOLLOW STATE (FOR LIST UI 🔥)
    # =========================
    async def bulk_is_following(
        self,
        db: AsyncSession,
        user_id: int,
        target_ids: list[int],
    ):
        if not target_ids:
            return {}

        result = await db.execute(
            select(Follow.following_id).where(
                Follow.follower_id == user_id,
                Follow.following_id.in_(target_ids)
            )
        )

        following_ids = set(result.scalars().all())

        return {
            tid: (tid in following_ids)
            for tid in target_ids
        }