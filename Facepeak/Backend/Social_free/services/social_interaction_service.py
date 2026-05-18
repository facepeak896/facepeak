# Backend/Social_free/services/social_interaction_service.py

from fastapi import HTTPException


class SocialInteractionService:
    @staticmethod
    def guard_not_self(actor_user_id: int, target_user_id: int):
        if actor_user_id == target_user_id:
            raise HTTPException(
                status_code=400,
                detail="CANNOT_INTERACT_WITH_SELF",
            )