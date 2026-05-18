from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User
from Backend.Social_free.services.social_state_service import SocialStateService

router = APIRouter(prefix="/social/state", tags=["Social State"])

service = SocialStateService()


@router.get("/badges")
async def get_social_badges(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    badges = await service.get_badges(
        db=db,
        user_id=current_user.id,
    )

    return {
        "status": "success",
        "badges": badges,
    }


@router.get("/user/{target_id}")
async def get_user_action_state(
    target_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    state = await service.get_action_state(
        db=db,
        viewer_id=current_user.id,
        target_id=target_id,
    )

    return {
        "status": "success",
        "user_id": target_id,
        "action_state": state,
    }