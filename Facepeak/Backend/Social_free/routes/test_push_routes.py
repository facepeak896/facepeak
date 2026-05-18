# Backend/Social_free/routes/test_push_routes.py

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db

from Backend.Social_free.services.test_push_service import (
    TestPushService,
)

router = APIRouter(
    prefix="/test-push",
    tags=["Test Push"],
)


@router.post("/run")
async def run_test_push(
    db: AsyncSession = Depends(get_db),
):
    return await TestPushService.run(db=db)