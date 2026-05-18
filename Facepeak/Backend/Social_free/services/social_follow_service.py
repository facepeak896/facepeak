from sqlalchemy import select, update, delete, or_, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from sqlalchemy.sql import func

from Backend.Social_free.models.user import User
from Backend.Social_free.models.follow import Follow
from Backend.Social_free.models.user_stats import UserStats
from Backend.Social_free.models.user_block import UserBlock
from Backend.Social_free.services.notification_service import NotificationService


class SocialFollowService:
    async def _ensure_stats(self, db: AsyncSession, user_id: int) -> None:
        stats = await db.get(UserStats, user_id)

        if not stats:
            db.add(UserStats(user_id=user_id))
            await db.flush()

    async def _inc_stat(
        self,
        db: AsyncSession,
        user_id: int,
        field: str,
        amount: int,
    ) -> None:
        allowed = {
            "followers_count",
            "following_count",
            "notifications_count",
        }

        if field not in allowed:
            raise ValueError("INVALID_STAT_FIELD")

        await self._ensure_stats(db, user_id)

        await db.execute(
            update(UserStats)
            .where(UserStats.user_id == user_id)
            .values({
                field: func.greatest(
                    getattr(UserStats, field) + amount,
                    0,
                )
            })
        )

    async def _is_blocked(
        self,
        db: AsyncSession,
        user_a: int,
        user_b: int,
    ) -> bool:
        result = await db.execute(
            select(UserBlock).where(
                or_(
                    and_(
                        UserBlock.blocker_id == user_a,
                        UserBlock.blocked_id == user_b,
                    ),
                    and_(
                        UserBlock.blocker_id == user_b,
                        UserBlock.blocked_id == user_a,
                    ),
                )
            )
        )

        return result.scalar_one_or_none() is not None

    async def is_following(
        self,
        db: AsyncSession,
        *,
        follower_id: int,
        following_id: int,
    ) -> bool:
        result = await db.execute(
            select(Follow).where(
                Follow.follower_id == follower_id,
                Follow.following_id == following_id,
                Follow.status == "accepted",
            )
        )

        return result.scalar_one_or_none() is not None

    async def _send_follow_push(
        self,
        db: AsyncSession,
        *,
        follower_id: int,
        following_id: int,
    ) -> None:
        follower = await db.get(User, follower_id)

        follower_name = (
            follower.username
            if follower and follower.username
            else "Someone"
        )

        try:
            await NotificationService.on_follow_created(
                db=db,
                follower_id=follower_id,
                following_id=following_id,
                follower_name=follower_name,
            )
        except Exception as e:
            print("FOLLOW PUSH ERROR:", e)

    async def follow_user(
        self,
        db: AsyncSession,
        *,
        follower_id: int,
        following_id: int,
    ) -> dict:
        if follower_id == following_id:
            raise ValueError("CANNOT_FOLLOW_YOURSELF")

        target = await db.get(User, following_id)

        if not target:
            raise ValueError("USER_NOT_FOUND")

        if await self._is_blocked(db, follower_id, following_id):
            raise ValueError("USER_BLOCKED")

        existing = await db.execute(
            select(Follow).where(
                Follow.follower_id == follower_id,
                Follow.following_id == following_id,
            )
        )

        existing_follow = existing.scalar_one_or_none()

        if existing_follow:
            if existing_follow.status != "accepted":
                existing_follow.status = "accepted"

                await self._inc_stat(
                    db,
                    follower_id,
                    "following_count",
                    1,
                )

                await self._inc_stat(
                    db,
                    following_id,
                    "followers_count",
                    1,
                )

                await self._inc_stat(
                    db,
                    following_id,
                    "notifications_count",
                    1,
                )

                await db.commit()

                await self._send_follow_push(
                    db,
                    follower_id=follower_id,
                    following_id=following_id,
                )

            return {
                "status": "already_following",
                "is_following": True,
                "can_follow_request": False,
            }

        follow = Follow(
            follower_id=follower_id,
            following_id=following_id,
            status="accepted",
        )

        db.add(follow)

        try:
            await db.flush()

            await self._inc_stat(
                db,
                follower_id,
                "following_count",
                1,
            )

            await self._inc_stat(
                db,
                following_id,
                "followers_count",
                1,
            )

            await self._inc_stat(
                db,
                following_id,
                "notifications_count",
                1,
            )

            await db.commit()
            await db.refresh(follow)

            await self._send_follow_push(
                db,
                follower_id=follower_id,
                following_id=following_id,
            )

            return {
                "status": "following",
                "follow_id": follow.id,
                "is_following": True,
                "can_follow_request": False,
            }

        except IntegrityError:
            await db.rollback()

            return {
                "status": "already_following",
                "is_following": True,
                "can_follow_request": False,
            }

    async def unfollow_user(
        self,
        db: AsyncSession,
        *,
        follower_id: int,
        following_id: int,
    ) -> dict:
        if follower_id == following_id:
            raise ValueError("CANNOT_UNFOLLOW_YOURSELF")

        result = await db.execute(
            select(Follow).where(
                Follow.follower_id == follower_id,
                Follow.following_id == following_id,
            )
        )

        follow = result.scalar_one_or_none()

        if not follow:
            return {
                "status": "not_following",
                "is_following": False,
                "can_follow_request": True,
            }

        await db.delete(follow)

        await self._inc_stat(
            db,
            follower_id,
            "following_count",
            -1,
        )

        await self._inc_stat(
            db,
            following_id,
            "followers_count",
            -1,
        )

        await db.commit()

        return {
            "status": "unfollowed",
            "is_following": False,
            "can_follow_request": True,
        }

    async def remove_follower(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        follower_id: int,
    ) -> dict:
        if current_user_id == follower_id:
            raise ValueError("CANNOT_REMOVE_YOURSELF")

        result = await db.execute(
            select(Follow).where(
                Follow.follower_id == follower_id,
                Follow.following_id == current_user_id,
            )
        )

        follow = result.scalar_one_or_none()

        if not follow:
            return {
                "status": "not_a_follower",
                "removed": False,
            }

        await db.delete(follow)

        await self._inc_stat(
            db,
            follower_id,
            "following_count",
            -1,
        )

        await self._inc_stat(
            db,
            current_user_id,
            "followers_count",
            -1,
        )

        await db.commit()

        return {
            "status": "follower_removed",
            "removed": True,
        }

    async def remove_all_follow_edges_between_users(
        self,
        db: AsyncSession,
        *,
        user_a: int,
        user_b: int,
    ) -> dict:
        result = await db.execute(
            select(Follow).where(
                or_(
                    and_(
                        Follow.follower_id == user_a,
                        Follow.following_id == user_b,
                    ),
                    and_(
                        Follow.follower_id == user_b,
                        Follow.following_id == user_a,
                    ),
                )
            )
        )

        follows = result.scalars().all()

        removed = 0

        for f in follows:
            await db.delete(f)
            removed += 1

            await self._inc_stat(
                db,
                f.follower_id,
                "following_count",
                -1,
            )

            await self._inc_stat(
                db,
                f.following_id,
                "followers_count",
                -1,
            )

        await db.commit()

        return {
            "status": "follow_edges_removed",
            "removed": removed,
        }

    async def list_followers(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        viewer_id: int,
        limit: int = 30,
        offset: int = 0,
    ) -> list[dict]:
        limit = max(1, min(limit, 50))
        offset = max(0, offset)

        result = await db.execute(
            select(Follow, User)
            .join(User, User.id == Follow.follower_id)
            .where(
                Follow.following_id == user_id,
                Follow.status == "accepted",
            )
            .order_by(Follow.created_at.desc())
            .limit(limit)
            .offset(offset)
        )

        data = []

        for follow, user in result.all():
            if await self._is_blocked(db, viewer_id, user.id):
                continue

            data.append({
                "user_id": user.id,
                "username": user.username or "User",
                "profile_image_url": user.profile_image_url or "",
                "followed_at": (
                    follow.created_at.isoformat()
                    if follow.created_at
                    else None
                ),
                "is_following": await self.is_following(
                    db,
                    follower_id=viewer_id,
                    following_id=user.id,
                ),
            })

        return data

    async def list_following(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        viewer_id: int,
        limit: int = 30,
        offset: int = 0,
    ) -> list[dict]:
        limit = max(1, min(limit, 50))
        offset = max(0, offset)

        result = await db.execute(
            select(Follow, User)
            .join(User, User.id == Follow.following_id)
            .where(
                Follow.follower_id == user_id,
                Follow.status == "accepted",
            )
            .order_by(Follow.created_at.desc())
            .limit(limit)
            .offset(offset)
        )

        data = []

        for follow, user in result.all():
            if await self._is_blocked(db, viewer_id, user.id):
                continue

            data.append({
                "user_id": user.id,
                "username": user.username or "User",
                "profile_image_url": user.profile_image_url or "",
                "followed_at": (
                    follow.created_at.isoformat()
                    if follow.created_at
                    else None
                ),
                "is_following": await self.is_following(
                    db,
                    follower_id=viewer_id,
                    following_id=user.id,
                ),
            })

        return data

    async def list_followers_page(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        viewer_id: int,
        limit: int = 30,
        offset: int = 0,
    ) -> dict:
        limit = max(1, min(limit, 50))
        offset = max(0, offset)

        items = await self.list_followers(
            db=db,
            user_id=user_id,
            viewer_id=viewer_id,
            limit=limit,
            offset=offset,
        )

        return {
            "items": items,
            "has_more": len(items) >= limit,
            "next_offset": offset + len(items),
            "count": len(items),
        }

    async def list_following_page(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        viewer_id: int,
        limit: int = 30,
        offset: int = 0,
    ) -> dict:
        limit = max(1, min(limit, 50))
        offset = max(0, offset)

        items = await self.list_following(
            db=db,
            user_id=user_id,
            viewer_id=viewer_id,
            limit=limit,
            offset=offset,
        )

        return {
            "items": items,
            "has_more": len(items) >= limit,
            "next_offset": offset + len(items),
            "count": len(items),
        }