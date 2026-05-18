import re
from datetime import datetime, timezone, timedelta

from sqlalchemy import select, update, or_, and_, delete
from sqlalchemy.sql import func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from Backend.Social_free.models.user import User
from Backend.Social_free.models.user_stats import UserStats
from Backend.Social_free.models.message_request import MessageRequest
from Backend.Social_free.models.conversation import Conversation
from Backend.Social_free.models.message import Message
from Backend.Social_free.models.user_block import UserBlock
from Backend.Social_free.models.user_report import UserReport
from Backend.Social_free.models.conversation_hidden import ConversationHidden
from Backend.Social_free.services.notification_service import NotificationService


class SocialMessageService:
    MAX_MESSAGE_LEN = 500

    def _utc_now(self) -> datetime:
        return datetime.now(timezone.utc)

    def _active_now(self, user: User) -> bool:
        if not user or not user.last_active_at:
            return False

        last_active = user.last_active_at

        if last_active.tzinfo is None:
            last_active = last_active.replace(tzinfo=timezone.utc)

        diff = self._utc_now() - last_active

        if diff.total_seconds() < 0:
            return True

        return diff <= timedelta(minutes=2)

    async def touch_active(
        self,
        db: AsyncSession,
        *,
        user_id: int,
    ) -> None:
        await db.execute(
            update(User)
            .where(User.id == user_id)
            .values(last_active_at=self._utc_now())
        )

    def _clean_text(self, text: str) -> str:
        cleaned = (text or "").strip()
        cleaned = re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "", cleaned)
        cleaned = re.sub(r"\s+", " ", cleaned)
        return cleaned[: self.MAX_MESSAGE_LEN]

    async def _has_blocked(
        self,
        db: AsyncSession,
        *,
        blocker_id: int,
        blocked_id: int,
    ) -> bool:
        result = await db.execute(
            select(UserBlock).where(
                UserBlock.blocker_id == blocker_id,
                UserBlock.blocked_id == blocked_id,
            )
        )
        return result.scalar_one_or_none() is not None

    async def _delete_own_block(
        self,
        db: AsyncSession,
        *,
        blocker_id: int,
        blocked_id: int,
    ) -> None:
        await db.execute(
            delete(UserBlock).where(
                UserBlock.blocker_id == blocker_id,
                UserBlock.blocked_id == blocked_id,
            )
        )

    async def _is_blocked(self, db: AsyncSession, user_a: int, user_b: int) -> bool:
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

    async def _is_conversation_hidden_for_user(
        self,
        db: AsyncSession,
        *,
        conversation_id: int,
        user_id: int,
    ) -> bool:
        result = await db.execute(
            select(ConversationHidden).where(
                ConversationHidden.conversation_id == conversation_id,
                ConversationHidden.user_id == user_id,
            )
        )
        return result.scalar_one_or_none() is not None

    async def _inc_stat(
        self,
        db: AsyncSession,
        user_id: int,
        field: str,
        amount: int,
    ) -> None:
        allowed = {
            "message_requests_count",
            "notifications_count",
            "unread_messages_count",
        }

        if field not in allowed:
            raise ValueError("INVALID_STAT_FIELD")

        await db.execute(
            update(UserStats)
            .where(UserStats.user_id == user_id)
            .values({field: func.greatest(getattr(UserStats, field) + amount, 0)})
        )

    async def _restore_hidden_for_users(
        self,
        db: AsyncSession,
        *,
        conversation_id: int,
        user_ids: list[int],
    ) -> None:
        await db.execute(
            delete(ConversationHidden).where(
                ConversationHidden.conversation_id == conversation_id,
                ConversationHidden.user_id.in_(user_ids),
            )
        )

    async def mark_delivered(
        self,
        db: AsyncSession,
        *,
        message_id: int,
        receiver_id: int,
    ) -> dict:
        result = await db.execute(
            update(Message)
            .where(
                Message.id == message_id,
                Message.receiver_id == receiver_id,
                Message.delivered_at.is_(None),
            )
            .values(delivered_at=func.now())
            .returning(Message.id, Message.conversation_id, Message.sender_id)
        )

        row = result.first()

        await db.commit()

        if not row:
            return {
                "status": "already_delivered",
                "message_id": message_id,
            }

        return {
            "status": "delivered",
            "message_id": row.id,
            "conversation_id": row.conversation_id,
            "sender_id": row.sender_id,
        }

    async def _get_conversation(
        self,
        db: AsyncSession,
        user1_id: int,
        user2_id: int,
    ) -> Conversation | None:
        result = await db.execute(
            select(Conversation).where(
                Conversation.user1_id == user1_id,
                Conversation.user2_id == user2_id,
            )
        )
        return result.scalar_one_or_none()

    async def send_message_request(
        self,
        db: AsyncSession,
        *,
        sender_id: int,
        receiver_id: int,
    ) -> dict:
        await self.touch_active(db, user_id=sender_id)

        if sender_id == receiver_id:
            raise ValueError("CANNOT_MESSAGE_YOURSELF")

        receiver = await db.get(User, receiver_id)
        if not receiver:
            raise ValueError("USER_NOT_FOUND")

        if await self._has_blocked(db, blocker_id=receiver_id, blocked_id=sender_id):
            raise ValueError("USER_BLOCKED")

        if await self._has_blocked(db, blocker_id=sender_id, blocked_id=receiver_id):
            await self._delete_own_block(
                db,
                blocker_id=sender_id,
                blocked_id=receiver_id,
            )

        user1_id, user2_id = sorted([sender_id, receiver_id])

        conv = await self._get_conversation(db, user1_id, user2_id)
        if conv:
            await self._restore_hidden_for_users(
                db,
                conversation_id=conv.id,
                user_ids=[sender_id, receiver_id],
            )

            await db.commit()

            return {
                "status": "conversation_exists",
                "conversation_id": conv.id,
            }

        existing = await db.execute(
            select(MessageRequest).where(
                MessageRequest.sender_id == sender_id,
                MessageRequest.receiver_id == receiver_id,
            )
        )
        req = existing.scalar_one_or_none()

        if req:
            if req.status == "pending":
                await db.commit()
                return {
                    "status": "pending",
                    "request_id": req.id,
                }

            if req.status == "accepted":
                await db.commit()
                return {
                    "status": "accepted",
                    "request_id": req.id,
                }

            req.status = "pending"
            req.created_at = func.now()

            await self._inc_stat(db, receiver_id, "message_requests_count", 1)
            await self._inc_stat(db, receiver_id, "notifications_count", 1)

            await db.commit()
            await db.refresh(req)

            sender = await db.get(User, sender_id)

            sender_name = (
                sender.username
                if sender and sender.username
                else "Someone"
            )

            try:
                await NotificationService.on_message_request_created(
                    db=db,
                    sender_id=sender_id,
                    receiver_id=receiver_id,
                    request_id=req.id,
                    sender_name=sender_name,
                )
            except Exception as e:
                print("MESSAGE REQUEST PUSH ERROR:", e)

            return {
                "status": "pending",
                "request_id": req.id,
            }

        reverse = await db.execute(
            select(MessageRequest).where(
                MessageRequest.sender_id == receiver_id,
                MessageRequest.receiver_id == sender_id,
            )
        )
        reverse_req = reverse.scalar_one_or_none()

        if reverse_req:
            if reverse_req.status == "pending":
                reverse_req.status = "accepted"

                conv = Conversation(user1_id=user1_id, user2_id=user2_id)
                db.add(conv)
                await db.flush()

                await self._inc_stat(db, sender_id, "notifications_count", 1)
                await self._inc_stat(db, receiver_id, "message_requests_count", -1)

                await db.commit()
                await db.refresh(conv)

                sender = await db.get(User, receiver_id)

                sender_name = (
                    sender.username
                    if sender and sender.username
                    else "Someone"
                )

                try:
                    await NotificationService.send_now(
                        db=db,
                        user_id=receiver_id,
                        notification_type="message_request_accepted",
                        dedupe_key=f"message_request_accepted:{receiver_id}:{reverse_req.id}",
                        title="✅ Message Request Accepted",
                        body=f"{sender_name} accepted your message request",
                        data={
                            "type": "message_request_accepted",
                            "request_id": reverse_req.id,
                            "conversation_id": conv.id,
                            "sender_id": sender_id,
                        },
                        daily_limit=5,
                    )
                except Exception as e:
                    print("MESSAGE REQUEST ACCEPT PUSH ERROR:", e)

                return {
                    "status": "conversation_created",
                    "request_id": reverse_req.id,
                    "conversation_id": conv.id,
                }

            reverse_req.sender_id = sender_id
            reverse_req.receiver_id = receiver_id
            reverse_req.status = "pending"
            reverse_req.created_at = func.now()

            await self._inc_stat(db, receiver_id, "message_requests_count", 1)
            await self._inc_stat(db, receiver_id, "notifications_count", 1)

            await db.commit()
            await db.refresh(reverse_req)

            sender = await db.get(User, sender_id)

            sender_name = (
                sender.username
                if sender and sender.username
                else "Someone"
            )

            try:
                await NotificationService.on_message_request_created(
                    db=db,
                    sender_id=sender_id,
                    receiver_id=receiver_id,
                    request_id=reverse_req.id,
                    sender_name=sender_name,
                )
            except Exception as e:
                print("MESSAGE REQUEST PUSH ERROR:", e)

            return {
                "status": "pending",
                "request_id": reverse_req.id,
            }

        req = MessageRequest(
            sender_id=sender_id,
            receiver_id=receiver_id,
            status="pending",
        )
        db.add(req)

        await self._inc_stat(db, receiver_id, "message_requests_count", 1)
        await self._inc_stat(db, receiver_id, "notifications_count", 1)

        try:
            await db.commit()
            await db.refresh(req)
        except IntegrityError:
            await db.rollback()
            return {"status": "duplicate"}

        sender = await db.get(User, sender_id)

        sender_name = (
            sender.username
            if sender and sender.username
            else "Someone"
        )

        try:
            await NotificationService.on_message_request_created(
                db=db,
                sender_id=sender_id,
                receiver_id=receiver_id,
                request_id=req.id,
                sender_name=sender_name,
            )
        except Exception as e:
            print("MESSAGE REQUEST PUSH ERROR:", e)

        return {
            "status": "pending",
            "request_id": req.id,
        }

    async def accept_message_request(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        request_id: int,
    ) -> dict:
        await self.touch_active(db, user_id=current_user_id)

        result = await db.execute(
            select(MessageRequest).where(MessageRequest.id == request_id)
        )
        req = result.scalar_one_or_none()

        if not req:
            raise ValueError("MESSAGE_REQUEST_NOT_FOUND")

        if req.receiver_id != current_user_id:
            raise ValueError("NOT_ALLOWED")

        if await self._is_blocked(db, req.sender_id, req.receiver_id):
            raise ValueError("USER_BLOCKED")

        user1_id, user2_id = sorted([req.sender_id, req.receiver_id])
        conv = await self._get_conversation(db, user1_id, user2_id)

        if req.status == "accepted":
            await db.commit()
            return {
                "status": "already_accepted",
                "conversation_id": conv.id if conv else None,
            }

        if req.status != "pending":
            raise ValueError("REQUEST_NOT_PENDING")

        req.status = "accepted"

        if not conv:
            conv = Conversation(user1_id=user1_id, user2_id=user2_id)
            db.add(conv)
            await db.flush()

        await self._restore_hidden_for_users(
            db,
            conversation_id=conv.id,
            user_ids=[req.sender_id, req.receiver_id],
        )

        await self._inc_stat(db, req.receiver_id, "message_requests_count", -1)
        await self._inc_stat(db, req.sender_id, "notifications_count", 1)

        sender_id = req.sender_id

        await db.commit()
        await db.refresh(conv)

        accepter = await db.get(User, current_user_id)

        accepter_name = (
            accepter.username
            if accepter and accepter.username
            else "Someone"
        )

        try:
            await NotificationService.send_now(
                db=db,
                user_id=sender_id,
                notification_type="message_request_accepted",
                dedupe_key=f"message_request_accepted:{sender_id}:{request_id}",
                title="✅ Message Request Accepted",
                body=f"{accepter_name} accepted your message request",
                data={
                    "type": "message_request_accepted",
                    "request_id": request_id,
                    "conversation_id": conv.id,
                    "sender_id": current_user_id,
                },
                daily_limit=5,
            )
        except Exception as e:
            print("MESSAGE REQUEST ACCEPT PUSH ERROR:", e)

        return {
            "status": "conversation_created",
            "conversation_id": conv.id,
        }

    async def reject_message_request(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        request_id: int,
    ) -> dict:
        await self.touch_active(db, user_id=current_user_id)

        result = await db.execute(
            select(MessageRequest).where(MessageRequest.id == request_id)
        )
        req = result.scalar_one_or_none()

        if not req:
            raise ValueError("MESSAGE_REQUEST_NOT_FOUND")

        if req.receiver_id != current_user_id:
            raise ValueError("NOT_ALLOWED")

        if req.status != "pending":
            raise ValueError("REQUEST_NOT_PENDING")

        sender_id = req.sender_id

        req.status = "rejected"

        await self._inc_stat(db, req.receiver_id, "message_requests_count", -1)
        await db.commit()

        decliner = await db.get(User, current_user_id)

        decliner_name = (
            decliner.username
            if decliner and decliner.username
            else "Someone"
        )

        try:
            await NotificationService.send_now(
                db=db,
                user_id=sender_id,
                notification_type="message_request_declined",
                dedupe_key=f"message_request_declined:{sender_id}:{request_id}",
                title="Message Request Declined",
                body=f"{decliner_name} declined your message request",
                data={
                    "type": "message_request_declined",
                    "request_id": request_id,
                    "sender_id": current_user_id,
                },
                daily_limit=5,
            )
        except Exception as e:
            print("MESSAGE REQUEST DECLINE PUSH ERROR:", e)

        return {"status": "rejected"}

    async def cancel_message_request(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        request_id: int,
    ) -> dict:
        await self.touch_active(db, user_id=current_user_id)

        result = await db.execute(
            select(MessageRequest).where(MessageRequest.id == request_id)
        )
        req = result.scalar_one_or_none()

        if not req:
            raise ValueError("MESSAGE_REQUEST_NOT_FOUND")

        if req.sender_id != current_user_id:
            raise ValueError("NOT_ALLOWED")

        if req.status != "pending":
            raise ValueError("REQUEST_NOT_PENDING")

        req.status = "cancelled"

        await self._inc_stat(db, req.receiver_id, "message_requests_count", -1)
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
        await self.touch_active(db, user_id=user_id)

        result = await db.execute(
            select(MessageRequest, User)
            .join(User, User.id == MessageRequest.sender_id)
            .where(
                MessageRequest.receiver_id == user_id,
                MessageRequest.status == "pending",
            )
            .order_by(MessageRequest.created_at.desc())
            .limit(limit)
            .offset(offset)
        )

        rows = result.all()

        if not rows:
            await db.commit()
            return []

        sender_ids = [sender.id for _, sender in rows]

        block_result = await db.execute(
            select(UserBlock).where(
                or_(
                    and_(
                        UserBlock.blocker_id == user_id,
                        UserBlock.blocked_id.in_(sender_ids),
                    ),
                    and_(
                        UserBlock.blocked_id == user_id,
                        UserBlock.blocker_id.in_(sender_ids),
                    ),
                )
            )
        )

        blocked_ids: set[int] = set()

        for b in block_result.scalars().all():
            if b.blocker_id == user_id:
                blocked_ids.add(b.blocked_id)
            else:
                blocked_ids.add(b.blocker_id)

        data = []

        for req, sender in rows:
            if sender.id in blocked_ids:
                continue

            data.append(
                {
                    "request_id": req.id,
                    "sender_id": sender.id,
                    "username": sender.username or "User",
                    "profile_image_url": sender.profile_image_url or "",
                    "active_now": self._active_now(sender),
                    "last_active_at": sender.last_active_at.isoformat()
                    if sender.last_active_at
                    else None,
                    "status": req.status,
                    "created_at": req.created_at.isoformat()
                    if req.created_at
                    else None,
                }
            )

        await db.commit()
        return data

    async def list_conversations(
        self,
        db: AsyncSession,
        *,
        user_id: int,
        limit: int = 30,
        offset: int = 0,
    ) -> list[dict]:
        await self.touch_active(db, user_id=user_id)

        hidden_subq = select(ConversationHidden.conversation_id).where(
            ConversationHidden.user_id == user_id
        )

        result = await db.execute(
            select(Conversation)
            .where(
                or_(
                    Conversation.user1_id == user_id,
                    Conversation.user2_id == user_id,
                ),
                Conversation.id.not_in(hidden_subq),
            )
            .order_by(Conversation.updated_at.desc())
            .limit(limit)
            .offset(offset)
        )

        conversations = result.scalars().all()

        if not conversations:
            await db.commit()
            return []

        other_ids = [
            c.user2_id if c.user1_id == user_id else c.user1_id
            for c in conversations
        ]

        users_result = await db.execute(
            select(User).where(User.id.in_(other_ids))
        )
        users = {u.id: u for u in users_result.scalars().all()}

        last_message_ids = [
            c.last_message_id for c in conversations if c.last_message_id
        ]

        messages = {}

        if last_message_ids:
            msg_result = await db.execute(
                select(Message).where(Message.id.in_(last_message_ids))
            )
            messages = {m.id: m for m in msg_result.scalars().all()}

        block_result = await db.execute(
            select(UserBlock).where(
                or_(
                    UserBlock.blocker_id == user_id,
                    UserBlock.blocked_id == user_id,
                )
            )
        )

        blocked_ids: set[int] = set()

        for b in block_result.scalars().all():
            if b.blocker_id == user_id:
                blocked_ids.add(b.blocked_id)
            else:
                blocked_ids.add(b.blocker_id)

        data = []

        for c in conversations:
            other_id = c.user2_id if c.user1_id == user_id else c.user1_id

            if other_id in blocked_ids:
                continue

            other = users.get(other_id)
            if not other:
                continue

            last = messages.get(c.last_message_id)

            data.append(
                {
                    "conversation_id": c.id,
                    "user_id": other.id,
                    "username": other.username or "User",
                    "profile_image_url": other.profile_image_url or "",
                    "active_now": self._active_now(other),
                    "last_active_at": other.last_active_at.isoformat()
                    if other.last_active_at
                    else None,
                    "last_message": None
                    if not last
                    else {
                        "id": last.id,
                        "body": "" if last.is_deleted else last.body,
                        "sender_id": last.sender_id,
                        "receiver_id": last.receiver_id,
                        "is_me": last.sender_id == user_id,
                        "delivered_at": last.delivered_at.isoformat()
                        if last.delivered_at
                        else None,
                        "seen_at": last.seen_at.isoformat()
                        if last.seen_at
                        else None,
                        "created_at": last.created_at.isoformat()
                        if last.created_at
                        else None,
                    },
                    "updated_at": c.updated_at.isoformat()
                    if c.updated_at
                    else None,
                }
            )

        await db.commit()
        return data

    async def list_messages(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        conversation_id: int,
        limit: int = 50,
        offset: int = 0,
    ) -> list[dict]:
        await self.touch_active(db, user_id=current_user_id)

        conv = await db.get(Conversation, conversation_id)

        if not conv:
            raise ValueError("CONVERSATION_NOT_FOUND")

        if current_user_id not in {conv.user1_id, conv.user2_id}:
            raise ValueError("NOT_ALLOWED")

        other_id = conv.user2_id if conv.user1_id == current_user_id else conv.user1_id

        if await self._is_blocked(db, current_user_id, other_id):
            raise ValueError("USER_BLOCKED")

        result = await db.execute(
            select(Message)
            .where(Message.conversation_id == conversation_id)
            .order_by(Message.created_at.desc())
            .limit(limit)
            .offset(offset)
        )

        messages = list(reversed(result.scalars().all()))

        data = [
            {
                "id": m.id,
                "conversation_id": m.conversation_id,
                "sender_id": m.sender_id,
                "receiver_id": m.receiver_id,
                "body": "" if m.is_deleted else m.body,
                "is_me": m.sender_id == current_user_id,
                "is_deleted": bool(m.is_deleted),
                "delivered_at": m.delivered_at.isoformat()
                if m.delivered_at
                else None,
                "seen_at": m.seen_at.isoformat() if m.seen_at else None,
                "created_at": m.created_at.isoformat()
                if m.created_at
                else None,
            }
            for m in messages
        ]

        await db.commit()

        return data

    async def send_message(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        conversation_id: int,
        body: str,
    ) -> dict:
        await self.touch_active(db, user_id=current_user_id)

        clean = self._clean_text(body)

        if not clean:
            raise ValueError("EMPTY_MESSAGE")

        conv = await db.get(Conversation, conversation_id)

        if not conv:
            raise ValueError("CONVERSATION_NOT_FOUND")

        if current_user_id not in {conv.user1_id, conv.user2_id}:
            raise ValueError("NOT_ALLOWED")

        receiver_id = conv.user2_id if conv.user1_id == current_user_id else conv.user1_id

        if await self._has_blocked(db, blocker_id=receiver_id, blocked_id=current_user_id):
            raise ValueError("USER_BLOCKED")

        if await self._has_blocked(db, blocker_id=current_user_id, blocked_id=receiver_id):
            await self._delete_own_block(
                db,
                blocker_id=current_user_id,
                blocked_id=receiver_id,
            )

        await self._restore_hidden_for_users(
            db,
            conversation_id=conversation_id,
            user_ids=[current_user_id, receiver_id],
        )

        msg = Message(
            conversation_id=conversation_id,
            sender_id=current_user_id,
            receiver_id=receiver_id,
            body=clean,
        )
        db.add(msg)
        await db.flush()

        conv.last_message_id = msg.id
        conv.updated_at = func.now()

        await self._inc_stat(db, receiver_id, "unread_messages_count", 1)
        await self._inc_stat(db, receiver_id, "notifications_count", 1)

        await db.commit()
        await db.refresh(msg)

        sender = await db.get(User, current_user_id)

        sender_name = (
            sender.username
            if sender and sender.username
            else "Someone"
        )

        try:
            await NotificationService.on_message_sent(
                db=db,
                sender_id=current_user_id,
                receiver_id=receiver_id,
                conversation_id=conversation_id,
                message_id=msg.id,
                sender_name=sender_name,
                preview=msg.body,
            )
        except Exception as e:
            print("MESSAGE PUSH ERROR:", e)

        return {
            "id": msg.id,
            "conversation_id": msg.conversation_id,
            "sender_id": msg.sender_id,
            "receiver_id": msg.receiver_id,
            "body": msg.body,
            "is_me": True,
            "delivered_at": msg.delivered_at.isoformat()
            if msg.delivered_at
            else None,
            "seen_at": msg.seen_at.isoformat() if msg.seen_at else None,
            "created_at": msg.created_at.isoformat()
            if msg.created_at
            else None,
        }

    async def mark_seen(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        conversation_id: int,
    ) -> dict:
        await self.touch_active(db, user_id=current_user_id)

        conv = await db.get(Conversation, conversation_id)

        if not conv:
            raise ValueError("CONVERSATION_NOT_FOUND")

        if current_user_id not in {conv.user1_id, conv.user2_id}:
            raise ValueError("NOT_ALLOWED")

        await db.execute(
            update(Message)
            .where(
                Message.conversation_id == conversation_id,
                Message.receiver_id == current_user_id,
                Message.seen_at.is_(None),
            )
            .values(seen_at=func.now())
        )

        await db.execute(
            update(UserStats)
            .where(UserStats.user_id == current_user_id)
            .values(unread_messages_count=0)
        )

        await db.commit()

        return {"status": "seen"}

    async def remove_conversation_for_me(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        conversation_id: int,
    ) -> dict:
        await self.touch_active(db, user_id=current_user_id)

        conv = await db.get(Conversation, conversation_id)

        if not conv:
            raise ValueError("CONVERSATION_NOT_FOUND")

        if current_user_id not in {conv.user1_id, conv.user2_id}:
            raise ValueError("NOT_ALLOWED")

        hidden = ConversationHidden(
            conversation_id=conversation_id,
            user_id=current_user_id,
        )

        db.add(hidden)

        try:
            await db.commit()
            await db.refresh(hidden)
        except IntegrityError:
            await db.rollback()
            return {
                "status": "already_removed",
                "conversation_id": conversation_id,
            }

        return {
            "status": "removed",
            "conversation_id": conversation_id,
        }

    async def restore_conversation_for_me(
        self,
        db: AsyncSession,
        *,
        current_user_id: int,
        conversation_id: int,
    ) -> dict:
        await self.touch_active(db, user_id=current_user_id)

        result = await db.execute(
            select(ConversationHidden).where(
                ConversationHidden.conversation_id == conversation_id,
                ConversationHidden.user_id == current_user_id,
            )
        )

        hidden = result.scalar_one_or_none()

        if not hidden:
            await db.commit()
            return {
                "status": "not_removed",
                "conversation_id": conversation_id,
            }

        await db.delete(hidden)
        await db.commit()

        return {
            "status": "restored",
            "conversation_id": conversation_id,
        }

    async def block_user(
        self,
        db: AsyncSession,
        *,
        blocker_id: int,
        blocked_id: int,
    ) -> dict:
        await self.touch_active(db, user_id=blocker_id)

        if blocker_id == blocked_id:
            raise ValueError("CANNOT_BLOCK_YOURSELF")

        blocked = await db.get(User, blocked_id)
        if not blocked:
            raise ValueError("USER_NOT_FOUND")

        block = UserBlock(blocker_id=blocker_id, blocked_id=blocked_id)
        db.add(block)

        try:
            await db.commit()
            await db.refresh(block)
        except IntegrityError:
            await db.rollback()
            return {"status": "already_blocked"}

        return {
            "status": "blocked",
            "block_id": block.id,
        }

    async def unblock_user(
        self,
        db: AsyncSession,
        *,
        blocker_id: int,
        blocked_id: int,
    ) -> dict:
        await self.touch_active(db, user_id=blocker_id)

        if blocker_id == blocked_id:
            raise ValueError("CANNOT_UNBLOCK_YOURSELF")

        result = await db.execute(
            select(UserBlock).where(
                UserBlock.blocker_id == blocker_id,
                UserBlock.blocked_id == blocked_id,
            )
        )

        block = result.scalar_one_or_none()

        if not block:
            await db.commit()
            return {"status": "not_blocked"}

        await db.delete(block)
        await db.commit()

        return {"status": "unblocked"}

    async def report_user(
        self,
        db: AsyncSession,
        *,
        reporter_id: int,
        reported_id: int,
        reason: str,
        details: str | None = None,
    ) -> dict:
        await self.touch_active(db, user_id=reporter_id)

        if reporter_id == reported_id:
            raise ValueError("CANNOT_REPORT_YOURSELF")

        reported = await db.get(User, reported_id)
        if not reported:
            raise ValueError("USER_NOT_FOUND")

        safe_reason = self._clean_text(reason)[:80]
        safe_details = self._clean_text(details or "")[:500] or None

        if not safe_reason:
            raise ValueError("REPORT_REASON_REQUIRED")

        report = UserReport(
            reporter_id=reporter_id,
            reported_id=reported_id,
            reason=safe_reason,
            details=safe_details,
        )

        db.add(report)

        try:
            await db.commit()
            await db.refresh(report)
        except IntegrityError:
            await db.rollback()
            return {"status": "already_reported"}

        return {
            "status": "reported",
            "report_id": report.id,
        }