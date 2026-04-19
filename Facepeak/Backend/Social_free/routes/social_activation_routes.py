from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from Backend.Social_free.login.database import get_db
from Backend.Social_free.models.user import User
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.services.social_activation_service import SocialActivationService

router = APIRouter(prefix="/social", tags=["social"])

social_activation_service = SocialActivationService()


@router.post("/go-live")
async def go_live(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    snapshot = await social_activation_service.activate_live_profile(
        db=db,
        user_id=current_user.id,
    )

    if not snapshot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="USER_NOT_FOUND",
        )

    return {
        "status": "success",
        "user": snapshot,
    }


@router.post("/social-explainer/seen")
async def mark_social_explainer_seen(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await social_activation_service.mark_social_explainer_seen(
        db=db,
        user_id=current_user.id,
    )

    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="USER_NOT_FOUND",
        )

    return result


@router.get("/live-status")
async def get_live_status(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(User.is_live).where(User.id == current_user.id)
    )
    is_live = result.scalar_one_or_none()

    if is_live is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="USER_NOT_FOUND",
        )

    return {
        "status": "success",
        "is_live": bool(is_live),
    }