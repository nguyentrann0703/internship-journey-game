# TECH SPEC

## Overview

This project is a live classroom game web app for the UEH soft-skills activity "Hanh Trinh Thuc Tap Sinh". The system supports 9 teams, 3 judges, 1 admin/operator, and a public leaderboard/projector view.

Primary goals:

- run smoothly for about 30 minutes in a classroom setting
- support real-time updates across all devices
- minimize operator error during live hosting
- keep the game state recoverable if a device reconnects

## Game Structure

### Round 1: Token Challenge

- Each team starts with `10` tokens.
- There are `5` questions.
- Before each question, each team places a bet from `1` to `5` tokens.
- Correct answer: add the bet amount.
- Wrong answer: subtract the bet amount.
- Admin manually marks each team as correct or wrong after teams raise their boards.

Round 1 score conversion:

| Tokens left | Round 1 points |
| --- | --- |
| `18+` | `5` |
| `14-17` | `4` |
| `9-13` | `3` |
| `4-8` | `2` |
| `0-3` | `1` |

### Round 2: SWOT Presentation

- Each team receives `1` SWOT case from a pool of `9`.
- All teams discuss for `2 minutes`.
- One representative presents in `1 minute`.
- `3` judges score independently.
- Final round score = average of 3 judge scores, rounded down with `floor`.

Rubric:

- SWOT correctness and completeness: `2`
- Logic and reasoning: `2`
- Presentation confidence and clarity: `1`

### Bonus Round: Cross the Road

- Each team gets one attempt.
- Finishing the game grants `+2` bonus points.

### Final Score

`total_score = round_1_points + round_2_points + bonus_points`

Maximum total score: `12`

## User Roles

### Admin

Permissions:

- control phase and question flow
- open/close betting
- reveal answers
- mark round 1 results per team
- start round 2 presentations
- monitor judge submissions
- publish final round 2 score
- manually edit leaderboard values if needed
- pause or reset the game in emergencies

### Judge

Permissions:

- view only the active team/case to score
- submit one score per presentation

Restrictions:

- cannot control game flow
- cannot edit team data directly

### Team / Student

Permissions:

- join as one assigned team
- place bets in round 1
- submit answers in round 1
- view assigned SWOT case in round 2
- play the bonus game

Restrictions:

- cannot submit after timeout
- should be limited to one active team session

### Public / Projector

Displays:

- waiting screen
- current question or case
- countdown timer
- leaderboard
- celebration effects

## Core Views

### `/student`

Main UI states:

- lobby / waiting
- round 1 betting and answer submission
- submitted / locked
- round 2 case discussion
- bonus game
- eliminated / disabled overlay if needed

Key elements:

- token balance
- bet input or slider
- answer input
- countdown synced from server
- status messages

### `/admin`

Main sections:

- top status bar for phase, connectivity, and judge readiness
- round 1 control panel
- team verification grid for correct/wrong marking
- round 2 presentation controller
- judge submission monitor
- leaderboard with manual edit actions

### `/judge/:id` or equivalent judge route

Main elements:

- active team information
- simple 1-5 scoring UI
- submit state indicator

### `/leaderboard`

Displays:

- real-time ranking
- podium/top 3 emphasis
- current phase context
- projector-friendly typography and layout

## Suggested State Model

Top-level game phases:

- `lobby`
- `round1_question_open`
- `round1_betting_locked`
- `round1_reveal`
- `round2_case_draw`
- `round2_discussion`
- `round2_presentation`
- `bonus`
- `results`
- `paused`

Suggested `game_state` fields:

- `phase`
- `round`
- `question_number`
- `active_team_id`
- `countdown_ends_at`
- `is_submission_locked`
- `projector_message`
- `updated_at`

## Suggested Data Model

### `teams`

- `id`
- `name`
- `token_balance`
- `round_1_points`
- `round_2_points`
- `bonus_points`
- `total_points`
- `status`

### `round1_submissions`

- `id`
- `team_id`
- `question_number`
- `bet_amount`
- `answer_text`
- `submitted_at`
- `is_correct`
- `token_delta`

### `round2_cases`

- `id`
- `title`
- `prompt`
- `expected_swot`
- `suggested_plan`

### `judge_scores`

- `id`
- `team_id`
- `judge_id`
- `round2_case_id`
- `score_swot`
- `score_logic`
- `score_presentation`
- `total_score`
- `submitted_at`

### `team_sessions`

- `id`
- `team_id`
- `device_fingerprint` or `session_id`
- `last_seen_at`
- `is_active`

## Core Business Rules

- A team cannot bet more than `5`.
- A team cannot bet more than its current token balance.
- Round 1 submissions must be rejected after the server lock time.
- Judge submissions should count only once per judge per team presentation.
- Round 2 final score is calculated only when all required judge scores are present.
- Reconnects must restore the current game phase and team state.
- Manual admin edits must be logged if implemented.

## Real-Time Requirements

- All critical screens should update without refresh.
- Target update latency should feel near-instant in the classroom setting.
- Countdown source of truth must come from the server/backend, not the client.
- Leaderboard changes should propagate to student, admin, and projector views.

## UX Priorities

- projector view must be large, clear, and low-risk for live operation
- admin actions should be simple and hard to misclick
- judge UI should be minimal and fast on phones
- student UI should work primarily on mobile devices
- use clear success/error/locked states

## Technical Direction

Frontend:

- Next.js App Router
- Tailwind CSS
- shadcn/ui
- Framer Motion

Backend / Realtime:

- Supabase or Firebase for production realtime state
- FastAPI can be used as a local logic testbed and contract reference if desired

## Delivery Priority

### Phase 1

- define routes
- define state machine
- define schema and enums
- build base layouts for admin, student, leaderboard, judge

### Phase 2

- implement round 1 end-to-end
- implement realtime leaderboard
- implement round 2 judge scoring flow

### Phase 3

- implement bonus game integration
- add recovery, anti-cheat, and operator safeguards
- polish animation and projector mode

## Open Decisions

These should be confirmed before full implementation:

- production backend choice: `Supabase` or `Firebase`
- authentication/session strategy for teams and judges
- whether admin manual edits need audit history
- whether round 2 teams discuss simultaneously or one-by-one in the actual UI flow
- exact rule for ties on leaderboard
