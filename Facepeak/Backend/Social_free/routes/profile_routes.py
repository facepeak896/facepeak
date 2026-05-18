from fastapi import APIRouter, Depends, HTTPException, Request, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from pathlib import Path
from uuid import uuid4
import os

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User
from Backend.Social_free.services.user_service import UserService
from Backend.Social_free.redis import safe_delete
from Backend.Social_free.auth_protection import protect_profile_analysis_save
from Backend.Social_free.services.social_rescore_limit_service import (
    SocialRescoreLimitService,
)

router = APIRouter(tags=["Profile"])

user_service = UserService()

PROFILE_IMAGE_DIR = Path("storage/profile_images")
PROFILE_IMAGE_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_IMAGE_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}


@router.post("/me/save-analysis-profile")
async def save_analysis_profile(
    request: Request,
    image: UploadFile | None = File(default=None),
    weekly_potential_range: str | None = Form(default=None),
    reach_target_percentile: int | None = Form(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    print("❌❌❌ PROFILE SAVE HIT")
    print(f"user_id = {current_user.id}")

    # 🔥 RESCORE COOLDOWN SOURCE OF TRUTH
    SocialRescoreLimitService.enforce(current_user)

    try:
        await protect_profile_analysis_save(request, current_user.id)
    except Exception as e:
        print(f"❌❌❌ PROTECT FAILED = {e}")

    if image is None and weekly_potential_range is None and reach_target_percentile is None:
        raise HTTPException(400, "NOTHING_TO_SAVE")

    cooldown = None

    try:
        if image is not None:
            if image.content_type not in ALLOWED_IMAGE_TYPES:
                raise HTTPException(400, "INVALID_IMAGE_TYPE")

            ext = ALLOWED_IMAGE_TYPES[image.content_type]
            filename = f"user_{current_user.id}_{uuid4().hex}{ext}"

            file_path = PROFILE_IMAGE_DIR / filename
            content = await image.read()

            with open(file_path, "wb") as f:
                f.write(content)

            current_user.profile_image_url = f"/storage/profile_images/{filename}"

            print(f"❌❌❌ saved image = {current_user.profile_image_url}")

        if weekly_potential_range is not None:
            current_user.weekly_potential_range = weekly_potential_range[:50]

        if reach_target_percentile is not None:
            if 1 <= reach_target_percentile <= 100:
                current_user.reach_target_percentile = reach_target_percentile
            else:
                raise HTTPException(422, "INVALID_PERCENTILE")

        await db.commit()
        await db.refresh(current_user)

        print("❌❌❌ DB SAVE SUCCESS")

        # 🔥 START 3-DAY COOLDOWN ONLY AFTER REAL SAVE SUCCESS
        cooldown = await SocialRescoreLimitService.mark_success(
            db=db,
            user=current_user,
        )

        db.add(current_user)
        await db.commit()
        await db.refresh(current_user)

        print(f"❌❌❌ SOCIAL RESCORE COOLDOWN = {cooldown}")

    except HTTPException:
        await db.rollback()
        raise

    except Exception as e:
        await db.rollback()
        print(f"❌❌❌ REAL ERROR = {e}")
        raise HTTPException(500, str(e))

    try:
        await safe_delete(f"user:snapshot:{current_user.id}")
        print("❌❌❌ CACHE CLEARED")
    except Exception as e:
        print(f"❌❌❌ CACHE DELETE FAIL = {e}")

    try:
        snapshot = await user_service.get_full_user_snapshot(db, current_user.id)
        print(f"❌❌❌ SNAPSHOT = {snapshot}")
    except Exception as e:
        print(f"❌❌❌ SNAPSHOT ERROR = {e}")
        raise HTTPException(500, "SNAPSHOT_FAILED")

    return {
        "status": "success",
        "user": snapshot,
        **(cooldown or {}),
    }