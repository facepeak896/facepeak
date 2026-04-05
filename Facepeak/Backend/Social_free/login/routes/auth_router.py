from fastapi import APIRouter, Depends, Request, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, EmailStr, constr

from Backend.Social_free.login.database import get_db
from Backend.Social_free.login.security import get_current_user
from Backend.Social_free.models.user import User

from Backend.Social_free.login.auth_service import (
    signup_user,
    login_user,
    refresh_user_token,
    logout_user,
    request_password_reset,
    reset_password,
)

from Backend.Social_free.services.user_service import UserService
from Backend.Social_free.auth_protection import protect_login, protect_signup

router = APIRouter(tags=["Auth"])

user_service = UserService()


# =========================
# RESPONSE MODEL
# =========================

class AuthResponse(BaseModel):
    status: str
    message: str | None = None
    access_token: str | None = None
    refresh_token: str | None = None  # 🔥 FIX
    user_id: int | None = None


# =========================
# INPUT SCHEMAS
# =========================

class SignupSchema(BaseModel):
    email: EmailStr
    username: constr(min_length=3, max_length=50)
    password: constr(min_length=6, max_length=72)


class LoginSchema(BaseModel):
    email: EmailStr
    password: str


class RefreshSchema(BaseModel):
    refresh_token: str


class LogoutSchema(BaseModel):
    refresh_token: str


class ResetRequestSchema(BaseModel):
    email: EmailStr


class ResetConfirmSchema(BaseModel):
    token: str
    new_password: constr(min_length=6, max_length=72)


# =========================
# SIGNUP
# =========================

@router.post("/signup", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def signup(data: SignupSchema, request: Request, db: AsyncSession = Depends(get_db)):

    protect_signup(request, data.email)

    try:
        return await signup_user(
            email=data.email,
            username=data.username,
            password=data.password,
            db=db,
        )
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(400, "SIGNUP_FAILED")


# =========================
# LOGIN
# =========================

@router.post("/login", response_model=AuthResponse)
async def login(data: LoginSchema, request: Request, db: AsyncSession = Depends(get_db)):

    protect_login(request, data.email)

    try:
        return await login_user(
            email=data.email,
            password=data.password,
            db=db,
        )
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(400, "LOGIN_FAILED")


# =========================
# REFRESH
# =========================

@router.post("/refresh", response_model=AuthResponse)
async def refresh(data: RefreshSchema):

    try:
        return await refresh_user_token(data.refresh_token)
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(401, "REFRESH_FAILED")


# =========================
# LOGOUT
# =========================

@router.post("/logout", response_model=AuthResponse)
async def logout(data: LogoutSchema):

    try:
        return await logout_user(data.refresh_token)
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(400, "LOGOUT_FAILED")


# =========================
# REQUEST RESET
# =========================

@router.post("/forgot-password", response_model=AuthResponse)
async def forgot_password(data: ResetRequestSchema, db: AsyncSession = Depends(get_db)):
    return await request_password_reset(data.email, db)


# =========================
# RESET PASSWORD
# =========================

@router.post("/reset-password", response_model=AuthResponse)
async def reset_password_route(data: ResetConfirmSchema, db: AsyncSession = Depends(get_db)):
    return await reset_password(
        token=data.token,
        new_password=data.new_password,
        db=db,
    )


# =========================
# GET CURRENT USER (FIXED)
# =========================

@router.get("/me")
async def get_me(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    if not current_user:
        raise HTTPException(401, "UNAUTHORIZED")

    return await user_service.get_full_user_snapshot(
        db,
        current_user.id
    )