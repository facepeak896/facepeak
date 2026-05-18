from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.models.user import User
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.services.social_follow_service import SocialFollowService


router = APIRouter(
    prefix="/api/v1/social",
    tags=["Social Follow"],
)

service = SocialFollowService()


def _handle_error(e: Exception):
    msg = str(e)

    if "CANNOT_FOLLOW_YOURSELF" in msg:
        raise HTTPException(status_code=400, detail="CANNOT_FOLLOW_YOURSELF")

    if "CANNOT_UNFOLLOW_YOURSELF" in msg:
        raise HTTPException(status_code=400, detail="CANNOT_UNFOLLOW_YOURSELF")

    if "CANNOT_REMOVE_YOURSELF" in msg:
        raise HTTPException(status_code=400, detail="CANNOT_REMOVE_YOURSELF")

    if "USER_NOT_FOUND" in msg:
        raise HTTPException(status_code=404, detail="USER_NOT_FOUND")

    if "USER_BLOCKED" in msg:
        raise HTTPException(status_code=403, detail="USER_BLOCKED")

    raise HTTPException(status_code=400, detail=msg)


@router.post("/users/{target_user_id}/follow")
async def follow_user(
    target_user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return await service.follow_user(
            db,
            follower_id=current_user.id,
            following_id=target_user_id,
        )
    except Exception as e:
        _handle_error(e)


@router.delete("/users/{target_user_id}/follow")
async def unfollow_user(
    target_user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return await service.unfollow_user(
            db,
            follower_id=current_user.id,
            following_id=target_user_id,
        )
    except Exception as e:
        _handle_error(e)


@router.delete("/followers/{follower_id}")
async def remove_follower(
    follower_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return await service.remove_follower(
            db,
            current_user_id=current_user.id,
            follower_id=follower_id,
        )
    except Exception as e:
        _handle_error(e)


@router.get("/users/{user_id}/followers")
async def list_followers(
    user_id: int,
    limit: int = Query(30, ge=1, le=50),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        page = await service.list_followers_page(
            db,
            user_id=user_id,
            viewer_id=current_user.id,
            limit=limit,
            offset=offset,
        )

        return {
            "followers": page["items"],
            "items": page["items"],
            "count": page["count"],
            "has_more": page["has_more"],
            "next_offset": page["next_offset"],
            "limit": limit,
            "offset": offset,
        }
    except Exception as e:
        _handle_error(e)


@router.get("/users/{user_id}/following")
async def list_following(
    user_id: int,
    limit: int = Query(30, ge=1, le=50),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        page = await service.list_following_page(
            db,
            user_id=user_id,
            viewer_id=current_user.id,
            limit=limit,
            offset=offset,
        )

        return {
            "following": page["items"],
            "items": page["items"],
            "count": page["count"],
            "has_more": page["has_more"],
            "next_offset": page["next_offset"],
            "limit": limit,
            "offset": offset,
        }
    except Exception as e:
        _handle_error(e)


@router.delete("/users/{target_user_id}/follow-edges")
async def remove_follow_edges_between_users(
    target_user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        return await service.remove_all_follow_edges_between_users(
            db,
            user_a=current_user.id,
            user_b=target_user_id,
        )
    except Exception as e:
        _handle_error(e)