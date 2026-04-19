# -- coding: utf-8 --
from __future__ import annotations

import base64
from typing import Optional

from fastapi import APIRouter, UploadFile, File, HTTPException, Header, Depends, Request
from fastapi.concurrency import run_in_threadpool

# ============================================================
# AI modules (ONLY WHAT YOU USE)
# ============================================================
from Backend.ai.psl_adapter import run_psl_adapter
from Backend.ai.appeal_adapter import run_appeal_adapter_insight
from Backend.ai.analysis_adapter import analyze_face

# ============================================================
# SERVICES
# ============================================================
from Backend.services.redis_client import get_redis
from Backend.services.embedding_service import extract_embedding

from Backend.services.analysis_service import (
    create_analysis,
    get_analysis_payload,
    get_analysis_part,
    save_analysis_part,
)

# ============================================================
# ROUTER
# ============================================================
router = APIRouter(
    prefix="/analyze",
    tags=["analysis"],
)

# ============================================================
# CONSTANTS
# ============================================================
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024
ANALYSIS_TTL_SECONDS = 24 * 60 * 60

# ============================================================
# HELPERS
# ============================================================
def _http(code: int, msg: str):
    raise HTTPException(status_code=code, detail=msg)

def _read_upload_guard(file: UploadFile, data: bytes):
    if file.content_type not in ALLOWED_TYPES:
        _http(415, "UNSUPPORTED_TYPE")
    if not data:
        _http(400, "EMPTY_IMAGE")
    if len(data) > MAX_FILE_SIZE:
        _http(413, "IMAGE_TOO_LARGE")


# ============================================================
# START (FIXED)
# ============================================================
@router.post("/start")
async def analyze_start(
    image: UploadFile = File(...),
    x_guest_token: Optional[str] = Header(default=None),
):
    image_bytes = await image.read()
    _read_upload_guard(image, image_bytes)

    analysis_id = create_analysis(
        {
            "user": None,
            "guest_token": x_guest_token,
            # ✅ FIX: base64 instead of raw bytes
            "image_bytes": base64.b64encode(image_bytes).decode(),
            "signals": None,
        },
        ttl_seconds=ANALYSIS_TTL_SECONDS,
    )

    return {
        "status": "success",
        "analysis_id": analysis_id,
    }
# ============================================================
# 🔥 PSL ROUTE
# ============================================================
@router.post("/{analysis_id}/psl")
async def analyze_psl(
    request: Request,
    analysis_id: str,
    x_guest_token: Optional[str] = Header(default=None),
):
    try:
        print("\n🔥 ===== PSL ROUTE HIT =====")
        print("analysis_id:", analysis_id)
        print("guest_token:", x_guest_token)

        payload = get_analysis_payload(analysis_id)
        if not payload:
            raise HTTPException(status_code=404, detail="ANALYSIS_NOT_FOUND")

        stored_token = payload.get("guest_token")
        if stored_token is not None and stored_token != x_guest_token:
            raise HTTPException(status_code=403, detail="INVALID_GUEST_TOKEN")

        image_b64 = payload.get("image_bytes")
        if not image_b64:
            raise HTTPException(status_code=422, detail="MISSING_IMAGE")

        image_bytes = base64.b64decode(image_b64)
        print("📸 Image bytes size:", len(image_bytes))

        try:
            extractor_output = await run_in_threadpool(
                extract_embedding,
                image_bytes
            )
        except Exception as e:
            print("❌ EMBEDDING ERROR:", e)
            raise HTTPException(status_code=500, detail="EMBEDDING_ERROR")

        if extractor_output is None:
            print("❌ NO FACE DETECTED")
            raise HTTPException(status_code=422, detail="NO_FACE_DETECTED")

        print("✅ Embedding extracted")

        previous_score = payload.get("previous_psl_score")
        if previous_score is not None:
            extractor_output["previous_score"] = previous_score
            print("📊 Previous score:", previous_score)

        try:
            result = await run_in_threadpool(
                run_psl_adapter,
                extractor_output
            )
        except Exception as e:
            print("❌ PSL ENGINE CRASH:", e)
            raise HTTPException(status_code=500, detail="PSL_ENGINE_ERROR")

        print("🧠 Raw PSL result:", result)

        if not isinstance(result, dict):
            raise HTTPException(status_code=500, detail="INVALID_PSL_RESULT")

        if result.get("status") != "success":
            raise HTTPException(
                status_code=422,
                detail=result.get("reason", "PSL_FAILED")
            )

        psl_payload = result.get("psl", {})

        score = psl_payload.get("psl_score")
        tier = psl_payload.get("tier")
        percentile = psl_payload.get("percentile")
        confidence = psl_payload.get("confidence")

        stable_score_float = psl_payload.get("stable_score_float")
        raw_expected = psl_payload.get("raw_expected")
        bonus_applied = psl_payload.get("bonus_applied")

        print("\n🎯 ===== FINAL PSL =====")
        print("Score:", score)
        print("Tier:", tier)
        print("Percentile:", percentile)
        print("Confidence:", confidence)
        print("Stable score float:", stable_score_float)
        print("Raw expected:", raw_expected)
        print("Bonus applied:", bonus_applied)
        print("========================\n")

        if score is not None:
            save_analysis_part(
                analysis_id,
                payload,
                "previous_psl_score",
                score,
            )

        return {
            "status": "success",
            "psl": {
                "psl_score": score,
                "tier": tier,
                "percentile": percentile,
                "confidence": confidence,
                "stable_score_float": stable_score_float,
                "raw_expected": raw_expected,
                "bonus_applied": bonus_applied,
            },
        }

    except Exception as e:
        print("❌ PSL ENDPOINT ERROR:", e)
        raise
# ============================================================
# 🔥 FREE ROUTE
# ============================================================
@router.post("/{analysis_id}/free")
async def analyze_free(
    request: Request,
    analysis_id: str,
    x_guest_token: Optional[str] = Header(default=None),
):
    try:

        payload = get_analysis_payload(analysis_id)
        if not payload:
            raise HTTPException(status_code=404, detail="ANALYSIS_NOT_FOUND")

        stored_token = payload.get("guest_token")
        if stored_token is not None and stored_token != x_guest_token:
            raise HTTPException(status_code=403, detail="INVALID_GUEST_TOKEN")

        # ✅ FIX
        image_b64 = payload.get("image_bytes")
        if not image_b64:
            raise HTTPException(status_code=422, detail="MISSING_IMAGE")

        image_bytes = base64.b64decode(image_b64)

        try:
            extractor_output = await run_in_threadpool(
                extract_embedding,
                image_bytes
            )
        except Exception as e:
            print("EMBEDDING ERROR:", e)
            raise HTTPException(status_code=500, detail="EMBEDDING_ERROR")

        if extractor_output is None:
            raise HTTPException(status_code=422, detail="NO_FACE_DETECTED")

        previous_score = payload.get("previous_psl_score")

        if previous_score is not None:
            extractor_output["previous_score"] = previous_score

        try:
            result = await run_in_threadpool(
                analyze_face,
                extractor_output
            )
        except Exception as e:
            print("FREE ENGINE CRASH:", e)
            raise HTTPException(status_code=500, detail="FREE_ENGINE_ERROR")

        if not isinstance(result, dict):
            raise HTTPException(status_code=500, detail="INVALID_RESULT")

        if result.get("status") != "success":
            raise HTTPException(
                status_code=422,
                detail=result.get("reason", "ANALYSIS_FAILED")
            )

        psl_payload = result.get("psl", {})
        score = psl_payload.get("psl_score")

        if score is not None:
            save_analysis_part(
                analysis_id,
                payload,
                "previous_psl_score",
                score,
            )

        return {
            "status": "success",
            "psl": {
                "psl_score": score,
            },
            "strengths": result.get("strengths", []),
            "limits": result.get("limits", []),
        }

    except Exception as e:
        print("FREE ENDPOINT ERROR:", e)
        raise


# ============================================================
# 🔥 APPEAL ROUTE (UNCHANGED LOGIC + FIX)
# ============================================================
@router.post("/{analysis_id}/appeal")
async def analyze_appeal(
    request: Request,
    analysis_id: str,
    x_guest_token: str | None = Header(default=None),
    redis=Depends(get_redis),
):
    try:

        if not x_guest_token:
            raise HTTPException(status_code=400, detail="GUEST_TOKEN_REQUIRED")

        payload = get_analysis_payload(analysis_id)

        # ✅ FIX
        image_b64 = payload.get("image_bytes")
        if not image_b64:
            raise HTTPException(status_code=400, detail="IMAGE_MISSING")

        image_bytes = base64.b64decode(image_b64)

        subject_id = f"guest:{x_guest_token}"
        used_key = f"appeal:used:{subject_id}"

        print("=== APPEAL ROUTE HIT ===")

        cached = get_analysis_part(analysis_id, "appeal")
        if cached:
            used = int(redis.get(used_key) or 0)

            return {
                "status": "success",
                "appeal": cached,
                "cached": True,
                "used": used,
                "limit": 2,
            }

        res = await run_in_threadpool(
            run_appeal_adapter_insight,
            image_bytes,
        )

        if res.get("status") != "success" or not res.get("appeal"):
            raise HTTPException(status_code=422, detail="APPEAL_FAILED")

        save_analysis_part(
            analysis_id,
            payload,
            "appeal",
            res["appeal"],
        )

        used_before = int(redis.get(used_key) or 0)

        pipe = redis.pipeline()
        used = used_before

        if used < 2:
            pipe.incr(used_key)

            ttl = redis.ttl(used_key)

            if ttl == -1:
                pipe.expire(used_key, 24 * 60 * 60)

            pipe.execute()
            used += 1

        return {
            "status": "success",
            "appeal": res["appeal"],
            "cached": False,
            "used": used,
            "limit": 2,
        }

    except Exception as e:
        print("APPEAL ENDPOINT ERROR:", e)
        raise