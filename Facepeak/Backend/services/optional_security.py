# Backend/Social_free/login/optional_security.py

from typing import Optional

from fastapi import Depends
from fastapi.security import (
    HTTPBearer,
    HTTPAuthorizationCredentials,
)
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user

# ✅ IMPORTANT
# auto_error=False prevents automatic 401
security = HTTPBearer(auto_error=False)


async def get_optional_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: AsyncSession = Depends(get_db),
):
    # =========================================================
    # GUEST USER
    # =========================================================
    if credentials is None:
        return None

    # =========================================================
    # LOGGED USER
    # =========================================================
    try:
        return await get_current_user(credentials, db)
    except Exception:
        return None