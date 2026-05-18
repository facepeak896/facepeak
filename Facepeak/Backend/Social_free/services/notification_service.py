from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from firebase_admin import messaging
from sqlalchemy import delete, func, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.models.notification_log import NotificationLog
from Backend.Social_free.models.user_push_token import UserPushToken
from Backend.Social_free.ws.websocket_manager import manager


class NotificationService:
    MESSAGE_DAILY_PUSH_LIMIT = 1
    MESSAGE_REQUEST_DAILY_PUSH_LIMIT = 5
    FOLLOW_DAILY_PUSH_LIMIT = 3
    FOLLOW_REQUEST_DAILY_PUSH_LIMIT = 5
    MATCH_DAILY_PUSH_LIMIT = 5
    MATCH_REQUEST_DAILY_PUSH_LIMIT = 3

    MAX_FCM_BATCH = 500

    @staticmethod
    def _now() -> datetime:
        return datetime.now(timezone.utc)

    @staticmethod
    def _day_key() -> str:
        return datetime.now(timezone.utc).strftime("%Y-%m-%d")

    @staticmethod
    def _string_data(data: dict[str, Any] | None) -> dict[str, str]:
        return {str(k): str(v) for k, v in (data or {}).items() if v is not None}

    @classmethod
    async def _get_token_rows(cls, db: AsyncSession, user_id: int):
        stmt = select(UserPushToken).where(UserPushToken.user_id == user_id)

        if hasattr(UserPushToken, "is_active"):
            stmt = stmt.where(UserPushToken.is_active == True)

        result = await db.execute(stmt)
        return result.scalars().all()

    @classmethod
    async def _get_tokens(cls, db: AsyncSession, user_id: int) -> list[str]:
        rows = await cls._get_token_rows(db, user_id)

        tokens: list[str] = []

        for row in rows:
            token = (
                getattr(row, "fcm_token", None)
                or getattr(row, "token", None)
                or getattr(row, "push_token", None)
            )

            if token and str(token).strip():
                tokens.append(str(token).strip())

        return list(dict.fromkeys(tokens))

    @classmethod
    async def _delete_invalid_tokens(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
        invalid_tokens: list[str],
    ) -> None:
        if not invalid_tokens:
            return

        rows = await cls._get_token_rows(db, user_id)

        invalid_set = set(invalid_tokens)
        ids_to_delete: list[int] = []

        for row in rows:
            token = (
                getattr(row, "fcm_token", None)
                or getattr(row, "token", None)
                or getattr(row, "push_token", None)
            )

            if token in invalid_set:
                row_id = getattr(row, "id", None)
                if row_id is not None:
                    ids_to_delete.append(row_id)

        if not ids_to_delete:
            return

        await db.execute(
            delete(UserPushToken).where(UserPushToken.id.in_(ids_to_delete))
        )

    @classmethod
    async def _count_sent_last_24h(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
        notification_type: str,
    ) -> int:
        since = cls._now() - timedelta(hours=24)

        result = await db.execute(
            select(func.count(NotificationLog.id))
            .where(NotificationLog.user_id == user_id)
            .where(NotificationLog.type == notification_type)
            .where(NotificationLog.status == "sent")
            .where(NotificationLog.sent_at >= since)
        )

        return int(result.scalar() or 0)

    @classmethod
    async def _create_log(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
        notification_type: str,
        dedupe_key: str,
        title: str,
        body: str,
        data: dict[str, Any] | None = None,
        send_at: datetime | None = None,
        status: str = "pending",
    ) -> int | None:
        stmt = (
            insert(NotificationLog)
            .values(
                user_id=user_id,
                type=notification_type,
                dedupe_key=dedupe_key,
                title=title,
                body=body,
                data=data or {},
                send_at=send_at,
                status=status,
                created_at=cls._now(),
                updated_at=cls._now(),
            )
            .on_conflict_do_nothing(
                constraint="uq_notification_logs_dedupe_key"
            )
            .returning(NotificationLog.id)
        )

        result = await db.execute(stmt)
        log_id = result.scalar_one_or_none()

        return int(log_id) if log_id is not None else None

    @classmethod
    async def _mark_log(
        cls,
        db: AsyncSession,
        *,
        log_id: int,
        status: str,
        error: str | None = None,
    ) -> None:
        now = cls._now()

        values: dict[str, Any] = {
            "status": status,
            "updated_at": now,
        }

        if status == "sent":
            values["sent_at"] = now

        if status == "skipped":
            values["skipped_at"] = now

        if status == "failed":
            values["failed_at"] = now

        if error:
            values["error"] = error[:2000]

        await db.execute(
            update(NotificationLog)
            .where(NotificationLog.id == log_id)
            .values(**values)
        )

    @classmethod
    async def _increase_attempts(
        cls,
        db: AsyncSession,
        *,
        log_id: int,
    ) -> None:
        await db.execute(
            update(NotificationLog)
            .where(NotificationLog.id == log_id)
            .values(
                attempts=NotificationLog.attempts + 1,
                updated_at=cls._now(),
            )
        )

    @classmethod
    async def _send_fcm_to_tokens(
        cls,
        *,
        tokens: list[str],
        title: str,
        body: str,
        data: dict[str, Any] | None = None,
    ) -> list[str]:
        clean_tokens = [
            str(t).strip()
            for t in tokens
            if t and str(t).strip()
        ]

        clean_tokens = list(dict.fromkeys(clean_tokens))

        if not clean_tokens:
            return []

        invalid_tokens: list[str] = []

        for i in range(0, len(clean_tokens), cls.MAX_FCM_BATCH):
            batch = clean_tokens[i:i + cls.MAX_FCM_BATCH]

            msg = messaging.MulticastMessage(
                tokens=batch,
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=cls._string_data(data),
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        channel_id="default",
                        sound="default",
                    ),
                ),
                apns=messaging.APNSConfig(
                    headers={
                        "apns-priority": "10",
                    },
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound="default",
                        ),
                    ),
                ),
            )

            response = messaging.send_each_for_multicast(msg)

            for idx, item in enumerate(response.responses):
                if item.success:
                    continue

                err = str(item.exception).lower()

                if (
                    "registration-token-not-registered" in err
                    or "requested entity was not found" in err
                    or "invalid-registration-token" in err
                    or "invalid-argument" in err
                ):
                    invalid_tokens.append(batch[idx])

        return invalid_tokens

    @classmethod
    async def send_now(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
        notification_type: str,
        dedupe_key: str,
        title: str,
        body: str,
        data: dict[str, Any] | None = None,
        daily_limit: int | None = None,
    ) -> dict[str, Any]:
        if daily_limit is not None:
            sent_today = await cls._count_sent_last_24h(
                db,
                user_id=user_id,
                notification_type=notification_type,
            )

            if sent_today >= daily_limit:
                log_id = await cls._create_log(
                    db,
                    user_id=user_id,
                    notification_type=notification_type,
                    dedupe_key=dedupe_key,
                    title=title,
                    body=body,
                    data=data,
                    status="skipped",
                )

                if log_id:
                    await cls._mark_log(
                        db,
                        log_id=log_id,
                        status="skipped",
                        error="DAILY_PUSH_LIMIT_REACHED",
                    )

                await db.commit()

                return {
                    "status": "skipped",
                    "reason": "DAILY_PUSH_LIMIT_REACHED",
                }

        log_id = await cls._create_log(
            db,
            user_id=user_id,
            notification_type=notification_type,
            dedupe_key=dedupe_key,
            title=title,
            body=body,
            data=data,
            status="pending",
        )

        if log_id is None:
            return {
                "status": "skipped",
                "reason": "DUPLICATE_DEDUPE_KEY",
            }

        tokens = await cls._get_tokens(db, user_id)

        if not tokens:
            await cls._mark_log(
                db,
                log_id=log_id,
                status="skipped",
                error="NO_PUSH_TOKEN",
            )

            await db.commit()

            return {
                "status": "skipped",
                "reason": "NO_PUSH_TOKEN",
            }

        try:
            await cls._increase_attempts(db, log_id=log_id)

            invalid_tokens = await cls._send_fcm_to_tokens(
                tokens=tokens,
                title=title,
                body=body,
                data=data,
            )

            await cls._delete_invalid_tokens(
                db,
                user_id=user_id,
                invalid_tokens=invalid_tokens,
            )

            await cls._mark_log(
                db,
                log_id=log_id,
                status="sent",
            )

            await db.commit()

            return {
                "status": "sent",
                "notification_id": log_id,
                "invalid_tokens_removed": len(invalid_tokens),
            }

        except Exception as e:
            await cls._mark_log(
                db,
                log_id=log_id,
                status="failed",
                error=str(e),
            )

            await db.commit()

            return {
                "status": "failed",
                "reason": str(e),
            }

    @classmethod
    async def schedule(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
        notification_type: str,
        dedupe_key: str,
        title: str,
        body: str,
        send_at: datetime,
        data: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        if send_at.tzinfo is None:
            send_at = send_at.replace(tzinfo=timezone.utc)

        log_id = await cls._create_log(
            db,
            user_id=user_id,
            notification_type=notification_type,
            dedupe_key=dedupe_key,
            title=title,
            body=body,
            data=data,
            send_at=send_at,
            status="pending",
        )

        if log_id is None:
            return {
                "status": "skipped",
                "reason": "DUPLICATE_DEDUPE_KEY",
            }

        await db.commit()

        return {
            "status": "scheduled",
            "notification_id": log_id,
            "send_at": send_at.isoformat(),
        }

    @classmethod
    async def process_due(
        cls,
        db: AsyncSession,
        *,
        limit: int = 100,
    ) -> dict[str, Any]:
        now = cls._now()

        result = await db.execute(
            select(NotificationLog)
            .where(NotificationLog.status == "pending")
            .where(NotificationLog.send_at.is_not(None))
            .where(NotificationLog.send_at <= now)
            .where(NotificationLog.attempts < NotificationLog.max_attempts)
            .order_by(NotificationLog.send_at.asc())
            .with_for_update(skip_locked=True)
            .limit(limit)
        )

        logs = result.scalars().all()

        sent = 0
        skipped = 0
        failed = 0

        for log in logs:
            tokens = await cls._get_tokens(db, log.user_id)

            if not tokens:
                await cls._mark_log(
                    db,
                    log_id=log.id,
                    status="skipped",
                    error="NO_PUSH_TOKEN",
                )
                skipped += 1
                continue

            try:
                await cls._increase_attempts(db, log_id=log.id)

                invalid_tokens = await cls._send_fcm_to_tokens(
                    tokens=tokens,
                    title=log.title,
                    body=log.body,
                    data=log.data or {},
                )

                await cls._delete_invalid_tokens(
                    db,
                    user_id=log.user_id,
                    invalid_tokens=invalid_tokens,
                )

                await cls._mark_log(
                    db,
                    log_id=log.id,
                    status="sent",
                )

                sent += 1

            except Exception as e:
                next_attempts = int(log.attempts or 0) + 1

                if next_attempts >= int(log.max_attempts or 3):
                    await cls._mark_log(
                        db,
                        log_id=log.id,
                        status="failed",
                        error=str(e),
                    )
                else:
                    await db.execute(
                        update(NotificationLog)
                        .where(NotificationLog.id == log.id)
                        .values(
                            attempts=next_attempts,
                            error=str(e)[:2000],
                            updated_at=cls._now(),
                        )
                    )

                failed += 1

        await db.commit()

        return {
            "status": "success",
            "processed": len(logs),
            "sent": sent,
            "skipped": skipped,
            "failed": failed,
        }

    @classmethod
    async def on_message_sent(
        cls,
        db: AsyncSession,
        *,
        sender_id: int,
        receiver_id: int,
        conversation_id: int,
        message_id: int,
        sender_name: str = "Someone",
        preview: str = "Sent you a message",
    ) -> dict[str, Any]:
        try:
            if manager.is_user_in_conversation(
                user_id=receiver_id,
                conversation_id=conversation_id,
            ):
                return {
                    "status": "skipped",
                    "reason": "USER_ACTIVE_IN_CONVERSATION",
                }
        except Exception:
            pass

        day = cls._day_key()

        return await cls.send_now(
            db=db,
            user_id=receiver_id,
            notification_type="message",
            dedupe_key=f"message:{receiver_id}:{conversation_id}:{day}",
            title="💬 New Message",
            body=f"{sender_name}: {preview[:90]}",
            data={
                "type": "message",
                "conversation_id": conversation_id,
                "sender_id": sender_id,
                "message_id": message_id,
            },
            daily_limit=cls.MESSAGE_DAILY_PUSH_LIMIT,
        )

    @classmethod
    async def on_message_request_created(
        cls,
        db: AsyncSession,
        *,
        sender_id: int,
        receiver_id: int,
        request_id: int,
        sender_name: str = "Someone",
    ) -> dict[str, Any]:
        day = cls._day_key()

        return await cls.send_now(
            db=db,
            user_id=receiver_id,
            notification_type="message_request",
            dedupe_key=f"message_request:{receiver_id}:{sender_id}:{day}",
            title="📩 New Message Request",
            body=f"{sender_name} sent you a message request",
            data={
                "type": "message_request",
                "request_id": request_id,
                "sender_id": sender_id,
            },
            daily_limit=cls.MESSAGE_REQUEST_DAILY_PUSH_LIMIT,
        )

    @classmethod
    async def on_match_request_created(
        cls,
        db: AsyncSession,
        *,
        sender_id: int,
        receiver_id: int,
        request_id: int,
        sender_name: str = "Someone",
    ) -> dict[str, Any]:
        day = cls._day_key()

        return await cls.send_now(
            db=db,
            user_id=receiver_id,
            notification_type="match_request",
            dedupe_key=f"match_request:{receiver_id}:{sender_id}:{day}",
            title="💜 New Match Request",
            body=f"{sender_name} wants to match with you",
            data={
                "type": "match_request",
                "request_id": request_id,
                "sender_id": sender_id,
            },
            daily_limit=cls.MATCH_REQUEST_DAILY_PUSH_LIMIT,
        )

    @classmethod
    async def on_follow_request_created(
        cls,
        db: AsyncSession,
        *,
        sender_id: int,
        receiver_id: int,
        request_id: int,
        sender_name: str = "Someone",
    ) -> dict[str, Any]:
        day = cls._day_key()

        return await cls.send_now(
            db=db,
            user_id=receiver_id,
            notification_type="follow_request",
            dedupe_key=f"follow_request:{receiver_id}:{sender_id}:{day}",
            title="👤 New Follow Request",
            body=f"{sender_name} requested to follow you",
            data={
                "type": "follow_request",
                "request_id": request_id,
                "sender_id": sender_id,
            },
            daily_limit=cls.FOLLOW_REQUEST_DAILY_PUSH_LIMIT,
        )

    @classmethod
    async def on_follow_created(
        cls,
        db: AsyncSession,
        *,
        follower_id: int,
        following_id: int,
        follower_name: str = "Someone",
    ) -> dict[str, Any]:
        day = cls._day_key()

        return await cls.send_now(
            db=db,
            user_id=following_id,
            notification_type="follow",
            dedupe_key=f"follow:{following_id}:{follower_id}:{day}",
            title="👥 New Follower",
            body=f"{follower_name} started following you",
            data={
                "type": "follow",
                "follower_id": follower_id,
            },
            daily_limit=cls.FOLLOW_DAILY_PUSH_LIMIT,
        )

    @classmethod
    async def on_match_created(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
        other_user_id: int,
        match_id: int,
        other_name: str = "Someone",
    ) -> dict[str, Any]:
        return await cls.send_now(
            db=db,
            user_id=user_id,
            notification_type="match",
            dedupe_key=f"match:{user_id}:{match_id}",
            title="🔥 New Match",
            body=f"You matched with {other_name}",
            data={
                "type": "match",
                "match_id": match_id,
                "user_id": other_user_id,
            },
            daily_limit=cls.MATCH_DAILY_PUSH_LIMIT,
        )

    @classmethod
    async def schedule_chat_limit_reset(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
        reset_at: datetime,
    ) -> dict[str, Any]:
        return await cls.schedule(
            db=db,
            user_id=user_id,
            notification_type="chat_limit_reset",
            dedupe_key=f"chat_limit_reset:{user_id}:{reset_at.isoformat()}",
            title="🔓 Messages Unlocked",
            body="You can send messages again.",
            send_at=reset_at,
            data={
                "type": "chat_limit_reset",
            },
        )

    @classmethod
    async def schedule_social_live_update_3d(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
    ) -> dict[str, Any]:
        send_at = cls._now() + timedelta(days=3)

        return await cls.schedule(
            db=db,
            user_id=user_id,
            notification_type="social_live_update",
            dedupe_key=f"social_live_update:{user_id}:{send_at.date().isoformat()}",
            title="✨ Your Profile Is Still Live",
            body="Update your profile to get more reach on Social.",
            send_at=send_at,
            data={
                "type": "social_live_update",
            },
        )

    @classmethod
    async def schedule_profile_reminder_3d(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
    ) -> dict[str, Any]:
        send_at = cls._now() + timedelta(days=3)

        return await cls.schedule(
            db=db,
            user_id=user_id,
            notification_type="profile_update_reminder",
            dedupe_key=f"profile_update_reminder:{user_id}:{send_at.date().isoformat()}",
            title="✨ Update Your Profile",
            body="New photos can improve your reach.",
            send_at=send_at,
            data={
                "type": "profile_update_reminder",
            },
        )

    @classmethod
    async def schedule_premium_teaser(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
        delay_hours: int = 6,
    ) -> dict[str, Any]:
        send_at = cls._now() + timedelta(hours=delay_hours)

        return await cls.schedule(
            db=db,
            user_id=user_id,
            notification_type="premium_teaser",
            dedupe_key=f"premium_teaser:{user_id}:{send_at.date().isoformat()}",
            title="✨ Unlock Your Next Move",
            body="Premium shows exactly what to improve next.",
            send_at=send_at,
            data={
                "type": "premium_teaser",
            },
        )

    @classmethod
    async def on_daily_smart_push(
        cls,
        db: AsyncSession,
        *,
        user_id: int,
    ) -> dict[str, Any]:
        day = cls._day_key()

        return await cls.send_now(
            db=db,
            user_id=user_id,
            notification_type="daily_smart_push",
            dedupe_key=f"daily_smart_push:{user_id}:{day}",
            title="🚀 You're Climbing",
            body="People are viewing your profile again.",
            data={
                "type": "daily_smart_push",
            },
            daily_limit=1,
        )