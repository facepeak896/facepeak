from sqlalchemy import select, or_, and_, func
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.models.follow import Follow
from Backend.Social_free.models.match_request import MatchRequest
from Backend.Social_free.models.match_table import Match
from Backend.Social_free.models.message_request import MessageRequest
from Backend.Social_free.models.conversation import Conversation
from Backend.Social_free.models.conversation_hidden import ConversationHidden
from Backend.Social_free.models.message import Message
from Backend.Social_free.models.user_block import UserBlock


class SocialStateService:
    async def get_badges(
        self,
        db: AsyncSession,
        *,
        user_id: int,
    ) -> dict:
        message_requests = await db.scalar(
            select(func.count(MessageRequest.id)).where(
                MessageRequest.receiver_id == user_id,
                MessageRequest.status == "pending",
            )
        ) or 0

        match_requests = await db.scalar(
            select(func.count(MatchRequest.id)).where(
                MatchRequest.receiver_id == user_id,
                MatchRequest.status == "pending",
            )
        ) or 0

        dm_unread = await db.scalar(
            select(func.count(Message.id)).where(
                Message.receiver_id == user_id,
                Message.seen_at.is_(None),
                Message.is_deleted == False,
            )
        ) or 0

        follow_events = 0
        comment_requests = 0

        total = (
            int(message_requests)
            + int(match_requests)
            + int(dm_unread)
            + int(follow_events)
            + int(comment_requests)
        )

        return {
            "dm_unread": int(dm_unread),
            "message_requests": int(message_requests),
            "match_requests": int(match_requests),
            "follow_events": int(follow_events),
            "comment_requests": int(comment_requests),
            "total": int(total),
        }

    async def get_action_state(
        self,
        db: AsyncSession,
        *,
        viewer_id: int,
        target_id: int,
    ) -> dict:
        states = await self.hydrate_action_states(
            db=db,
            viewer_id=viewer_id,
            target_ids=[target_id],
        )

        return states.get(target_id, self._empty_state(viewer_id, target_id))

    async def hydrate_users_with_action_state(
        self,
        db: AsyncSession,
        *,
        viewer_id: int,
        users: list[dict],
    ) -> list[dict]:
        target_ids = [
            int(u["user_id"] if "user_id" in u else u["id"])
            for u in users
            if (u.get("user_id") or u.get("id"))
        ]

        states = await self.hydrate_action_states(
            db=db,
            viewer_id=viewer_id,
            target_ids=target_ids,
        )

        hydrated = []

        for user in users:
            target_id = int(user.get("user_id") or user.get("id"))
            hydrated.append({
                **user,
                **states.get(target_id, self._empty_state(viewer_id, target_id)),
            })

        return hydrated

    async def hydrate_action_states(
        self,
        db: AsyncSession,
        *,
        viewer_id: int,
        target_ids: list[int],
    ) -> dict[int, dict]:
        target_ids = list(set([i for i in target_ids if i and i != viewer_id]))

        states = {
            target_id: self._empty_state(viewer_id, target_id)
            for target_id in target_ids
        }

        if not target_ids:
            return states

        # BLOCKS
        block_rows = await db.execute(
            select(UserBlock).where(
                or_(
                    and_(
                        UserBlock.blocker_id == viewer_id,
                        UserBlock.blocked_id.in_(target_ids),
                    ),
                    and_(
                        UserBlock.blocked_id == viewer_id,
                        UserBlock.blocker_id.in_(target_ids),
                    ),
                )
            )
        )

        for block in block_rows.scalars().all():
            if block.blocker_id == viewer_id:
                target_id = block.blocked_id
                states[target_id]["blocked_by_me"] = True
                states[target_id]["block_status"] = "blocked_by_me"
            else:
                target_id = block.blocker_id
                states[target_id]["blocked_me"] = True
                states[target_id]["block_status"] = "blocked_me"

        for target_id, state in states.items():
            # Ako su se oboje blokirali, hard lock.
            if state["blocked_by_me"] and state["blocked_me"]:
                state["block_status"] = "mutual_block"
                state["can_follow_request"] = False
                state["can_match_request"] = False
                state["can_dm_request"] = False

            # Ako je target blokirao viewera, hard lock.
            elif state["blocked_me"]:
                state["can_follow_request"] = False
                state["can_match_request"] = False
                state["can_dm_request"] = False

            # Ako je viewer blokirao targeta, dopusti akcije.
            # Servisi već automatski brišu own block kad viewer pošalje novu akciju.
            elif state["blocked_by_me"]:
                state["can_follow_request"] = True
                state["can_match_request"] = True
                state["can_dm_request"] = True

        # FOLLOW
        follow_rows = await db.execute(
            select(Follow).where(
                Follow.follower_id == viewer_id,
                Follow.following_id.in_(target_ids),
            )
        )

        for follow in follow_rows.scalars().all():
            target_id = follow.following_id
            states[target_id]["follow_status"] = follow.status
            states[target_id]["is_following"] = follow.status == "accepted"

            if not states[target_id]["blocked_by_me"]:
                states[target_id]["can_follow_request"] = follow.status != "accepted"

        # MATCHES
        match_pairs = [(min(viewer_id, t), max(viewer_id, t)) for t in target_ids]

        match_rows = await db.execute(
            select(Match).where(
                or_(
                    *[
                        and_(Match.user1_id == a, Match.user2_id == b)
                        for a, b in match_pairs
                    ]
                )
            )
        )

        for match in match_rows.scalars().all():
            target_id = match.user2_id if match.user1_id == viewer_id else match.user1_id
            states[target_id]["is_matched"] = True
            states[target_id]["match_status"] = "accepted"

            if not states[target_id]["blocked_by_me"]:
                states[target_id]["can_match_request"] = False

        match_req_rows = await db.execute(
            select(MatchRequest).where(
                or_(
                    and_(
                        MatchRequest.sender_id == viewer_id,
                        MatchRequest.receiver_id.in_(target_ids),
                    ),
                    and_(
                        MatchRequest.receiver_id == viewer_id,
                        MatchRequest.sender_id.in_(target_ids),
                    ),
                )
            )
        )

        for req in match_req_rows.scalars().all():
            target_id = req.receiver_id if req.sender_id == viewer_id else req.sender_id

            if states[target_id]["is_matched"]:
                continue

            states[target_id]["match_status"] = req.status
            states[target_id]["match_pending"] = req.status == "pending"

            if not states[target_id]["blocked_by_me"]:
                states[target_id]["can_match_request"] = req.status not in {
                    "pending",
                    "accepted",
                }

        # MESSAGE REQUESTS
        msg_req_rows = await db.execute(
            select(MessageRequest).where(
                or_(
                    and_(
                        MessageRequest.sender_id == viewer_id,
                        MessageRequest.receiver_id.in_(target_ids),
                    ),
                    and_(
                        MessageRequest.receiver_id == viewer_id,
                        MessageRequest.sender_id.in_(target_ids),
                    ),
                )
            )
        )

        for req in msg_req_rows.scalars().all():
            target_id = req.receiver_id if req.sender_id == viewer_id else req.sender_id

            states[target_id]["message_request_status"] = req.status
            states[target_id]["dm_status"] = req.status

            if not states[target_id]["blocked_by_me"]:
                states[target_id]["can_dm_request"] = req.status not in {
                    "pending",
                    "accepted",
                }

        # CONVERSATIONS
        conv_rows = await db.execute(
            select(Conversation).where(
                or_(
                    and_(
                        Conversation.user1_id == viewer_id,
                        Conversation.user2_id.in_(target_ids),
                    ),
                    and_(
                        Conversation.user2_id == viewer_id,
                        Conversation.user1_id.in_(target_ids),
                    ),
                )
            )
        )

        conversations = conv_rows.scalars().all()
        conv_by_target = {}

        for conv in conversations:
            target_id = conv.user2_id if conv.user1_id == viewer_id else conv.user1_id
            conv_by_target[target_id] = conv

            states[target_id]["has_conversation"] = True
            states[target_id]["message_request_status"] = "accepted"
            states[target_id]["dm_status"] = "accepted"

            if not states[target_id]["blocked_by_me"]:
                states[target_id]["can_dm_request"] = False

            states[target_id]["conversation_id"] = conv.id

        if conversations:
            conv_ids = [c.id for c in conversations]

            hidden_rows = await db.execute(
                select(ConversationHidden).where(
                    ConversationHidden.conversation_id.in_(conv_ids)
                )
            )

            for hidden in hidden_rows.scalars().all():
                for target_id, conv in conv_by_target.items():
                    if conv.id != hidden.conversation_id:
                        continue

                    if hidden.user_id == viewer_id:
                        states[target_id]["dm_status"] = "removed_by_me"
                        states[target_id]["can_dm_request"] = True
                    else:
                        states[target_id]["dm_status"] = "removed_by_other"
                        states[target_id]["can_dm_request"] = False

        # Final safety: mutual block ili blocked_me uvijek hard lock.
        for state in states.values():
            if state["blocked_me"]:
                if state["blocked_by_me"]:
                    state["block_status"] = "mutual_block"

                state["can_follow_request"] = False
                state["can_match_request"] = False
                state["can_dm_request"] = False

        return states

    def _empty_state(self, viewer_id: int, target_id: int) -> dict:
        is_me = viewer_id == target_id

        return {
            "is_me": is_me,

            "blocked_by_me": False,
            "blocked_me": False,
            "block_status": "",

            "is_following": False,
            "follow_status": "",
            "follow_pending": False,
            "can_follow_request": not is_me,

            "is_matched": False,
            "match_status": "",
            "match_pending": False,
            "can_match_request": not is_me,

            "has_conversation": False,
            "conversation_id": None,
            "message_request_status": "",
            "dm_status": "",
            "can_dm_request": not is_me,
        }