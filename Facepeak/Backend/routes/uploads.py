from fastapi import APIRouter, HTTPException

router = APIRouter(prefix="/upload", tags=["upload"])

@router.post("/")
async def upload_image():
    """
    Upload service is disabled in V2.5.

    All image uploads are handled via /analyze/start.
    This endpoint will be enabled in V3 for:
    - image history
    - profiles
    - social features
    """
    raise HTTPException(
        status_code=410,
        detail="Image upload service is disabled in this version."
    )