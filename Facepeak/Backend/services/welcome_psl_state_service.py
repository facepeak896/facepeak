from __future__ import annotations

from typing import Any, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from Backend.Social_free.models.user_welcome_psl import UserWelcomePSL


class WelcomePslStateService:
    @staticmethod
    async def get_or_create(
        db: AsyncSession,
        user_id: int,
    ) -> UserWelcomePSL:
        result = await db.execute(
            select(UserWelcomePSL).where(
                UserWelcomePSL.user_id == user_id,
            )
        )

        state = result.scalar_one_or_none()

        if state:
            return state

        state = UserWelcomePSL(
            user_id=user_id,
            welcome_loading_done=False,
            welcome_access_chosen=False,
            access_tier=None,
            psl_result=None,
        )

        db.add(state)
        await db.commit()
        await db.refresh(state)

        return state

    @staticmethod
    def serialize(state: UserWelcomePSL) -> dict[str, Any]:
        if state.welcome_access_chosen:
            next_screen = "home"
        elif state.welcome_loading_done:
            next_screen = "access_choice"
        else:
            next_screen = "landing"

        return {
            "status": "success",
            "next_screen": next_screen,
            "welcome_loading_done": state.welcome_loading_done,
            "welcome_access_chosen": state.welcome_access_chosen,
            "access_tier": state.access_tier,
            "psl_result": state.psl_result,
        }

    @staticmethod
    async def get_status(
        db: AsyncSession,
        user_id: int,
    ) -> dict[str, Any]:
        state = await WelcomePslStateService.get_or_create(
            db=db,
            user_id=user_id,
        )

        return WelcomePslStateService.serialize(state)

    @staticmethod
    async def save_psl_result(
        db: AsyncSession,
        user_id: int,
        psl_result: dict[str, Any],
    ) -> dict[str, Any]:
        state = await WelcomePslStateService.get_or_create(
            db=db,
            user_id=user_id,
        )

        state.welcome_loading_done = True
        state.psl_result = psl_result

        db.add(state)
        await db.commit()
        await db.refresh(state)

        return WelcomePslStateService.serialize(state)

    @staticmethod
    async def mark_access_choice(
        db: AsyncSession,
        user_id: int,
        access_tier: str,
    ) -> dict[str, Any]:
        if access_tier not in {"free", "premium"}:
            raise ValueError("INVALID_ACCESS_TIER")

        state = await WelcomePslStateService.get_or_create(
            db=db,
            user_id=user_id,
        )

        state.welcome_access_chosen = True
        state.access_tier = access_tier

        db.add(state)
        await db.commit()
        await db.refresh(state)

        return WelcomePslStateService.serialize(state)