from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User
from Backend.Social_free.services.social_match_service import SocialMatchService


router = APIRouter(prefix="/social", tags=["Social Matches"])

match_service = SocialMatchService()


@router.post("/users/{target_user_id}/match-request")
async def send_match_request(
    target_user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await match_service.send_match_request(
            db=db,
            sender_id=current_user.id,
            receiver_id=target_user_id,
        )

        return {
            "status": "success",
            "match_status": result["status"],
            "request_id": result.get("request_id"),
            "match_id": result.get("match_id"),  # ✅ DODANO
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/match-requests/{request_id}/accept")
async def accept_match_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await match_service.accept_match_request(
            db=db,
            current_user_id=current_user.id,
            request_id=request_id,
        )

        return {
            "status": "success",
            "match_status": result["status"],
            "request_id": result.get("request_id"),
            "match_id": result.get("match_id"),  # ✅ DODANO
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/match-requests/{request_id}/reject")
async def reject_match_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await match_service.reject_match_request(
            db=db,
            current_user_id=current_user.id,
            request_id=request_id,
        )

        return {
            "status": "success",
            "match_status": result["status"],
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/match-requests/{request_id}")
async def cancel_match_request(
    request_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await match_service.cancel_match_request(
            db=db,
            current_user_id=current_user.id,
            request_id=request_id,
        )

        return {
            "status": "success",
            "match_status": result["status"],
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/match-requests/incoming")
async def list_incoming_match_requests(
    limit: int = Query(30, ge=1, le=50),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    requests = await match_service.list_incoming_requests(
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


@router.get("/matches")
async def list_matches(
    limit: int = Query(30, ge=1, le=50),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    matches = await match_service.list_matches(
        db=db,
        user_id=current_user.id,
        limit=limit,
        offset=offset,
    )

    return {
        "status": "success",
        "count": len(matches),
        "matches": matches,
    }