# Backend Verification Results

Verification was executed against the real Supabase project:

- project: `internship-journey-db`
- ref: `fxzdkqjexwewazswfjsg`

## Verified Happy Paths

- `join_team` creates a valid team session
- second `join_team` for the same team revokes the previous session
- `get_current_team_state` returns the active session state
- `set_game_phase` opens round 1 correctly
- `submit_round1_answer` accepts a valid submission
- `mark_round1_results` updates token balance and leaderboard
- `activate_round2_team` switches to the active presentation
- `get_assigned_round2_case` returns the team-specific SWOT case
- `submit_judge_score` aggregates 3 judge submissions
- round 2 final score is floored correctly
- `publish_round2_result` writes `round2_points` back to `teams`
- `grant_bonus_points` updates totals
- `adjust_team_score` recalculates round 1 score buckets and leaderboard
- `admin_events` records admin mutations

## Verified Rejections

- invalid team code is rejected
- invalid/revoked team session is rejected
- round 1 submission in the wrong phase is rejected
- round 1 submission after countdown expiry is rejected
- bet above `5` is rejected
- bet above current token balance is rejected
- judge submission for a non-active team is rejected
- duplicate judge submission is rejected

## Post-Verification Reset

After verification, the project was reset to a clean seeded baseline:

- `round1_submissions = 0`
- `judge_scores = 0`
- `round2_results = 0`
- `team_sessions = 0`
- `admin_events = 0`
- teams reset to `token_balance = 10`, `round2_points = 0`, `bonus_points = 0`
- `game_state` reset to `lobby`

## Remaining Advisor Warnings

### Security

Remaining warnings are currently intentional for v1:

- `rls_enabled_no_policy` on public tables
  - accepted because v1 is documented as `RPC-only`, not direct table access
- `anon_security_definer_function_executable` on public RPC functions
  - accepted because v1 uses code-gated RPC calls over the anon key for event speed

Resolved compared to the initial foundation:

- security definer view warnings were removed
- authenticated-role execute warnings were reduced by narrowing grants to `anon`
- internal helper functions were moved behind private helpers

### Performance

Remaining performance items are informational:

- newly added indexes are currently reported as unused because the dataset is tiny and the project is fresh

