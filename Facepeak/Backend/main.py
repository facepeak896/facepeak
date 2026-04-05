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

# ======================
# DATABASE (ASYNC FIX 🔥)
# ======================
from Backend.Social_free.login.database import Base, engine

# 🔥 IMPORT MODELA (OBAVEZNO)
from Backend.Social_free.models.user import User

# ======================
# ROUTES
# ======================
from Backend.routes.ai_analysis import router as ai_analysis_router
from Backend.routes.uploads import router as uploads_router
from Backend.Social_free.login.routes.auth_router import router as auth_router

API_V1 = "/api/v1"

app = FastAPI(
    title="FacePeak API",
    description="Educational facial structure analysis backend",
    version="1.0.0",
)

# ======================
# 🔥 ASYNC DB INIT (FIX)
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
# ROUTES
# ======================
app.include_router(
    ai_analysis_router,
    prefix=f"{API_V1}/analysis",
    tags=["AI Analysis"],
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