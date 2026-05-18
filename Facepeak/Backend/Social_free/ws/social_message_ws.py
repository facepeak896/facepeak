from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from sqlalchemy import select

from Backend.Social_free.ws.websocket_manager import manager
from Backend.Social_free.ws.auth_ws import get_current_user_ws
from Backend.Social_free.login.database import AsyncSessionLocal
from Backend.Social_free.services.social_message_service import SocialMessageService
from Backend.Social_free.models.conversation import Conversation
from Backend.Social_free.redis import safe_set

router = APIRouter()
service = SocialMessageService()


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@router.websocket("/ws/social-chat")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(...),
):
    try:
        user_id = get_current_user_ws(token)
    except Exception:
        await websocket.close()
        return

    await manager.connect(user_id, websocket)
    await safe_set(f"online:user:{user_id}", "1", ex=60)

    try:
        while True:
            data = await websocket.receive_json()
            event_type = data.get("type")

            if event_type == "heartbeat":
                await safe_set(f"online:user:{user_id}", "1", ex=60)
                await websocket.send_json({"type": "pong"})

            elif event_type == "delivered_ack":
                message_id = data.get("message_id")

                if not message_id:
                    continue

                async with AsyncSessionLocal() as db:
                    result = await service.mark_delivered(
                        db=db,
                        message_id=int(message_id),
                        receiver_id=user_id,
                    )

                    if result["status"] == "delivered":
                        delivered_at = utc_now_iso()

                        await manager.send_to_user(
                            result["sender_id"],
                            {
                                "type": "delivered",
                                "message_id": result["message_id"],
                                "conversation_id": result["conversation_id"],
                                "delivered_at": delivered_at,
                            },
                        )

            elif event_type == "seen":
                conversation_id = data.get("conversation_id")

                if not conversation_id:
                    continue

                conversation_id = int(conversation_id)
                seen_at = utc_now_iso()

                async with AsyncSessionLocal() as db:
                    await service.mark_seen(
                        db=db,
                        current_user_id=user_id,
                        conversation_id=conversation_id,
                    )

                    result = await db.execute(
                        select(Conversation).where(
                            Conversation.id == conversation_id
                        )
                    )
                    conv = result.scalar_one_or_none()

                    if conv:
                        other_user = (
                            conv.user2_id
                            if conv.user1_id == user_id
                            else conv.user1_id
                        )

                        await manager.send_to_user(
                            other_user,
                            {
                                "type": "seen",
                                "conversation_id": conversation_id,
                                "seen_by_user_id": user_id,
                                "seen_at": seen_at,
                            },
                        )

    except WebSocketDisconnect:
        await manager.disconnect(user_id,websocket)

    except Exception:
        await manager.disconnect(user_id,websocket)
        try:
            await websocket.close()
        except Exception:
            pass