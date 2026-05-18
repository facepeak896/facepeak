from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User
from Backend.Social_free.services.social_badge_service import SocialBadgeService

router = APIRouter(prefix="/social", tags=["Social Badges"])

badge_service = SocialBadgeService()


@router.get("/badges")
async def get_social_badges(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    badges = await badge_service.get_badges(
        db=db,
        user_id=current_user.id,
    )

    return {
        "status": "success",
        "badges": badges,
    }


# ✅ NEW
@router.post("/badges/follow/seen")
async def mark_follow_badges_seen(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await badge_service.mark_follow_seen(
        db=db,
        user_id=current_user.id,
    )

    return {
        "status": "success",
    }