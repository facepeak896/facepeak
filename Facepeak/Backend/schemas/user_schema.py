"""
User schemas (V1 / JWT-ready)

This module defines data shapes related to users that are exposed
through the API layer.

Current scope:
- Lightweight user representation (id, flags, subscription state).
- No sensitive data (passwords, tokens, emails) included.
- Designed to support both guest and authenticated flows.

Why schemas may not be strictly enforced yet:
- Authentication is currently token-based stub (pre-JWT).
- User persistence layer (DB) is not finalized.
- Allows frontend iteration without frequent breaking changes.

Planned evolution:
- V2: strict response_model enforcement on user endpoints.
- V2+: JWT-backed users, database models, role-based access.
- Admin and analytics extensions built on top of this schema.

Rules:
- Schemas must remain API-facing only.
- No business logic or permission checks here.
- Any sensitive user data must never be added to schemas.

This file defines the contract, not the implementation.
"""