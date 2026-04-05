from fastapi import APIRouter

router = APIRouter(prefix="/socials", tags=["socials"])


@router.get("/status")
async def socials_status():
    return {
        "status": "disabled",
        "available": False,
        "features": {
            "sharing": False,
            "looksmatch": False,
            "friends": False,
            "chat": False,
        },
        "message": "Social features are coming soon.",
    }