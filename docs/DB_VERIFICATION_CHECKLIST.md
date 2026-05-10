# DB Verification Checklist

Use this checklist after every migration or before event day.

## Required Tables

- `teams`
- `game_state`
- `round1_questions`
- `round1_submissions`
- `round2_cases`
- `judge_scores`
- `round2_results`
- `team_sessions`
- `admin_events`
- `admin_accounts`
- `judge_accounts`

## Required Functions

- `join_team`
- `get_current_team_state`
- `submit_round1_answer`
- `get_assigned_round2_case`
- `get_active_presentation`
- `get_public_leaderboard`
- `submit_judge_score`
- `set_game_phase`
- `mark_round1_results`
- `activate_round2_team`
- `get_judge_submission_status`
- `publish_round2_result`
- `adjust_team_score`
- `grant_bonus_points`

## Required Seed Counts

- `teams = 9`
- `round1_questions = 5`
- `round2_cases = 9`
- `judge_accounts = 3`
- `admin_accounts = 1`
- `game_state = 1`

## Default Operational Codes

Current seeded defaults:

- admin: `ADMIN-UEH`
- judges: `JUDGE-01`, `JUDGE-02`, `JUDGE-03`
- teams: `TEAM-01` to `TEAM-09`

Before a real event:

- confirm whether these defaults stay as-is
- or rotate them and update the operator guide

## Behavior Checks

- team relogin revokes the prior session
- invalid team session is rejected
- round 1 rejects wrong phase and expired countdown
- round 1 result marking updates token balance and rank
- judge duplicate submission is rejected
- round 2 final score floors correctly after 3 judges
- publish writes round 2 points to `teams`
- bonus/admin adjustments create `admin_events`

## Recommended Advisor Checks

- run Supabase security advisors
- run Supabase performance advisors
- review any remaining warnings before event day

