from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User
from Backend.Social_free.services.account_deletion_service import (
    AccountDeletionService,
)

router = APIRouter(
    prefix="/account",
    tags=["Account"],
)


@router.delete("/me")
async def delete_my_account(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await AccountDeletionService.permanently_delete_user(
        db=db,
        user_id=current_user.id,
    )

    return {
        "status": "success",
        "message": "ACCOUNT_PERMANENTLY_DELETED",
    }