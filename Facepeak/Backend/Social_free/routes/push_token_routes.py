from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User
from Backend.Social_free.services.push_token_service import PushTokenService


router = APIRouter(prefix="/social", tags=["Push Tokens"])

push_token_service = PushTokenService()


# =========================
# REQUEST MODELS
# =========================

class SavePushTokenRequest(BaseModel):
    fcm_token: str = Field(..., min_length=20, max_length=512)
    platform: str = Field(default="android", max_length=30)
    device_id: str | None = Field(default=None, max_length=255)


class DeletePushTokenRequest(BaseModel):
    fcm_token: str = Field(..., min_length=20, max_length=512)


# =========================
# SAVE TOKEN
# =========================

@router.post("/push-token")
async def save_push_token(
    payload: SavePushTokenRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        result = await push_token_service.save_token(
            db=db,
            user_id=current_user.id,
            fcm_token=payload.fcm_token.strip(),
            platform=payload.platform.strip(),
            device_id=payload.device_id.strip() if payload.device_id else None,
        )

        return {
            "status": "success",
            "token_status": result.get("status"),
            "push_token_id": result.get("id"),
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    except Exception as e:
        raise HTTPException(status_code=500, detail="PUSH_TOKEN_SAVE_FAILED")


# =========================
# DELETE TOKEN
# =========================

@router.delete("/push-token")
async def delete_push_token(
    payload: DeletePushTokenRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        deleted = await push_token_service.deactivate_token(
            db=db,
            fcm_token=payload.fcm_token.strip(),
        )

        return {
            "status": "success",
            "deleted": deleted,
        }

    except Exception:
        raise HTTPException(status_code=500, detail="PUSH_TOKEN_DELETE_FAILED")