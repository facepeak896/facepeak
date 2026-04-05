"""
Schemas package

This package contains API-facing data schemas used for request and response
validation across the application.

Purpose:
- Define stable, explicit data contracts between backend and frontend.
- Improve readability, maintainability, and API documentation (OpenAPI).
- Serve as a single source of truth for response shapes.

Design principles:
- Schemas describe what is returned, not how data is produced.
- No business logic, database logic, or service logic lives here.
- Schemas may be partially adopted during early development stages.

Usage notes:
- In V1, schemas can be optional to allow rapid iteration.
- In V2+, schemas should be enforced via FastAPI response_model.
- Schemas are versioned implicitly by API versioning (/api/v1, /api/v2).

Security & compliance:
- No raw images, landmarks, or biometric data.
- No authentication or premium logic.
- Safe for App Store / Google Play review requirements.

This file intentionally contains no imports to avoid circular dependencies
and to keep schema modules decoupled.
"""