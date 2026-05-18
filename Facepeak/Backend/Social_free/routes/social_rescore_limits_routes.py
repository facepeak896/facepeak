from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user

from Backend.Social_free.models.user import User

from Backend.Social_free.services.social_rescore_limit_service import (
    SocialRescoreLimitService,
)

router = APIRouter(
    prefix="/social/rescore",
    tags=["Social Rescore"],
)


# =========================
# STATUS
# =========================
@router.get("/status")
async def social_rescore_status(
    current_user: User = Depends(get_current_user),
):
    return {
        "status": "success",
        **SocialRescoreLimitService.build_state(current_user),
    }


# =========================
# ENFORCE
# =========================
@router.post("/enforce")
async def enforce_social_rescore(
    current_user: User = Depends(get_current_user),
):
    state = SocialRescoreLimitService.enforce(current_user)

    return {
        "status": "success",
        **state,
    }


# =========================
# MARK SUCCESS
# =========================
@router.post("/mark-success")
async def mark_social_rescore_success(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    cooldown = await SocialRescoreLimitService.mark_success(
        db=db,
        user=current_user,
    )

    db.add(current_user)

    await db.commit()
    await db.refresh(current_user)

    return {
        "status": "success",
        "message": "SOCIAL_RESCORE_SUCCESS_RECORDED",
        **cooldown,
    }