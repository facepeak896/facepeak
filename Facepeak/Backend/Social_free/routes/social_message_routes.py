from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User
from Backend.Social_free.services.social_message_service import SocialMessageService
from Backend.Social_free.services.message_rate_limit_service import MessageRateLimitService
from Backend.Social_free.ws.websocket_manager import manager


router = APIRouter(prefix="/social", tags=["Social Messages"])

message_service = SocialMessageService()


class SendMessageBody(BaseModel):
    body: str = Field(..., min_length=1, max_length=500)


class ReportUserBody(BaseModel):
    reason: str = Field(..., min_length=2, max_length=80)
    details: str | None = Field(default=None, max_length=500)


@router.get("/messages/rate-limit/status")
async def get_message_rate_limit_status(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await MessageRateLimitService.get_status(
        db=db,
        user_id=current_user.id,
    )


@router.post("/users/{target_user_id}/message-request")
async def send_message_request(
    target_user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.send_message_request(
            db=db,
            sender_id=current_user.id,
            receiver_id=target_user_id,
        )

        return {
            "status": "success",
            "message_status": result["status"],
            "request_id": result.get("request_id"),
            "conversation_id": result.get("conversation_id"),
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/message-requests/incoming")
async def list_incoming_message_requests(
    limit: int = Query(30, ge=1, le=50),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    requests = await message_service.list_incoming_requests(
        db=db,
        user_id=current_user.id,
        limit=limit,
        offset=offset,
    )

    return {
        "status": "success",
        "count": len(requests),
        "requests": requests,
    }


@router.post("/message-requests/{request_id}/accept")
async def accept_message_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.accept_message_request(
            db=db,
            current_user_id=current_user.id,
            request_id=request_id,
        )

        return {
            "status": "success",
            "message_status": result["status"],
            "conversation_id": result.get("conversation_id"),
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/message-requests/{request_id}/reject")
async def reject_message_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.reject_message_request(
            db=db,
            current_user_id=current_user.id,
            request_id=request_id,
        )

        return {
            "status": "success",
            "message_status": result["status"],
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/message-requests/{request_id}")
async def cancel_message_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.cancel_message_request(
            db=db,
            current_user_id=current_user.id,
            request_id=request_id,
        )

        return {
            "status": "success",
            "message_status": result["status"],
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/conversations/{conversation_id}/restore")
async def restore_conversation_for_me(
    conversation_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.restore_conversation_for_me(
            db=db,
            current_user_id=current_user.id,
            conversation_id=conversation_id,
        )

        return {
            "status": "success",
            "restore_status": result["status"],
            "conversation_id": result.get("conversation_id"),
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/conversations")
async def list_conversations(
    limit: int = Query(30, ge=1, le=50),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    conversations = await message_service.list_conversations(
        db=db,
        user_id=current_user.id,
        limit=limit,
        offset=offset,
    )

    return {
        "status": "success",
        "count": len(conversations),
        "conversations": conversations,
    }


@router.get("/conversations/{conversation_id}/messages")
async def list_messages(
    conversation_id: int,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        messages = await message_service.list_messages(
            db=db,
            current_user_id=current_user.id,
            conversation_id=conversation_id,
            limit=limit,
            offset=offset,
        )

        return {
            "status": "success",
            "count": len(messages),
            "messages": messages,
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/conversations/{conversation_id}/messages")
async def send_message(
    conversation_id: int,
    payload: SendMessageBody,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        rate_limit = await MessageRateLimitService.consume_or_raise(
            db=db,
            user_id=current_user.id,
        )

        message = await message_service.send_message(
            db=db,
            current_user_id=current_user.id,
            conversation_id=conversation_id,
            body=payload.body,
        )

        message["rate_limit"] = rate_limit

        # WebSocket realtime notify receiver.
        # HTTP/DB remains source of truth; if WS fails, chat still works.
        try:
            await manager.send_to_user(
                message["receiver_id"],
                {
                    "type": "receive_message",
                    "message": message,
                },
            )
        except Exception:
            pass

        return {
            "status": "success",
            "message": message,
            "rate_limit": rate_limit,
        }

    except HTTPException:
        raise

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/conversations/{conversation_id}/seen")
async def mark_conversation_seen(
    conversation_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.mark_seen(
            db=db,
            current_user_id=current_user.id,
            conversation_id=conversation_id,
        )

        return {
            "status": "success",
            "seen_status": result["status"],
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/users/{target_user_id}/block")
async def block_user(
    target_user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.block_user(
            db=db,
            blocker_id=current_user.id,
            blocked_id=target_user_id,
        )

        return {
            "status": "success",
            "block_status": result["status"],
            "block_id": result.get("block_id"),
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/users/{target_user_id}/report")
async def report_user(
    target_user_id: int,
    payload: ReportUserBody,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.report_user(
            db=db,
            reporter_id=current_user.id,
            reported_id=target_user_id,
            reason=payload.reason,
            details=payload.details,
        )

        return {
            "status": "success",
            "report_status": result["status"],
            "report_id": result.get("report_id"),
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/users/{target_user_id}/block")
async def unblock_user(
    target_user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.unblock_user(
            db=db,
            blocker_id=current_user.id,
            blocked_id=target_user_id,
        )

        return {
            "status": "success",
            "block_status": result["status"],
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/conversations/{conversation_id}")
async def remove_conversation_for_me(
    conversation_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await message_service.remove_conversation_for_me(
            db=db,
            current_user_id=current_user.id,
            conversation_id=conversation_id,
        )

        return {
            "status": "success",
            "remove_status": result["status"],
            "conversation_id": result.get("conversation_id"),
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))