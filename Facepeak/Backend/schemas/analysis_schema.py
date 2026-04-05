"""
Analysis schemas (V1 / Store-safe)

This module defines API-facing schemas for analysis-related responses.

Purpose:
- Describe the shape of analysis data returned to clients.
- Act as a stable contract between backend and frontend.
- Keep API responses predictable, documented, and testable.

Design principles:
- Schemas represent OUTPUT ONLY (responses), not internal state.
- No image bytes, landmarks, or raw biometric data included.
- Only aggregated, explainable analysis results are exposed.

Why schemas may be partially used (or optional) in V1:
- Analysis payloads are modular and feature-gated (premium / free).
- Frontend iterates rapidly during early product stages.
- Avoids excessive refactors before DB + JWT stabilization.

Security & compliance:
- No personal identifiers beyond analysis_id.
- No face geometry, embeddings, or identity inference.
- Fully compliant with App Store / Google Play AI policies.

Planned evolution:
- V2: enforce response_model on all analysis endpoints.
- V2+: versioned schemas per feature (psl, appeal, potential, etc.).
- V3: database-backed analysis history with strict typing.

Rules:
- Schemas must never include raw inputs (image bytes, landmarks).
- No business logic or premium checks here.
- Changes to schemas must be backward-compatible when possible.

This file defines the API contract — not how analysis is computed.
"""