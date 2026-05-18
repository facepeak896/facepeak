# Backend/Social_free/analysis/home_free_analysis_router.py

from __future__ import annotations

import base64

from fastapi import (
    APIRouter,
    HTTPException,
    Request,
    Depends,
)

from fastapi.concurrency import run_in_threadpool

# ============================================================
# AI
# ============================================================
from Backend.ai.psl_adapter import run_psl_adapter

# ============================================================
# SERVICES
# ============================================================
from Backend.services.embedding_service import extract_embedding

from Backend.services.analysis_service import (
    get_analysis_payload,
    save_analysis_part,
)

from Backend.services.free_psl_cooldown_service import (
    FreePslCooldownService,
)

# ============================================================
# REQUIRED AUTH
# ============================================================
from Backend.Social_free.login.security import (
    get_current_user,
)

# ============================================================
# ROUTER
# ============================================================
router = APIRouter(
    prefix="/home-free/analyze",
    tags=["home-free-analysis"],
)


# ============================================================
# HOME FREE PSL
# ============================================================
@router.post("/{analysis_id}/psl")
async def home_free_psl(
    request: Request,
    analysis_id: str,

    # 🔒 REQUIRED AUTH
    current_user=Depends(get_current_user),
):
    try:
        print("")
        print("🔥 HOME FREE PSL REQUEST")
        print("🔥 current_user =", current_user)
        print("")

        # ====================================================
        # USER KEY
        # ====================================================
        user_key = FreePslCooldownService.build_user_key(
            user=current_user,
        )

        # ====================================================
        # RATE LIMIT
        # ====================================================
        limited = await FreePslCooldownService.check_or_rate_limit(
            user_key=user_key,
            request=request,
        )

        if limited:
            print("🔒 RATE LIMITED")
            return limited

        # ====================================================
        # ANALYSIS PAYLOAD
        # ====================================================
        payload = get_analysis_payload(analysis_id)

        if not payload:
            raise HTTPException(
                status_code=404,
                detail="ANALYSIS_NOT_FOUND",
            )

        # ====================================================
        # IMAGE
        # ====================================================
        image_b64 = payload.get("image_bytes")

        if not image_b64:
            raise HTTPException(
                status_code=422,
                detail="MISSING_IMAGE",
            )

        image_bytes = base64.b64decode(image_b64)

        # ====================================================
        # EMBEDDING
        # ====================================================
        try:
            extractor_output = await run_in_threadpool(
                extract_embedding,
                image_bytes,
            )

        except Exception as e:
            print("❌ EMBEDDING ERROR:", e)

            raise HTTPException(
                status_code=500,
                detail="EMBEDDING_ERROR",
            )

        if extractor_output is None:
            raise HTTPException(
                status_code=422,
                detail="NO_FACE_DETECTED",
            )

        # ====================================================
        # PREVIOUS SCORE
        # ====================================================
        previous_score = payload.get("previous_psl_score")

        if previous_score is not None:
            extractor_output["previous_score"] = previous_score

        # ====================================================
        # PSL ENGINE
        # ====================================================
        try:
            result = await run_in_threadpool(
                run_psl_adapter,
                extractor_output,
            )

        except Exception as e:
            print("❌ PSL ENGINE ERROR:", e)

            raise HTTPException(
                status_code=500,
                detail="PSL_ENGINE_ERROR",
            )

        # ====================================================
        # VALIDATION
        # ====================================================
        if not isinstance(result, dict):
            raise HTTPException(
                status_code=500,
                detail="INVALID_PSL_RESULT",
            )

        if result.get("status") != "success":
            raise HTTPException(
                status_code=422,
                detail=result.get("reason", "PSL_FAILED"),
            )

        # ====================================================
        # PSL PAYLOAD
        # ====================================================
        psl_payload = result.get("psl", {})

        score = psl_payload.get("psl_score")

        # ====================================================
        # SAVE SCORE
        # ====================================================
        if score is not None:
            save_analysis_part(
                analysis_id,
                payload,
                "previous_psl_score",
                score,
            )

        # ====================================================
        # LOCK AFTER SUCCESS
        # ====================================================
        lock_data = await FreePslCooldownService.lock_after_success(
            user_key=user_key,
        )

        print("✅ HOME FREE PSL SUCCESS")
        print("✅ lock_data =", lock_data)
        print("")

        # ====================================================
        # RESPONSE
        # ====================================================
        return {
            "status": "success",
            "psl": {
                "psl_score": score,
                "tier": psl_payload.get("tier"),
                "percentile": psl_payload.get("percentile"),
                "confidence": psl_payload.get("confidence"),
                "stable_score_float": psl_payload.get("stable_score_float"),
                "raw_expected": psl_payload.get("raw_expected"),
                "bonus_applied": psl_payload.get("bonus_applied"),
            },
            "strengths": result.get("strengths", []),
            "limits": result.get("limits", []),
            **lock_data,
        }

    except HTTPException:
        raise

    except Exception as e:
        print("❌ HOME FREE PSL ERROR:", e)

        raise HTTPException(
            status_code=500,
            detail="HOME_FREE_PSL_FAILED",
        )