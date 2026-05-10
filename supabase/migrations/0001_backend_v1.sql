begin;

create extension if not exists pgcrypto;

create type public.game_phase as enum (
  'lobby',
  'round1_question_open',
  'round1_betting_locked',
  'round1_reveal',
  'round2_case_draw',
  'round2_discussion',
  'round2_presentation',
  'bonus',
  'results',
  'paused'
);

create type public.user_role as enum ('team', 'judge', 'admin', 'public');

create type public.team_status as enum ('waiting', 'active', 'submitted', 'locked', 'offline');

create table public.round2_cases (
  id uuid primary key default gen_random_uuid(),
  case_number smallint not null unique check (case_number between 1 and 9),
  title text not null,
  prompt text not null,
  expected_swot jsonb not null,
  suggested_plan text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  team_code text not null unique,
  sort_key smallint not null unique check (sort_key between 1 and 9),
  round2_case_id uuid unique references public.round2_cases(id),
  token_balance integer not null default 10 check (token_balance >= 0),
  round1_points integer not null default 1 check (round1_points between 1 and 5),
  round2_points integer not null default 0 check (round2_points between 0 and 5),
  bonus_points integer not null default 0 check (bonus_points between 0 and 2),
  total_points integer generated always as (round1_points + round2_points + bonus_points) stored,
  display_rank integer not null default 1 check (display_rank >= 1),
  status public.team_status not null default 'waiting',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.round1_questions (
  id uuid primary key default gen_random_uuid(),
  question_number smallint not null unique check (question_number between 1 and 5),
  prompt text not null,
  answer_key text not null,
  difficulty text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.admin_accounts (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  admin_code text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.judge_accounts (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  judge_code text not null unique,
  sort_order smallint not null unique check (sort_order between 1 and 3),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.game_state (
  singleton boolean primary key default true,
  phase public.game_phase not null default 'lobby',
  round_number smallint not null default 1 check (round_number between 1 and 3),
  question_number smallint check (question_number between 1 and 5),
  active_team_id uuid references public.teams(id),
  countdown_ends_at timestamptz,
  is_submission_locked boolean not null default false,
  projector_message text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.team_sessions (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  session_token text not null unique,
  user_agent text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  last_seen_at timestamptz not null default timezone('utc', now()),
  revoked_at timestamptz
);

create table public.round1_submissions (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  question_number smallint not null references public.round1_questions(question_number),
  bet_amount integer not null check (bet_amount between 1 and 5),
  answer_text text not null,
  submitted_at timestamptz not null default timezone('utc', now()),
  is_correct boolean,
  token_delta integer not null default 0,
  marked_at timestamptz,
  processed_at timestamptz,
  unique (team_id, question_number)
);

create table public.round2_results (
  team_id uuid primary key references public.teams(id) on delete cascade,
  round2_case_id uuid not null references public.round2_cases(id),
  judge_count integer not null default 0 check (judge_count between 0 and 3),
  average_score numeric(4,2) check (average_score between 0 and 5),
  final_score integer check (final_score between 0 and 5),
  is_finalized boolean not null default false,
  is_published boolean not null default false,
  finalized_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.judge_scores (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  judge_id uuid not null references public.judge_accounts(id) on delete cascade,
  round2_case_id uuid not null references public.round2_cases(id),
  score_swot integer not null check (score_swot between 0 and 2),
  score_logic integer not null check (score_logic between 0 and 2),
  score_presentation integer not null check (score_presentation between 0 and 1),
  total_score integer generated always as (score_swot + score_logic + score_presentation) stored,
  submitted_at timestamptz not null default timezone('utc', now()),
  unique (team_id, judge_id)
);

create table public.admin_events (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.admin_accounts(id) on delete cascade,
  action text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index team_sessions_active_idx on public.team_sessions(team_id, is_active);
create index round1_submissions_question_idx on public.round1_submissions(question_number);
create index judge_scores_team_idx on public.judge_scores(team_id);
create index admin_events_admin_idx on public.admin_events(admin_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create trigger set_updated_at_round2_cases
before update on public.round2_cases
for each row execute function public.set_updated_at();

create trigger set_updated_at_teams
before update on public.teams
for each row execute function public.set_updated_at();

create trigger set_updated_at_round1_questions
before update on public.round1_questions
for each row execute function public.set_updated_at();

create trigger set_updated_at_admin_accounts
before update on public.admin_accounts
for each row execute function public.set_updated_at();

create trigger set_updated_at_judge_accounts
before update on public.judge_accounts
for each row execute function public.set_updated_at();

create trigger set_updated_at_game_state
before update on public.game_state
for each row execute function public.set_updated_at();

create trigger set_updated_at_round2_results
before update on public.round2_results
for each row execute function public.set_updated_at();

create or replace function public.points_for_tokens(p_tokens integer)
returns integer
language plpgsql
immutable
as $$
begin
  if p_tokens < 0 then
    raise exception 'Token balance cannot be negative.';
  elsif p_tokens >= 18 then
    return 5;
  elsif p_tokens >= 14 then
    return 4;
  elsif p_tokens >= 9 then
    return 3;
  elsif p_tokens >= 4 then
    return 2;
  end if;

  return 1;
end;
$$;

create or replace function public.require_admin(p_admin_code text)
returns public.admin_accounts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin public.admin_accounts;
begin
  select *
  into v_admin
  from public.admin_accounts
  where admin_code = p_admin_code and is_active = true;

  if v_admin.id is null then
    raise exception 'Invalid admin code.';
  end if;

  return v_admin;
end;
$$;

create or replace function public.require_judge(p_judge_code text)
returns public.judge_accounts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_judge public.judge_accounts;
begin
  select *
  into v_judge
  from public.judge_accounts
  where judge_code = p_judge_code and is_active = true;

  if v_judge.id is null then
    raise exception 'Invalid judge code.';
  end if;

  return v_judge;
end;
$$;

create or replace function public.require_team_session(p_session_token text)
returns public.team_sessions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.team_sessions;
begin
  select *
  into v_session
  from public.team_sessions
  where session_token = p_session_token and is_active = true;

  if v_session.id is null then
    raise exception 'Invalid team session.';
  end if;

  update public.team_sessions
  set last_seen_at = timezone('utc', now())
  where id = v_session.id;

  select *
  into v_session
  from public.team_sessions
  where id = v_session.id;

  return v_session;
end;
$$;

create or replace function public.log_admin_event(
  p_admin_id uuid,
  p_action text,
  p_payload jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.admin_events (admin_id, action, payload)
  values (p_admin_id, p_action, coalesce(p_payload, '{}'::jsonb));
$$;

create or replace function public.refresh_team_points(p_team_id uuid default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.teams
  set round1_points = public.points_for_tokens(token_balance)
  where p_team_id is null or id = p_team_id;
end;
$$;

create or replace function public.refresh_leaderboard()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  with ranked as (
    select
      id,
      dense_rank() over (order by total_points desc) as next_rank
    from public.teams
  )
  update public.teams as teams
  set display_rank = ranked.next_rank
  from ranked
  where ranked.id = teams.id;
end;
$$;

create or replace function public.join_team(
  p_team_code text,
  p_session_token text,
  p_user_agent text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_team public.teams;
begin
  select *
  into v_team
  from public.teams
  where team_code = p_team_code;

  if v_team.id is null then
    raise exception 'Invalid team code.';
  end if;

  update public.team_sessions
  set is_active = false,
      revoked_at = timezone('utc', now())
  where team_id = v_team.id and is_active = true and session_token <> p_session_token;

  insert into public.team_sessions (team_id, session_token, user_agent, is_active, revoked_at)
  values (v_team.id, p_session_token, p_user_agent, true, null)
  on conflict (session_token) do update
  set team_id = excluded.team_id,
      user_agent = excluded.user_agent,
      is_active = true,
      revoked_at = null,
      last_seen_at = timezone('utc', now());

  update public.teams
  set status = 'active'
  where id = v_team.id;

  return public.get_current_team_state(p_session_token);
end;
$$;

create or replace function public.get_current_team_state(p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.team_sessions;
  v_state public.game_state;
  v_team public.teams;
  v_submission public.round1_submissions;
begin
  v_session := public.require_team_session(p_session_token);

  select *
  into v_team
  from public.teams
  where id = v_session.team_id;

  select *
  into v_state
  from public.game_state
  where singleton = true;

  if v_state.question_number is not null then
    select *
    into v_submission
    from public.round1_submissions
    where team_id = v_team.id and question_number = v_state.question_number;
  end if;

  return jsonb_build_object(
    'team',
    jsonb_build_object(
      'id', v_team.id,
      'name', v_team.name,
      'token_balance', v_team.token_balance,
      'round1_points', v_team.round1_points,
      'round2_points', v_team.round2_points,
      'bonus_points', v_team.bonus_points,
      'total_points', v_team.total_points,
      'display_rank', v_team.display_rank,
      'status', v_team.status,
      'round2_case_id', v_team.round2_case_id
    ),
    'game_state',
    jsonb_build_object(
      'phase', v_state.phase,
      'round_number', v_state.round_number,
      'question_number', v_state.question_number,
      'active_team_id', v_state.active_team_id,
      'countdown_ends_at', v_state.countdown_ends_at,
      'projector_message', v_state.projector_message,
      'is_submission_locked', v_state.is_submission_locked
    ),
    'latest_submission',
    case
      when v_submission.id is null then null
      else jsonb_build_object(
        'question_number', v_submission.question_number,
        'bet_amount', v_submission.bet_amount,
        'answer_text', v_submission.answer_text,
        'is_correct', v_submission.is_correct
      )
    end
  );
end;
$$;

create or replace function public.submit_round1_answer(
  p_session_token text,
  p_question_number integer,
  p_bet_amount integer,
  p_answer_text text
)
returns public.round1_submissions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.team_sessions;
  v_team public.teams;
  v_state public.game_state;
  v_submission public.round1_submissions;
begin
  v_session := public.require_team_session(p_session_token);

  select *
  into v_team
  from public.teams
  where id = v_session.team_id;

  select *
  into v_state
  from public.game_state
  where singleton = true;

  if v_state.phase <> 'round1_question_open' then
    raise exception 'Round 1 is not accepting submissions.';
  end if;

  if v_state.question_number is distinct from p_question_number then
    raise exception 'Question number does not match the current game state.';
  end if;

  if v_state.is_submission_locked then
    raise exception 'Submissions are locked.';
  end if;

  if v_state.countdown_ends_at is not null and v_state.countdown_ends_at <= timezone('utc', now()) then
    raise exception 'Submission deadline has passed.';
  end if;

  if p_bet_amount < 1 or p_bet_amount > 5 then
    raise exception 'Bet amount must be between 1 and 5.';
  end if;

  if p_bet_amount > v_team.token_balance then
    raise exception 'Bet amount exceeds current token balance.';
  end if;

  insert into public.round1_submissions (
    team_id,
    question_number,
    bet_amount,
    answer_text,
    submitted_at,
    is_correct,
    token_delta,
    marked_at,
    processed_at
  )
  values (
    v_team.id,
    p_question_number,
    p_bet_amount,
    p_answer_text,
    timezone('utc', now()),
    null,
    0,
    null,
    null
  )
  on conflict (team_id, question_number) do update
  set bet_amount = excluded.bet_amount,
      answer_text = excluded.answer_text,
      submitted_at = timezone('utc', now()),
      is_correct = null,
      token_delta = 0,
      marked_at = null,
      processed_at = null
  returning *
  into v_submission;

  update public.teams
  set status = 'submitted'
  where id = v_team.id;

  return v_submission;
end;
$$;

create or replace function public.set_game_phase(
  p_admin_code text,
  p_phase public.game_phase,
  p_countdown_ends_at timestamptz default null,
  p_projector_message text default null
)
returns public.game_state
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin public.admin_accounts;
  v_state public.game_state;
begin
  v_admin := public.require_admin(p_admin_code);

  update public.game_state
  set phase = p_phase,
      countdown_ends_at = p_countdown_ends_at,
      projector_message = coalesce(p_projector_message, projector_message),
      is_submission_locked = case when p_phase = 'round1_betting_locked' then true else false end,
      round_number = case
        when p_phase::text like 'round1%' then 1
        when p_phase::text like 'round2%' then 2
        when p_phase = 'bonus' then 3
        else round_number
      end
  where singleton = true
  returning *
  into v_state;

  perform public.log_admin_event(
    v_admin.id,
    'set_game_phase',
    jsonb_build_object(
      'phase', p_phase,
      'countdown_ends_at', p_countdown_ends_at,
      'projector_message', p_projector_message
    )
  );

  return v_state;
end;
$$;

create or replace function public.mark_round1_results(
  p_admin_code text,
  p_question_number integer,
  p_team_results jsonb
)
returns table (team_id uuid, token_balance integer, token_delta integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin public.admin_accounts;
  v_entry jsonb;
  v_submission public.round1_submissions;
  v_delta integer;
begin
  v_admin := public.require_admin(p_admin_code);

  for v_entry in
    select value
    from jsonb_array_elements(p_team_results)
  loop
    select *
    into v_submission
    from public.round1_submissions
    where team_id = (v_entry ->> 'team_id')::uuid
      and question_number = p_question_number;

    if v_submission.id is null then
      raise exception 'Missing submission for team % on question %.', v_entry ->> 'team_id', p_question_number;
    end if;

    if v_submission.processed_at is not null then
      raise exception 'Submission for team % was already processed.', v_submission.team_id;
    end if;

    v_delta := case when (v_entry ->> 'is_correct')::boolean then v_submission.bet_amount else -v_submission.bet_amount end;

    update public.round1_submissions
    set is_correct = (v_entry ->> 'is_correct')::boolean,
        token_delta = v_delta,
        marked_at = timezone('utc', now()),
        processed_at = timezone('utc', now())
    where id = v_submission.id;

    update public.teams
    set token_balance = token_balance + v_delta,
        status = 'active'
    where id = v_submission.team_id;
  end loop;

  perform public.refresh_team_points();
  perform public.refresh_leaderboard();
  perform public.log_admin_event(
    v_admin.id,
    'mark_round1_results',
    jsonb_build_object(
      'question_number', p_question_number,
      'team_results', p_team_results
    )
  );

  return query
  select teams.id, teams.token_balance, submissions.token_delta
  from public.teams as teams
  join public.round1_submissions as submissions
    on submissions.team_id = teams.id
  where submissions.question_number = p_question_number
  order by teams.sort_key;
end;
$$;

create or replace function public.activate_round2_team(
  p_admin_code text,
  p_team_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin public.admin_accounts;
  v_team public.teams;
  v_case public.round2_cases;
begin
  v_admin := public.require_admin(p_admin_code);

  select *
  into v_team
  from public.teams
  where id = p_team_id;

  if v_team.id is null then
    raise exception 'Team not found.';
  end if;

  select *
  into v_case
  from public.round2_cases
  where id = v_team.round2_case_id;

  update public.game_state
  set active_team_id = p_team_id,
      phase = 'round2_presentation',
      round_number = 2
  where singleton = true;

  perform public.log_admin_event(
    v_admin.id,
    'activate_round2_team',
    jsonb_build_object(
      'team_id', p_team_id,
      'round2_case_id', v_case.id
    )
  );

  return public.get_active_presentation();
end;
$$;

create or replace function public.get_active_presentation()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_state public.game_state;
  v_team public.teams;
  v_case public.round2_cases;
  v_submission_count integer;
begin
  select *
  into v_state
  from public.game_state
  where singleton = true;

  if v_state.active_team_id is null then
    return jsonb_build_object(
      'active_team', null,
      'round2_case', null,
      'judge_submission_count', 0,
      'phase', v_state.phase
    );
  end if;

  select *
  into v_team
  from public.teams
  where id = v_state.active_team_id;

  select *
  into v_case
  from public.round2_cases
  where id = v_team.round2_case_id;

  select count(*)
  into v_submission_count
  from public.judge_scores
  where team_id = v_team.id;

  return jsonb_build_object(
    'phase', v_state.phase,
    'active_team',
    jsonb_build_object(
      'id', v_team.id,
      'name', v_team.name,
      'display_rank', v_team.display_rank
    ),
    'round2_case',
    jsonb_build_object(
      'id', v_case.id,
      'case_number', v_case.case_number,
      'title', v_case.title,
      'prompt', v_case.prompt
    ),
    'judge_submission_count', v_submission_count
  );
end;
$$;

create or replace function public.get_assigned_round2_case(p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.team_sessions;
  v_team public.teams;
  v_case public.round2_cases;
begin
  v_session := public.require_team_session(p_session_token);

  select *
  into v_team
  from public.teams
  where id = v_session.team_id;

  select *
  into v_case
  from public.round2_cases
  where id = v_team.round2_case_id;

  return jsonb_build_object(
    'team_id', v_team.id,
    'team_name', v_team.name,
    'case',
    jsonb_build_object(
      'id', v_case.id,
      'case_number', v_case.case_number,
      'title', v_case.title,
      'prompt', v_case.prompt
    )
  );
end;
$$;

create or replace function public.submit_judge_score(
  p_judge_code text,
  p_team_id uuid,
  p_score_swot integer,
  p_score_logic integer,
  p_score_presentation integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_judge public.judge_accounts;
  v_state public.game_state;
  v_team public.teams;
  v_case public.round2_cases;
  v_average numeric(4,2);
  v_final integer;
  v_count integer;
begin
  v_judge := public.require_judge(p_judge_code);

  select *
  into v_state
  from public.game_state
  where singleton = true;

  if v_state.phase <> 'round2_presentation' then
    raise exception 'Round 2 is not accepting judge scores.';
  end if;

  if v_state.active_team_id is distinct from p_team_id then
    raise exception 'The requested team is not the active presentation.';
  end if;

  select *
  into v_team
  from public.teams
  where id = p_team_id;

  if v_team.id is null then
    raise exception 'Team not found.';
  end if;

  select *
  into v_case
  from public.round2_cases
  where id = v_team.round2_case_id;

  insert into public.judge_scores (
    team_id,
    judge_id,
    round2_case_id,
    score_swot,
    score_logic,
    score_presentation,
    submitted_at
  )
  values (
    v_team.id,
    v_judge.id,
    v_case.id,
    p_score_swot,
    p_score_logic,
    p_score_presentation,
    timezone('utc', now())
  )
  on conflict (team_id, judge_id) do update
  set round2_case_id = excluded.round2_case_id,
      score_swot = excluded.score_swot,
      score_logic = excluded.score_logic,
      score_presentation = excluded.score_presentation,
      submitted_at = timezone('utc', now());

  select count(*), avg(total_score)
  into v_count, v_average
  from public.judge_scores
  where team_id = v_team.id;

  v_final := case when v_count = 3 then floor(v_average)::integer else null end;

  insert into public.round2_results (
    team_id,
    round2_case_id,
    judge_count,
    average_score,
    final_score,
    is_finalized,
    finalized_at
  )
  values (
    v_team.id,
    v_case.id,
    v_count,
    v_average,
    v_final,
    v_count = 3,
    case when v_count = 3 then timezone('utc', now()) else null end
  )
  on conflict (team_id) do update
  set round2_case_id = excluded.round2_case_id,
      judge_count = excluded.judge_count,
      average_score = excluded.average_score,
      final_score = excluded.final_score,
      is_finalized = excluded.is_finalized,
      finalized_at = excluded.finalized_at;

  return jsonb_build_object(
    'team_id', v_team.id,
    'judge_count', v_count,
    'average_score', v_average,
    'final_score', v_final,
    'is_finalized', v_count = 3
  );
end;
$$;

create or replace function public.publish_round2_result(
  p_admin_code text,
  p_team_id uuid
)
returns public.round2_results
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin public.admin_accounts;
  v_result public.round2_results;
begin
  v_admin := public.require_admin(p_admin_code);

  select *
  into v_result
  from public.round2_results
  where team_id = p_team_id;

  if v_result.team_id is null then
    raise exception 'No round 2 result found for team.';
  end if;

  if not v_result.is_finalized then
    raise exception 'Round 2 result is not finalized yet.';
  end if;

  update public.round2_results
  set is_published = true,
      published_at = timezone('utc', now())
  where team_id = p_team_id
  returning *
  into v_result;

  update public.teams
  set round2_points = v_result.final_score
  where id = p_team_id;

  perform public.refresh_leaderboard();
  perform public.log_admin_event(
    v_admin.id,
    'publish_round2_result',
    jsonb_build_object(
      'team_id', p_team_id,
      'final_score', v_result.final_score
    )
  );

  return v_result;
end;
$$;

create or replace function public.adjust_team_score(
  p_admin_code text,
  p_team_id uuid,
  p_patch jsonb,
  p_note text default null
)
returns public.teams
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin public.admin_accounts;
  v_team public.teams;
begin
  v_admin := public.require_admin(p_admin_code);

  update public.teams
  set token_balance = coalesce((p_patch ->> 'token_balance')::integer, token_balance),
      round2_points = coalesce((p_patch ->> 'round2_points')::integer, round2_points),
      bonus_points = coalesce((p_patch ->> 'bonus_points')::integer, bonus_points)
  where id = p_team_id
  returning *
  into v_team;

  if v_team.id is null then
    raise exception 'Team not found.';
  end if;

  perform public.refresh_team_points(v_team.id);
  perform public.refresh_leaderboard();
  perform public.log_admin_event(
    v_admin.id,
    'adjust_team_score',
    jsonb_build_object(
      'team_id', p_team_id,
      'patch', p_patch,
      'note', p_note
    )
  );

  select *
  into v_team
  from public.teams
  where id = p_team_id;

  return v_team;
end;
$$;

create or replace function public.grant_bonus_points(
  p_admin_code text,
  p_team_id uuid,
  p_points integer default 2,
  p_note text default null
)
returns public.teams
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin public.admin_accounts;
  v_team public.teams;
begin
  v_admin := public.require_admin(p_admin_code);

  if p_points < 0 or p_points > 2 then
    raise exception 'Bonus points must be between 0 and 2.';
  end if;

  update public.teams
  set bonus_points = least(2, bonus_points + p_points)
  where id = p_team_id
  returning *
  into v_team;

  if v_team.id is null then
    raise exception 'Team not found.';
  end if;

  perform public.refresh_leaderboard();
  perform public.log_admin_event(
    v_admin.id,
    'grant_bonus_points',
    jsonb_build_object(
      'team_id', p_team_id,
      'points', p_points,
      'note', p_note
    )
  );

  return v_team;
end;
$$;

create view public.leaderboard_view as
select
  id,
  name,
  sort_key,
  token_balance,
  round1_points,
  round2_points,
  bonus_points,
  total_points,
  display_rank,
  status
from public.teams
order by total_points desc, sort_key asc;

create view public.judge_submission_status_view as
select
  teams.id as team_id,
  teams.name as team_name,
  teams.round2_case_id,
  count(judge_scores.id) as judge_submission_count,
  array_agg(judge_accounts.display_name order by judge_accounts.sort_order)
    filter (where judge_accounts.display_name is not null) as submitted_by
from public.teams
left join public.judge_scores
  on judge_scores.team_id = teams.id
left join public.judge_accounts
  on judge_accounts.id = judge_scores.judge_id
group by teams.id, teams.name, teams.round2_case_id;

alter table public.round2_cases enable row level security;
alter table public.teams enable row level security;
alter table public.round1_questions enable row level security;
alter table public.admin_accounts enable row level security;
alter table public.judge_accounts enable row level security;
alter table public.game_state enable row level security;
alter table public.team_sessions enable row level security;
alter table public.round1_submissions enable row level security;
alter table public.round2_results enable row level security;
alter table public.judge_scores enable row level security;
alter table public.admin_events enable row level security;

grant select on public.leaderboard_view to anon, authenticated;
grant select on public.judge_submission_status_view to anon, authenticated;
grant execute on function public.join_team(text, text, text) to anon, authenticated;
grant execute on function public.get_current_team_state(text) to anon, authenticated;
grant execute on function public.submit_round1_answer(text, integer, integer, text) to anon, authenticated;
grant execute on function public.get_active_presentation() to anon, authenticated;
grant execute on function public.get_assigned_round2_case(text) to anon, authenticated;
grant execute on function public.submit_judge_score(text, uuid, integer, integer, integer) to anon, authenticated;
grant execute on function public.set_game_phase(text, public.game_phase, timestamptz, text) to anon, authenticated;
grant execute on function public.mark_round1_results(text, integer, jsonb) to anon, authenticated;
grant execute on function public.activate_round2_team(text, uuid) to anon, authenticated;
grant execute on function public.publish_round2_result(text, uuid) to anon, authenticated;
grant execute on function public.adjust_team_score(text, uuid, jsonb, text) to anon, authenticated;
grant execute on function public.grant_bonus_points(text, uuid, integer, text) to anon, authenticated;

commit;
