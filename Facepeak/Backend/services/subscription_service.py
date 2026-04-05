# -- coding: utf-8 --
from __future__ import annotations

"""
Subscription Service (V2 Stub)

This module defines the FINAL subscription API surface.
Business logic is intentionally simplified for early-stage usage.

IMPORTANT:
- Routes and other services MUST depend on this file.
- When real billing is introduced (Apple / Google / Stripe),
  ONLY the internals of this file should change.
- No route refactors. No service contract changes.
"""

from typing import Dict, Any


# ============================================================
# CORE HELPERS
# ============================================================

def is_premium(user: Dict[str, Any] | None) -> bool:
    """
    Returns True if the user has premium access.
    Guest users are always non-premium.
    """
    if not user:
        return False
    return bool(user.get("is_premium", False))


def require_premium(user: Dict[str, Any] | None) -> None:
    """
    Business-level guard.
    Raises PermissionError if user is not premium.
    HTTP mapping is handled at route / service layer.
    """
    if not is_premium(user):
        raise PermissionError("PREMIUM_REQUIRED")


# ============================================================
# FEATURE GATING
# ============================================================

def has_feature(user: Dict[str, Any] | None, feature: str) -> bool:
    """
    Feature-level access check.

    Future-ready:
    - subscriptions tiers
    - feature flags
    - A/B testing
    """
    if not is_premium(user):
        return False

    # V2: premium unlocks all features
    return True


def require_feature(user: Dict[str, Any] | None, feature: str) -> None:
    """
    Enforces access to a specific premium feature.
    """
    if not has_feature(user, feature):
        raise PermissionError("FEATURE_LOCKED")


# ============================================================
# FUTURE BILLING STUBS
# ============================================================

def sync_subscription_from_receipt(receipt_data: str) -> None:
    """
    Stub for future receipt validation.

    V3+:
    - Apple App Store receipt validation
    - Google Play purchase tokens
    - Stripe webhooks
    """
    raise NotImplementedError("Billing not implemented yet")


# ------------------------------------------------------------
# NOTE:
# This module is intentionally implemented as a stub.
# It defines the final subscription API surface without
# binding to any billing provider (Apple / Stripe / Google).
#
# When real purchases are introduced, only the internal
# logic of these functions should change — NOT the callers.
#
# This guarantees:
# - No route refactors
# - No service contract changes
# - Safe App Store / Play Store compliance
#
# V1–V2: stub logic
# V3+: real receipt validation & persistence
# ------------------------------------------------------------