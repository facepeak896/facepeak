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
    print("🔥🔥🔥 SOCIAL /go-live HIT")
    print(f"🔥🔥🔥 SOCIAL /go-live current_user.id = {current_user.id}")
    print(f"🔥🔥🔥 SOCIAL /go-live BEFORE current_user.is_live = {getattr(current_user, 'is_live', None)}")

    snapshot = await social_activation_service.activate_live_profile(
        db=db,
        user_id=current_user.id,
    )

    print(f"🔥🔥🔥 SOCIAL /go-live snapshot = {snapshot}")

    result = await db.execute(
        select(User.is_live).where(User.id == current_user.id)
    )
    db_is_live = result.scalar_one_or_none()

    print(f"🔥🔥🔥 SOCIAL /go-live AFTER DB is_live = {db_is_live}")

    if not snapshot:
        print("🔥🔥🔥 SOCIAL /go-live USER_NOT_FOUND")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="USER_NOT_FOUND",
        )

    print("🔥🔥🔥 SOCIAL /go-live SUCCESS")
    return {
        "status": "success",
        "user": snapshot,
    }


@router.post("/social-explainer/seen")
async def mark_social_explainer_seen(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    print("🔥🔥🔥 SOCIAL /social-explainer/seen HIT")
    print(f"🔥🔥🔥 SOCIAL /social-explainer/seen current_user.id = {current_user.id}")

    result = await social_activation_service.mark_social_explainer_seen(
        db=db,
        user_id=current_user.id,
    )

    print(f"🔥🔥🔥 SOCIAL /social-explainer/seen result = {result}")

    if not result:
        print("🔥🔥🔥 SOCIAL /social-explainer/seen USER_NOT_FOUND")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="USER_NOT_FOUND",
        )

    print("🔥🔥🔥 SOCIAL /social-explainer/seen SUCCESS")
    return result


@router.get("/live-status")
async def get_live_status(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    print("🔥🔥🔥 SOCIAL /live-status HIT")
    print(f"🔥🔥🔥 SOCIAL /live-status current_user.id = {current_user.id}")

    result = await db.execute(
        select(User.is_live).where(User.id == current_user.id)
    )
    is_live = result.scalar_one_or_none()

    print(f"🔥🔥🔥 SOCIAL /live-status DB is_live = {is_live}")

    if is_live is None:
        print("🔥🔥🔥 SOCIAL /live-status USER_NOT_FOUND")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="USER_NOT_FOUND",
        )

    print(f"🔥🔥🔥 SOCIAL /live-status SUCCESS returning {bool(is_live)}")
    return {
        "status": "success",
        "is_live": bool(is_live),
    }