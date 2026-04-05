"""
Data models (placeholder)

This module is intentionally empty at the current stage.

Current architecture:
- The backend operates without a database.
- Analysis data lives in cache and service layers.
- There is no persistent storage requiring ORM models yet.

Why models are not defined now:
- Database schema is not finalized.
- Premature models would cause refactors once real usage data exists.
- Product validation (AI flow, premium logic, UX) takes priority.

Planned future usage (V2+):
- ORM models for:
  - User
  - Analysis
  - Progress snapshots
  - Subscriptions
  - Social / Looksmatch features
- Models will be introduced together with database.py
  and repository layer.

Design principle:
- Models should represent real persisted data,
  not temporary in-memory structures.

This file exists to:
- Reserve the architectural layer
- Prevent future breaking changes
- Make intent explicit for future development
"""