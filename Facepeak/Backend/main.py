# ======================
# DETERMINISTIC SETUP
# ======================
import random
import numpy as np
import torch

SEED = 1337

random.seed(SEED)
np.random.seed(SEED)
torch.manual_seed(SEED)

# ======================
# ENV + EMAIL
# ======================
from dotenv import load_dotenv
import os
import resend

load_dotenv()

RESEND_API_KEY = os.getenv("RESEND_API_KEY")
resend.api_key = RESEND_API_KEY

# ======================
# FASTAPI
# ======================
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# ======================
# DATABASE
# ======================
from Backend.Social_free.login.database import Base, engine

from Backend.Social_free.models.user import User
from Backend.Social_free.models.user_stats import UserStats
from Backend.Social_free.models.user_push_token import UserPushToken

# 🔥 MATCHES
from Backend.Social_free.models.match_table import Match
from Backend.Social_free.models.match_request import MatchRequest

# ======================
# ROUTES
# ======================
from Backend.routes.ai_analysis import router as ai_analysis_router
from Backend.routes.uploads import router as uploads_router
from Backend.Social_free.login.routes.auth_router import router as auth_router

from Backend.Social_free.routes.profile_routes import router as profile_router
from Backend.Social_free.routes.social_activation_routes import router as social_router

from Backend.Social_free.routes.social_search import router as social_users_router

from Backend.Social_free.routes.social_user_profile import (
    router as social_user_profile_router,
)

from Backend.Social_free.routes.push_token_routes import (
    router as push_token_router,
)

# 🔥 SOCIAL MATCHES
from Backend.Social_free.routes.social_match_routes import (
    router as social_match_router,
)

# 🔥 SOCIAL MESSAGES (DM)
from Backend.Social_free.routes.social_message_routes import (
    router as social_message_router,
)

from Backend.Social_free.routes.social_follow_routes import (
    router as social_follow_router,
)

# 🔥 SOCIAL BADGES / STATE
from Backend.Social_free.routes.social_badge_routes import (
    router as social_badge_router,
)

from Backend.Social_free.routes.social_state_routes import (
    router as social_state_router,
)

# 🔥 SOCIAL RESCORE
from Backend.Social_free.routes.social_rescore_limits_routes import (
    router as social_rescore_limit_router,
)

# 🔥 SOCIAL MESSAGES WEBSOCKET
from Backend.Social_free.ws.social_message_ws import (
    router as social_message_ws_router,
)

# 🔥 NEW MESSAGE RATE LIMIT ROUTE
from Backend.Social_free.routes.social_message_routes import (
    router as message_rate_limit_router,
)

# 🔥 ACCOUNT DELETE
from Backend.Social_free.routes.delete_account_routes import (
    router as account_router,
)

# ============================================================
# 🔥 HOME FREE PSL ROUTER
# ============================================================
from Backend.routes.home_free_analysis_router import (
    router as home_free_analysis_router,
)
from Backend.routes.welcome_psl_state_router import router as welcome_psl_state_router




API_V1 = "/api/v1"

app = FastAPI(
    title="FacePeak API",
    description="Educational facial structure analysis backend",
    version="1.0.0",
)

# ======================
# ASYNC DB INIT
# ======================
@app.on_event("startup")
async def on_startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

# ======================
# CORS
# ======================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ======================
# STATIC STORAGE
# ======================
app.mount(
    "/storage",
    StaticFiles(directory="storage"),
    name="storage",
)

# ======================
# ROUTES
# ======================
app.include_router(
    ai_analysis_router,
    prefix=f"{API_V1}/analysis",
    tags=["AI Analysis"],
)

# ============================================================
# 🔥 HOME FREE PSL ROUTE
# ============================================================
app.include_router(
    home_free_analysis_router,
    prefix=f"{API_V1}",
    tags=["Home Free Analysis"],
)

app.include_router(
    uploads_router,
    prefix=f"{API_V1}/uploads",
    tags=["Uploads"],
)

app.include_router(
    auth_router,
    prefix=f"{API_V1}/auth",
    tags=["Auth"],
)

app.include_router(
    social_router,
    prefix=f"{API_V1}",
    tags=["Social"],
)

app.include_router(
    social_users_router,
    prefix=f"{API_V1}",
    tags=["Social Users"],
)

app.include_router(
    social_user_profile_router,
    prefix=f"{API_V1}",
    tags=["Social User Profile"],
)

app.include_router(
    push_token_router,
    prefix=f"{API_V1}",
    tags=["Push Tokens"],
)

# 🔥 SOCIAL MATCHES
app.include_router(
    social_match_router,
    prefix=f"{API_V1}",
    tags=["Social Matches"],
)

# 🔥 SOCIAL MESSAGES (DM HTTP)
app.include_router(
    social_message_router,
    prefix=f"{API_V1}",
    tags=["Social Messages"],
)

# 🔥 NEW MESSAGE RATE LIMIT ROUTE
app.include_router(
    message_rate_limit_router,
    prefix=f"{API_V1}",
    tags=["Message Rate Limit"],
)

# 🔥 SOCIAL MESSAGES (DM WEBSOCKET)
app.include_router(
    social_message_ws_router,
    prefix=f"{API_V1}",
    tags=["Social Messages WebSocket"],
)

app.include_router(
    profile_router,
    prefix=f"{API_V1}/profile",
    tags=["Profile"],
)

# 🔥 SOCIAL FOLLOW
app.include_router(
    social_follow_router,
    tags=["Social Follow"],
)

# 🔥 SOCIAL BADGES
app.include_router(
    social_badge_router,
    prefix=f"{API_V1}",
    tags=["Social Badges"],
)

# 🔥 SOCIAL STATE
app.include_router(
    social_state_router,
    prefix=f"{API_V1}",
    tags=["Social State"],
)
app.include_router(welcome_psl_state_router)

# 🔥 SOCIAL RESCORE LIMIT
app.include_router(
    social_rescore_limit_router,
    prefix=f"{API_V1}",
    tags=["Social Rescore"],
)

# 🔥 ACCOUNT DELETE
app.include_router(
    account_router,
    prefix=f"{API_V1}",
    tags=["Account"],
)

# ======================
# HEALTH
# ======================
@app.get("/")
def root():
    return {
        "status": "ok",
        "app": "FacePeak",
        "version": "v1",
        "message": "Backend is running",
    }


@app.get("/health")
def health():
    return {"status": "ok"}