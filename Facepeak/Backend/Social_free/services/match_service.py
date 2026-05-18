from sqlalchemy import select, update, or_, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from Backend.Social_free.models.user import User
from Backend.Social_free.models.user_stats import UserStats
from Backend.Social_free.models.match_request import MatchRequest
from Backend.Social_free.models.match_table import Match
from Backend.Social_free.models.user_block import UserBlock
from Backend.Social_free.services.notification_service import NotificationService


class SocialMatchService:
    async def _is_blocked(self, db: AsyncSession, user_a: int, user_b: int) -> bool:
        result = await db.execute(
            select(UserBlock).where(
                or_(
                    and_(UserBlock.blocker_id == user_a, UserBlock.blocked_id == user_b),
                    and_(UserBlock.blocker_id == user_b, UserBlock.blocked_id == user_a),
                )
            )
        )
        return result.scalar_one_or_none() is not None

    async def send_match_request(
        self,
        db: AsyncSession,
        *,
        sender_id: int,
        receiver_id: int,
    ) -> dict:
        if sender_id == receiver_id:
            raise ValueError("CANNOT_MATCH_YOURSELF")

        receiver = await db.get(User, receiver_id)
        if not receiver:
            raise ValueError("USER_NOT_FOUND")

        if await self._is_blocked(db, sender_id, receiver_id):
            raise ValueError("USER_BLOCKED")

        user1_id, user2_id = sorted([sender_id, receiver_id])

        existing_match = await db.execute(
            select(Match).where(
                Match.user1_id == user1_id,
                Match.user2_id == user2_id,
            )
        )

        if existing_match.scalar_one_or_none():
            return {"status": "already_matched"}

        existing_request = await db.execute(
            select(MatchRequest).where(
                MatchRequest.sender_id == sender_id,
                MatchRequest.receiver_id == receiver_id,
            )
        )

        req = existing_request.scalar_one_or_none()

        if req:
            return {
                "status": req.status,
                "request_id": req.id,
            }

        reverse_request = await db.execute(
            select(MatchRequest).where(
                MatchRequest.sender_id == receiver_id,
                MatchRequest.receiver_id == sender_id,
                MatchRequest.status == "pending",
            )
        )

        reverse = reverse_request.scalar_one_or_none()

        if reverse:
            reverse.status = "accepted"

            match = Match(user1_id=user1_id, user2_id=user2_id)
            db.add(match)

            await self._inc_stat(db, sender_id, "matches_count", 1)
            await self._inc_stat(db, receiver_id, "matches_count", 1)
            await self._inc_stat(db, sender_id, "notifications_count", 1)
            await self._inc_stat(db, receiver_id, "notifications_count", 1)

            await db.commit()
            await db.refresh(match)

            sender = await db.get(User, sender_id)
            receiver = await db.get(User, receiver_id)

            sender_name = (
                sender.username
                if sender and sender.username
                else "Someone"
            )

            receiver_name = (
                receiver.username
                if receiver and receiver.username
                else "Someone"
            )

            try:
                await NotificationService.on_match_created(
                    db=db,
                    user_id=sender_id,
                    other_user_id=receiver_id,
                    match_id=match.id,
                    other_name=receiver_name,
                )

                await NotificationService.on_match_created(
                    db=db,
                    user_id=receiver_id,
                    other_user_id=sender_id,
                    match_id=match.id,
                    other_name=sender_name,
                )

            except Exception as e:
                print("MATCH PUSH ERROR:", e)

            return {
                "status": "matched",
                "request_id": reverse.id,
                "match_id": match.id,
            }

        req = MatchRequest(
            sender_id=sender_id,
            receiver_id=receiver_id,
            status="pending",
        )

        db.add(req)

        await self._inc_stat(db, receiver_id, "match_requests_count", 1)
        await self._inc_stat(db, receiver_id, "notifications_count", 1)

        try:
            await db.commit()
            await db.refresh(req)

            sender = await db.get(User, sender_id)

            sender_name = (
                sender.username
                if sender and sender.username
                else "Someone"
            )

            try:
                await NotificationService.on_match_request_created(
                    db=db,
                    sender_id=sender_id,
                    receiver_id=receiver_id,
                    request_id=req.id,
                    sender_name=sender_name,
                )
            except Exception as e:
                print("MATCH REQUEST PUSH ERROR:", e)

        except IntegrityError:
            await db.rollback()
            return {"status": "duplicate"}

        return {
            "status": "pending",
            "request_id": req.id,
        }

    async def accept_match_request(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        request_id: int,
    ) -> dict:
        result = await db.execute(
            select(MatchRequest).where(MatchRequest.id == request_id)
        )

        req = result.scalar_one_or_none()

        if not req:
            raise ValueError("MATCH_REQUEST_NOT_FOUND")

        if req.receiver_id != current_user_id:
            raise ValueError("NOT_ALLOWED")

        if await self._is_blocked(db, req.sender_id, req.receiver_id):
            raise ValueError("USER_BLOCKED")

        if req.status == "accepted":
            return {"status": "already_accepted"}

        if req.status != "pending":
            raise ValueError("REQUEST_NOT_PENDING")

        req.status = "accepted"

        user1_id, user2_id = sorted([req.sender_id, req.receiver_id])

        existing_match = await db.execute(
            select(Match).where(
                Match.user1_id == user1_id,
                Match.user2_id == user2_id,
            )
        )

        match = existing_match.scalar_one_or_none()

        if not match:
            match = Match(user1_id=user1_id, user2_id=user2_id)
            db.add(match)
            await db.flush()

            await self._inc_stat(db, req.sender_id, "matches_count", 1)
            await self._inc_stat(db, req.receiver_id, "matches_count", 1)

        await self._inc_stat(db, req.receiver_id, "match_requests_count", -1)
        await self._inc_stat(db, req.sender_id, "notifications_count", 1)

        await db.commit()
        await db.refresh(match)

        sender = await db.get(User, req.sender_id)
        receiver = await db.get(User, req.receiver_id)

        sender_name = (
            sender.username
            if sender and sender.username
            else "Someone"
        )

        receiver_name = (
            receiver.username
            if receiver and receiver.username
            else "Someone"
        )

        try:
            await NotificationService.on_match_created(
                db=db,
                user_id=req.sender_id,
                other_user_id=req.receiver_id,
                match_id=match.id,
                other_name=receiver_name,
            )

            await NotificationService.on_match_created(
                db=db,
                user_id=req.receiver_id,
                other_user_id=req.sender_id,
                match_id=match.id,
                other_name=sender_name,
            )

        except Exception as e:
            print("MATCH PUSH ERROR:", e)

        return {
            "status": "matched",
            "request_id": req.id,
            "match_id": match.id,
        }

    async def reject_match_request(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        request_id: int,
    ) -> dict:
        result = await db.execute(
            select(MatchRequest).where(MatchRequest.id == request_id)
        )

        req = result.scalar_one_or_none()

        if not req:
            raise ValueError("MATCH_REQUEST_NOT_FOUND")

        if req.receiver_id != current_user_id:
            raise ValueError("NOT_ALLOWED")

        if req.status != "pending":
            raise ValueError("REQUEST_NOT_PENDING")

        req.status = "rejected"

        await self._inc_stat(db, req.receiver_id, "match_requests_count", -1)

        await db.commit()

        return {"status": "rejected"}

    async def cancel_match_request(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        request_id: int,
    ) -> dict:
        result = await db.execute(
            select(MatchRequest).where(MatchRequest.id == request_id)
        )

        req = result.scalar_one_or_none()

        if not req:
            raise ValueError("MATCH_REQUEST_NOT_FOUND")

        if req.sender_id != current_user_id:
            raise ValueError("NOT_ALLOWED")

        if req.status != "pending":
            raise ValueError("REQUEST_NOT_PENDING")

        req.status = "cancelled"

        await self._inc_stat(db, req.receiver_id, "match_requests_count", -1)
        await self._inc_stat(db, req.receiver_id, "notifications_count", -1)

        await db.commit()

        return {"status": "cancelled"}

    async def list_incoming_requests(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        limit: int = 30,
        offset: int = 0,
    ) -> list[dict]:
        result = await db.execute(
            select(MatchRequest, User)
            .join(User, User.id == MatchRequest.sender_id)
            .where(
                MatchRequest.receiver_id == user_id,
                MatchRequest.status == "pending",
            )
            .order_by(MatchRequest.created_at.desc())
            .limit(limit)
            .offset(offset)
        )

        data = []

        for req, sender in result.all():
            if await self._is_blocked(db, user_id, sender.id):
                continue

            data.append(
                {
                    "request_id": req.id,
                    "sender_id": sender.id,
                    "username": sender.username or "User",
                    "profile_image_url": sender.profile_image_url or "",
                    "status": req.status,
                    "created_at": req.created_at.isoformat()
                    if req.created_at
                    else None,
                }
            )

        return data

    async def list_matches(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        limit: int = 30,
        offset: int = 0,
    ) -> list[dict]:
        result = await db.execute(
            select(Match)
            .where(
                or_(
                    Match.user1_id == user_id,
                    Match.user2_id == user_id,
                )
            )
            .order_by(Match.created_at.desc())
            .limit(limit)
            .offset(offset)
        )

        matches = result.scalars().all()

        if not matches:
            return []

        other_ids = [
            m.user2_id if m.user1_id == user_id else m.user1_id
            for m in matches
        ]

        users_result = await db.execute(
            select(User).where(User.id.in_(other_ids))
        )

        users = {u.id: u for u in users_result.scalars().all()}

        data = []

        for m in matches:
            other_id = m.user2_id if m.user1_id == user_id else m.user1_id

            if await self._is_blocked(db, user_id, other_id):
                continue

            other = users.get(other_id)

            if not other:
                continue

            data.append(
                {
                    "match_id": m.id,
                    "user_id": other.id,
                    "username": other.username or "User",
                    "profile_image_url": other.profile_image_url or "",
                    "created_at": m.created_at.isoformat()
                    if m.created_at
                    else None,
                }
            )

        return data

    async def _inc_stat(
        self,
        db: AsyncSession,
        user_id: int,
        field: str,
        amount: int,
    ) -> None:
        allowed = {
            "matches_count",
            "match_requests_count",
            "notifications_count",
        }

        if field not in allowed:
            raise ValueError("INVALID_STAT_FIELD")

        await db.execute(
            update(UserStats)
            .where(UserStats.user_id == user_id)
            .values({field: getattr(UserStats, field) + amount})
        )