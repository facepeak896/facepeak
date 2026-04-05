"""
Validation helpers (placeholder)

This module is reserved for pure data validation functions.

Design rules:
- No FastAPI / HTTPException
- No database access
- No cache access
- No business logic
- Raise ValueError / TypeError only

Purpose:
- Validate raw input data
- Validate payload structure
- Validate numeric ranges
- Validate lists / dict shapes

Examples of future validators:
- validate_image_bytes(image_bytes)
- validate_score_range(score, min=0, max=10)
- validate_analysis_payload(payload)
- validate_uuid(value)
- validate_non_empty_string(value)

What must NOT go here:
- Authentication checks
- Premium checks
- Ownership checks
- Rate limiting
- Feature gating

Mapping rule:
validators.py → raises ValueError
routes/services → map to HTTP errors

This file is intentionally minimal for now.
"""