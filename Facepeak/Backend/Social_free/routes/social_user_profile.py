from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user

from Backend.Social_free.models.user import User

from Backend.Social_free.services.social_search_profile import (
    SocialUserProfileService,
)

from Backend.Social_free.services.social_state_service import (
    SocialStateService,
)

router = APIRouter(prefix="/social", tags=["Social User Profile"])

profile_service = SocialUserProfileService()
state_service = SocialStateService()


@router.get("/user/{user_id}")
async def get_social_user_profile(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    profile = await profile_service.get_public_profile(
        db=db,
        user_id=user_id,
    )

    if not profile:
        raise HTTPException(
            status_code=404,
            detail="USER_NOT_FOUND",
        )

    is_me = int(profile["id"]) == int(current_user.id)

    profile["is_me"] = is_me
    profile["viewer_user_id"] = current_user.id

    # =========================================
    # 🔒 MATCHES LOCK
    # =========================================

    if not is_me:
        profile["matches"] = None
        profile["matches_locked"] = True
    else:
        profile["matches_locked"] = False

    # =========================================
    # 🔥 ENTERPRISE SOCIAL ACTION STATE
    # =========================================

    action_state = await state_service.get_action_state(
        db=db,
        viewer_id=current_user.id,
        target_id=user_id,
    )

    profile.update(action_state)

    return {
        "status": "success",
        "user": profile,
    }