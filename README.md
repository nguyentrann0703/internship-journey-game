# Internship Journey Game

Collaborative repo structure for the UEH classroom game project.

## Structure

```text
apps/
  web/                # Frontend app lives here
docs/                 # Product, roadmap, and technical docs
src/
  backend/            # Shared backend-side JS helpers for app integration
  shared/             # Contracts, enums, and types shared with frontend
supabase/
  migrations/         # Source of truth for schema and RPC functions
  seed.sql            # Local/provisioning seed data
tests/                # Logic-level tests
```

## Collaboration rule of thumb

- Frontend builds inside `apps/web`.
- Backend database logic lives in `supabase/`.
- Shared interfaces go in `src/shared/`.
- App-facing backend helpers go in `src/backend/`.
- Product and implementation context stays in `docs/`.

## Current backend status

- Supabase schema and RPC scaffold is in place.
- Seed data includes teams, judges, admin, round 1 questions, and round 2 cases.
- Shared contract file is available for frontend integration.
- Logic tests currently cover scoring and leaderboard ranking rules.

