from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.services.welcome_psl_state_service import WelcomePslStateService


router = APIRouter(
    prefix="/welcome-psl",
    tags=["welcome-psl"],
)


class SaveWelcomePslRequest(BaseModel):
    psl_result: dict


class AccessChoiceRequest(BaseModel):
    access_tier: str


@router.get("/status")
async def get_welcome_psl_status(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await WelcomePslStateService.get_status(
        db=db,
        user_id=current_user.id,
    )


@router.post("/save-result")
async def save_welcome_psl_result(
    body: SaveWelcomePslRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await WelcomePslStateService.save_psl_result(
        db=db,
        user_id=current_user.id,
        psl_result=body.psl_result,
    )


@router.post("/access-choice")
async def save_access_choice(
    body: AccessChoiceRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    try:
        return await WelcomePslStateService.mark_access_choice(
            db=db,
            user_id=current_user.id,
            access_tier=body.access_tier,
        )
    except ValueError:
        raise HTTPException(
            status_code=422,
            detail="INVALID_ACCESS_TIER",
        )