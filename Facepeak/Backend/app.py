# app.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

# ======================
# ROUTES
# ======================
from routes.ai_analysis import router as ai_analysis_router
from routes.uploads import router as uploads_router
from routes.users import router as users_router
from routes.premium import router as premium_router


API_V1 = "/api/v1"
ENV = os.getenv("ENV", "dev")

# ======================
# APP INIT
# ======================
app = FastAPI(
    title="FacePeak API",
    description="Educational facial analysis & visual potential backend",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# ======================
# MIDDLEWARE
# ======================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if ENV == "dev" else [
        "https://app.facepeak.com",
        "https://www.facepeak.com",
    ],
    allow_credentials=False if ENV == "dev" else True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ======================
# ROUTER REGISTRATION
# ======================
app.include_router(
    ai_analysis_router,
    prefix=f"{API_V1}/analysis",
)

app.include_router(
    uploads_router,
    prefix=f"{API_V1}/uploads",
)

app.include_router(
    users_router,
    prefix=f"{API_V1}/users",
)

app.include_router(
    premium_router,
    prefix=f"{API_V1}/premium",
)



# ======================
# HEALTH CHECK
# ======================
@app.get("/", tags=["Health"])
def root():
    return {
        "status": "ok",
        "app": "FacePeak",
        "version": app.version,
        "environment": ENV,
    }