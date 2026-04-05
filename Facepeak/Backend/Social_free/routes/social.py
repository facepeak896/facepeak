from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel, constr

from Backend.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User

from Backend.Social_free.services.user_service import UserService
from Backend.Social_free.redis import safe_delete

router = APIRouter(tags=["Profile"])

user_service = UserService()


class UpdateProfileSchema(BaseModel):
    username: constr(min_length=3, max_length=50) | None = None
    bio: constr(max_length=500) | None = None
    profile_image_url: str | None = None
    is_private: bool | None = None


@router.get("/me")
async def get_me(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await user_service.get_full_user_snapshot(db, current_user.id)


@router.patch("/update-profile")
async def update_profile(
    data: UpdateProfileSchema,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    if not any([
        data.username,
        data.bio is not None,
        data.profile_image_url is not None,
        data.is_private is not None
    ]):
        raise HTTPException(400, "NOTHING_TO_UPDATE")

    # =========================
    # USERNAME (FINAL FIX)
    # =========================
    if data.username:
        new_username = data.username.strip().lower()

        if new_username != current_user.username:

            result = await db.execute(
                select(User).where(User.username == new_username)
            )
            existing = result.scalar_one_or_none()

            if existing:
                raise HTTPException(400, "USERNAME_TAKEN")

            current_user.username = new_username

    # =========================
    # BIO
    # =========================
    if data.bio is not None:
        current_user.bio = data.bio

    # =========================
    # IMAGE
    # =========================
    if data.profile_image_url is not None:
        current_user.profile_image_url = data.profile_image_url

    # =========================
    # PRIVACY
    # =========================
    if data.is_private is not None:
        current_user.is_private = data.is_private

    # =========================
    # SAVE
    # =========================
    try:
        await db.commit()
    except IntegrityError:
        raise HTTPException(400, "USERNAME_TAKEN")

    await db.refresh(current_user)

    # 🔥 SAFE CACHE INVALIDATION
    try:
        safe_delete(f"user:snapshot:{current_user.id}")
    except:
        pass

    return await user_service.get_full_user_snapshot(
        db,
        current_user.id
    )