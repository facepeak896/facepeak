from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete, update, case
from models.follow import Follow
from models.user import User


class FollowService:

    # =========================
    # FOLLOW
    # =========================
    async def follow(
        self,
        db: AsyncSession,
        user_id: int,
        target_id: int,
    ):
        # ❌ SELF FOLLOW
        if user_id == target_id:
            return {
                "status": "error",
                "reason": "SELF_FOLLOW_NOT_ALLOWED"
            }

        # 🔍 CHECK EXISTING
        result = await db.execute(
            select(Follow.id).where(
                Follow.follower_id == user_id,
                Follow.following_id == target_id
            )
        )
        existing = result.scalar_one_or_none()

        if existing:
            return {
                "status": "ok",
                "already_following": True
            }

        # 🔥 CREATE FOLLOW
        follow = Follow(
            follower_id=user_id,
            following_id=target_id,
            status="accepted"
        )
        db.add(follow)

        # ⚡ ATOMIC INCREMENT
        await db.execute(
            update(User)
            .where(User.id == target_id)
            .values(
                followers_count=User.followers_count + 1
            )
        )

        await db.execute(
            update(User)
            .where(User.id == user_id)
            .values(
                following_count=User.following_count + 1
            )
        )

        await db.commit()

        return {
            "status": "success",
            "delta": +1,
            "target_id": target_id
        }

    # =========================
    # UNFOLLOW (SAFE)
    # =========================
    async def unfollow(
        self,
        db: AsyncSession,
        user_id: int,
        target_id: int,
    ):
        # 🔍 CHECK EXISTING
        result = await db.execute(
            select(Follow.id).where(
                Follow.follower_id == user_id,
                Follow.following_id == target_id
            )
        )
        existing = result.scalar_one_or_none()

        if not existing:
            return {
                "status": "ok",
                "already_unfollowed": True
            }

        # ❌ DELETE RELATION
        await db.execute(
            delete(Follow).where(
                Follow.follower_id == user_id,
                Follow.following_id == target_id
            )
        )

        # 🔥 SAFE DECREMENT (NEVER < 0)
        await db.execute(
            update(User)
            .where(User.id == target_id)
            .values(
                followers_count=case(
                    (User.followers_count > 0, User.followers_count - 1),
                    else_=0
                )
            )
        )

        await db.execute(
            update(User)
            .where(User.id == user_id)
            .values(
                following_count=case(
                    (User.following_count > 0, User.following_count - 1),
                    else_=0
                )
            )
        )

        await db.commit()

        return {
            "status": "success",
            "delta": -1,
            "target_id": target_id
        }

    # =========================
    # CHECK IF FOLLOWING
    # =========================
    async def is_following(
        self,
        db: AsyncSession,
        user_id: int,
        target_id: int,
    ):
        result = await db.execute(
            select(Follow.id).where(
                Follow.follower_id == user_id,
                Follow.following_id == target_id
            )
        )

        return result.scalar_one_or_none() is not None