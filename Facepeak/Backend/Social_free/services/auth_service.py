from __future__ import annotations

import hashlib
import secrets
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional, Any

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from models.user import User
from models.user_session import UserSession
from models.refresh_token import RefreshToken


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# =====================================================
# EXCEPTIONS
# =====================================================

class AuthError(Exception):
    pass


class InvalidCredentialsError(AuthError):
    pass


class AccountDisabledError(AuthError):
    pass


class AccountBannedError(AuthError):
    pass


class EmailNotVerifiedError(AuthError):
    pass


class TokenExpiredError(AuthError):
    pass


class InvalidTokenError(AuthError):
    pass


class TokenReuseDetectedError(AuthError):
    pass


class SessionRevokedError(AuthError):
    pass


class WeakPasswordError(AuthError):
    pass


class EmailAlreadyUsedError(AuthError):
    pass


class UsernameAlreadyUsedError(AuthError):
    pass


# =====================================================
# AUTH SERVICE
# =====================================================

class AuthService:
    def _init_(
        self,
        secret_key: str,
        algorithm: str = "HS256",
        access_minutes: int = 15,
        refresh_days: int = 30,
    ) -> None:
        self.secret_key = secret_key
        self.algorithm = algorithm
        self.access_minutes = access_minutes
        self.refresh_days = refresh_days

    # -------------------------------------------------
    # TIME / TOKEN / PASSWORD HELPERS
    # -------------------------------------------------

    def _now(self) -> datetime:
        return datetime.now(timezone.utc)

    def _generate_token(self) -> str:
        return secrets.token_urlsafe(64)

    def _hash_token(self, token: str) -> str:
        return hashlib.sha256(token.encode("utf-8")).hexdigest()

    def hash_password(self, password: str) -> str:
        return pwd_context.hash(password)

    def verify_password(self, password: str, password_hash: str) -> bool:
        return pwd_context.verify(password, password_hash)

    def _validate_password_strength(self, password: str) -> None:
        if len(password) < 8:
            raise WeakPasswordError("Password must have at least 8 characters.")
        if password.isdigit():
            raise WeakPasswordError("Password cannot be only numbers.")
        if password.isalpha():
            raise WeakPasswordError("Password must include letters and numbers.")

    # -------------------------------------------------
    # JWT
    # -------------------------------------------------

    def _create_access_token(self, user: User, session_id: str) -> str:
        now = self._now()

        payload = {
            "sub": str(user.id),
            "session_id": session_id,
            "token_version": getattr(user, "token_version", 0),
            "iat": int(now.timestamp()),
            "exp": int((now + timedelta(minutes=self.access_minutes)).timestamp()),
        }

        return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)

    def decode_access_token(self, access_token: str) -> dict[str, Any]:
        try:
            payload = jwt.decode(
                access_token,
                self.secret_key,
                algorithms=[self.algorithm],
            )
            return payload
        except JWTError as exc:
            raise InvalidTokenError("Invalid access token.") from exc

    # -------------------------------------------------
    # LOOKUPS / STATE VALIDATION
    # -------------------------------------------------

    def _get_user_by_email(self, db: Session, email: str) -> Optional[User]:
        stmt = select(User).where(User.email == email.lower())
        return db.execute(stmt).scalar_one_or_none()

    def _get_user_by_username(self, db: Session, username: str) -> Optional[User]:
        stmt = select(User).where(User.username == username.lower())
        return db.execute(stmt).scalar_one_or_none()

    def _assert_user_can_login(self, user: Optional[User]) -> None:
        if not user:
            raise InvalidCredentialsError("Invalid credentials.")

        if not user.is_active:
            raise AccountDisabledError("Account disabled.")

        if user.is_banned:
            raise AccountBannedError("Account banned.")

    def _get_active_session(self, db: Session, session_id: str) -> Optional[UserSession]:
        stmt = select(UserSession).where(UserSession.session_id == session_id)
        return db.execute(stmt).scalar_one_or_none()

    # -------------------------------------------------
    # DTO
    # -------------------------------------------------

    def _serialize_user(self, user: User) -> dict[str, Any]:
        return {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "profile_image_url": user.profile_image_url,
            "bio": user.bio,
            "is_active": user.is_active,
            "is_banned": user.is_banned,
            "is_email_verified": getattr(user, "is_email_verified", False),
            "created_at": user.created_at.isoformat() if user.created_at else None,
        }

    # -------------------------------------------------
    # REGISTER
    # -------------------------------------------------

    def register_user(
        self,
        db: Session,
        username: str,
        email: str,
        password: str,
    ) -> dict[str, Any]:
        username = username.strip().lower()
        email = email.strip().lower()

        self._validate_password_strength(password)

        if self._get_user_by_email(db, email):
            raise EmailAlreadyUsedError("Email already used.")

        if self._get_user_by_username(db, username):
            raise UsernameAlreadyUsedError("Username already used.")

        user = User(
            username=username,
            email=email,
            password_hash=self.hash_password(password),
            token_version=0,
            is_active=True,
            is_email_verified=False,
            is_banned=False,
            last_active_at=self._now(),
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        return {
            "message": "registered",
            "user": self._serialize_user(user),
        }

    # -------------------------------------------------
    # LOGIN
    # -------------------------------------------------

    def login(
        self,
        db: Session,
        email: str,
        password: str,
        device_name: Optional[str],
        device_type: Optional[str],
        ip_address: Optional[str],
        user_agent: Optional[str],
    ) -> dict[str, Any]:
        user = self._get_user_by_email(db, email.strip().lower())
        self._assert_user_can_login(user)

        if not user.password_hash:
            raise InvalidCredentialsError("This account has no password login.")

        if not self.verify_password(password, user.password_hash):
            raise InvalidCredentialsError("Invalid credentials.")

        if not getattr(user, "is_email_verified", False):
            raise EmailNotVerifiedError("Email not verified.")

        now = self._now()
        session_uuid = str(uuid.uuid4())

        session = UserSession(
            user_id=user.id,
            session_id=session_uuid,
            device_name=device_name,
            device_type=device_type,
            ip_address=ip_address,
            user_agent=user_agent,
            is_active=True,
            last_seen_at=now,
            last_refresh_at=now,
        )
        db.add(session)
        db.flush()

        raw_refresh = self._generate_token()

        refresh_token = RefreshToken(
            user_id=user.id,
            session_id=session_uuid,
            token_hash=self._hash_token(raw_refresh),
            token_family=str(uuid.uuid4()),
            invalidated_by_user_version=getattr(user, "token_version", 0),
            expires_at=now + timedelta(days=self.refresh_days),
            device_name=device_name,
            device_type=device_type,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        db.add(refresh_token)

        user.last_active_at = now

        db.commit()

        access_token = self._create_access_token(user, session_uuid)

        return {
            "message": "login_success",
            "user": self._serialize_user(user),
            "access_token": access_token,
            "refresh_token": raw_refresh,
            "session_id": session_uuid,
        }

    # -------------------------------------------------
    # REFRESH
    # -------------------------------------------------

    def refresh_token(
        self,
        db: Session,
        refresh_token_raw: str,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> dict[str, Any]:
        now = self._now()
        token_hash = self._hash_token(refresh_token_raw)

        stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        token = db.execute(stmt).scalar_one_or_none()

        if not token:
            raise InvalidTokenError("Invalid refresh token.")

        # 1) revoked = mogući reuse attack
        if token.is_revoked:
            self._revoke_family_no_commit(
                db,
                token_family=token.token_family,
                reason="reuse_attack",
                now=now,
                mark_reuse=True,
                reused_token_hash=token_hash,
            )
            db.commit()
            raise TokenReuseDetectedError("Refresh token reuse detected.")

        # 2) expiry
        if token.expires_at < now:
            raise TokenExpiredError("Refresh token expired.")

        # 3) session mora postojati i biti aktivna
        session = self._get_active_session(db, token.session_id)
        if not session or not session.is_active:
            raise SessionRevokedError("Session revoked or inactive.")

        # 4) user mora biti validan
        user = db.get(User, token.user_id)
        self._assert_user_can_login(user)

        if not getattr(user, "is_email_verified", False):
            raise EmailNotVerifiedError("Email not verified.")

        # 5) token_version global invalidation
        if getattr(user, "token_version", 0) != token.invalidated_by_user_version:
            raise SessionRevokedError("Session invalidated by token version.")

        # 6) edge case: već zamijenjen token ne smije se refreshati opet
        if token.replaced_by_token_id is not None:
            self._revoke_family_no_commit(
                db,
                token_family=token.token_family,
                reason="replayed_rotated_token",
                now=now,
                mark_reuse=True,
                reused_token_hash=token_hash,
            )
            db.commit()
            raise TokenReuseDetectedError("Rotated token replay detected.")

        # rotacija
        new_raw = self._generate_token()
        new_token = RefreshToken(
            user_id=user.id,
            session_id=token.session_id,
            token_hash=self._hash_token(new_raw),
            token_family=token.token_family,
            parent_token_id=token.id,
            invalidated_by_user_version=token.invalidated_by_user_version,
            expires_at=now + timedelta(days=self.refresh_days),
            device_name=token.device_name,
            device_type=token.device_type,
            ip_address=ip_address or token.ip_address,
            user_agent=user_agent or token.user_agent,
        )

        db.add(new_token)
        db.flush()

        token.is_revoked = True
        token.replaced_by_token_id = new_token.id
        token.revoked_reason = "rotated"
        token.revoked_at = now
        token.used_at = now

        session.last_seen_at = now
        session.last_refresh_at = now
        if ip_address:
            session.ip_address = ip_address
        if user_agent:
            session.user_agent = user_agent

        user.last_active_at = now

        db.commit()

        access_token = self._create_access_token(user, token.session_id)

        return {
            "message": "token_refreshed",
            "user": self._serialize_user(user),
            "access_token": access_token,
            "refresh_token": new_raw,
            "session_id": token.session_id,
        }

    # -------------------------------------------------
    # LOGOUT
    # -------------------------------------------------

    def logout(self, db: Session, refresh_token_raw: str) -> dict[str, Any]:
        now = self._now()
        token_hash = self._hash_token(refresh_token_raw)

        stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        token = db.execute(stmt).scalar_one_or_none()

        if not token:
            return {"message": "already_logged_out"}

        token.is_revoked = True
        token.revoked_reason = "logout"
        token.revoked_at = now

        session = self._get_active_session(db, token.session_id)
        if session:
            session.is_active = False
            session.revoked_reason = "logout"
            session.revoked_at = now

        db.commit()
        return {"message": "logged_out"}

    # -------------------------------------------------
    # LOGOUT ALL DEVICES
    # -------------------------------------------------

    def logout_all_devices(self, db: Session, user_id: int) -> dict[str, Any]:
        now = self._now()
        user = db.get(User, user_id)

        if not user:
            raise InvalidCredentialsError("User not found.")

        user.token_version = getattr(user, "token_version", 0) + 1

        db.execute(
            update(RefreshToken)
            .where(
                RefreshToken.user_id == user_id,
                RefreshToken.is_revoked == False,
            )
            .values(
                is_revoked=True,
                revoked_reason="logout_all",
                revoked_at=now,
            )
        )

        db.execute(
            update(UserSession)
            .where(
                UserSession.user_id == user_id,
                UserSession.is_active == True,
            )
            .values(
                is_active=False,
                revoked_reason="logout_all",
                revoked_at=now,
            )
        )

        db.commit()
        return {"message": "all_sessions_revoked"}

    # -------------------------------------------------
    # CHANGE PASSWORD
    # -------------------------------------------------

    def change_password(
        self,
        db: Session,
        user_id: int,
        old_password: str,
        new_password: str,
    ) -> dict[str, Any]:
        self._validate_password_strength(new_password)

        user = db.get(User, user_id)
        self._assert_user_can_login(user)

        if not user.password_hash:
            raise InvalidCredentialsError("Account has no password login.")

        if not self.verify_password(old_password, user.password_hash):
            raise InvalidCredentialsError("Invalid current password.")

        user.password_hash = self.hash_password(new_password)
        user.token_version = getattr(user, "token_version", 0) + 1
        user.last_active_at = self._now()

        now = self._now()

        db.execute(
            update(RefreshToken)
            .where(
                RefreshToken.user_id == user_id,
                RefreshToken.is_revoked == False,
            )
            .values(
                is_revoked=True,
                revoked_reason="password_changed",
                revoked_at=now,
            )
        )

        db.execute(
            update(UserSession)
            .where(
                UserSession.user_id == user_id,
                UserSession.is_active == True,
            )
            .values(
                is_active=False,
                revoked_reason="password_changed",
                revoked_at=now,
            )
        )

        db.commit()
        return {"message": "password_changed"}

    # -------------------------------------------------
    # HELPERS (NO COMMIT)
    # -------------------------------------------------

    def _revoke_family_no_commit(
        self,
        db: Session,
        token_family: str,
        reason: str,
        now: Optional[datetime] = None,
        mark_reuse: bool = False,
        reused_token_hash: Optional[str] = None,
    ) -> None:
        now = now or self._now()

        values = {
            "is_revoked": True,
            "revoked_reason": reason,
            "revoked_at": now,
        }

        if mark_reuse:
            values["reuse_detected"] = True
            values["compromised_at"] = now
            if reused_token_hash:
                values["reused_token_hash"] = reused_token_hash

        db.execute(
            update(RefreshToken)
            .where(RefreshToken.token_family == token_family)
            .values(**values)
        )