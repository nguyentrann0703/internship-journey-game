# Backend Integration Guide

## Runtime Direction

This backend is `Supabase-only` for v1.

Frontend integration should use:

- the Supabase project as the runtime backend
- RPC calls as the primary API surface
- a thin wrapper layer inside `apps/web` that calls the RPCs through `src/backend/client.js`

Recommended frontend pattern:

- create a Supabase browser client in `apps/web`
- wrap RPC calls in app-specific functions
- keep request/response shapes aligned with `src/shared/contracts.ts`

## Required Environment Variables

Frontend needs:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

Optional app-level variables:

- `NEXT_PUBLIC_GAME_ADMIN_CODE` for local admin testing only
- `NEXT_PUBLIC_GAME_JUDGE_CODES` for local judge testing only

Do not ship admin and judge codes to a public production frontend without an additional server or operator-only layer.

## Access Model

For v1, direct table access is not part of the public contract.

Use:

- RPCs for team, judge, and admin actions
- `get_public_leaderboard()` for public leaderboard reads

Current security posture:

- RPCs are intentionally code-gated, not Supabase Auth user-gated
- most internal helper functions are moved behind private helpers
- frontend should treat session tokens and admin/judge codes as operational secrets

## RPC Surface

### Team-facing

- `join_team(team_code, session_token, user_agent)`
- `get_current_team_state(session_token)`
- `submit_round1_answer(session_token, question_number, bet_amount, answer_text)`
- `get_assigned_round2_case(session_token)`

### Public-facing

- `get_public_leaderboard()`
- `get_active_presentation()`

### Judge-facing

- `submit_judge_score(judge_code, team_id, score_swot, score_logic, score_presentation)`

### Admin-facing

- `set_game_phase(admin_code, phase, countdown_ends_at, projector_message)`
- `mark_round1_results(admin_code, question_number, team_results_jsonb)`
- `activate_round2_team(admin_code, team_id)`
- `get_judge_submission_status(admin_code)`
- `publish_round2_result(admin_code, team_id)`
- `adjust_team_score(admin_code, team_id, patch_jsonb, note)`
- `grant_bonus_points(admin_code, team_id, points, note)`

## Session Flow

### Team flow

1. Generate a client-side random session token.
2. Call `join_team`.
3. Persist the session token in a secure cookie or local storage for the event session.
4. Use the same token for `get_current_team_state`, `submit_round1_answer`, and `get_assigned_round2_case`.

Behavior:

- a second login for the same team invalidates the previous active session
- invalid session tokens are rejected

### Judge flow

1. Judge enters a fixed judge code.
2. Frontend polls `get_active_presentation`.
3. Judge submits one score payload for the active team.

Behavior:

- one judge can submit only once per active presentation
- duplicate judge submission is rejected

### Admin flow

1. Admin enters the fixed admin code.
2. Admin drives phase changes and score publication through RPCs.
3. Admin corrections are logged in `admin_events`.

## Frontend Wrapper Recommendation

Frontend should call backend through a thin wrapper, not raw `supabase.rpc(...)` spread across components.

Suggested structure:

```text
apps/web/lib/supabase.ts
apps/web/lib/game-backend.ts
```

`game-backend.ts` should:

- call the RPCs
- normalize errors
- expose typed functions matching `src/shared/contracts.ts`

## Known v1 Constraints

- public leaderboard is RPC-driven, not yet a dedicated realtime projection table
- admin and judge identity are code-based for event speed
- Supabase Auth user accounts are not part of v1
- advanced anti-cheat and rate limiting are deferred

