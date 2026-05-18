from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User
from Backend.Social_free.services.social_search_service import SocialSearchService
from Backend.Social_free.services.user_service import UserService

router = APIRouter(prefix="/social", tags=["Social Users"])

social_search_service = SocialSearchService()
user_service = UserService()


@router.get("/users")
async def get_social_users(
    limit: int = Query(30, ge=1, le=50),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    page = await social_search_service.list_live_users_page(
    db=db,
    limit=limit,
    offset=offset,
)

    return {
    "status": "success",
    "limit": limit,
    "offset": offset,
    "count": page["count"],
    "has_more": page["has_more"],
    "next_offset": page["next_offset"],
    "users": page["items"],
}


@router.get("/users/{user_id}")
async def get_social_user_profile(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    snapshot = await user_service.get_full_user_snapshot(db, user_id)

    if not snapshot:
        raise HTTPException(status_code=404, detail="USER_NOT_FOUND")

    return {
        "status": "success",
        "user": snapshot,
    }