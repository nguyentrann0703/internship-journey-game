begin;

create schema if not exists private;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.points_for_tokens(p_tokens integer)
returns integer
language plpgsql
immutable
set search_path = public
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

create or replace function private.require_admin(p_admin_code text)
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

create or replace function private.require_judge(p_judge_code text)
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

create or replace function private.require_team_session(p_session_token text)
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

create or replace function private.log_admin_event(
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

create or replace function private.refresh_team_points(p_team_id uuid default null)
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

create or replace function private.refresh_leaderboard()
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

create index if not exists game_state_active_team_idx on public.game_state(active_team_id);
create index if not exists judge_scores_judge_id_idx on public.judge_scores(judge_id);
create index if not exists judge_scores_round2_case_id_idx on public.judge_scores(round2_case_id);
create index if not exists round2_results_round2_case_id_idx on public.round2_results(round2_case_id);

create or replace view public.leaderboard_view
with (security_invoker = true) as
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

create or replace view public.judge_submission_status_view
with (security_invoker = true) as
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

create or replace function public.get_public_leaderboard()
returns setof public.leaderboard_view
language sql
security definer
set search_path = public
as $$
  select *
  from public.leaderboard_view
  order by total_points desc, sort_key asc;
$$;

create or replace function public.get_judge_submission_status(p_admin_code text)
returns setof public.judge_submission_status_view
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_admin public.admin_accounts;
begin
  v_admin := private.require_admin(p_admin_code);

  return query
  select *
  from public.judge_submission_status_view
  order by team_name asc;
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
set search_path = public, private
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
set search_path = public, private
as $$
declare
  v_session public.team_sessions;
  v_state public.game_state;
  v_team public.teams;
  v_submission public.round1_submissions;
begin
  v_session := private.require_team_session(p_session_token);

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
set search_path = public, private
as $$
declare
  v_session public.team_sessions;
  v_team public.teams;
  v_state public.game_state;
  v_submission public.round1_submissions;
begin
  v_session := private.require_team_session(p_session_token);

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
set search_path = public, private
as $$
declare
  v_admin public.admin_accounts;
  v_state public.game_state;
begin
  v_admin := private.require_admin(p_admin_code);

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

  perform private.log_admin_event(
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
set search_path = public, private
as $$
declare
  v_admin public.admin_accounts;
  v_entry jsonb;
  v_submission public.round1_submissions;
  v_delta integer;
begin
  v_admin := private.require_admin(p_admin_code);

  for v_entry in
    select value
    from jsonb_array_elements(p_team_results)
  loop
    select *
    into v_submission
    from public.round1_submissions as submissions
    where submissions.team_id = (v_entry ->> 'team_id')::uuid
      and submissions.question_number = p_question_number;

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

    update public.teams as teams
    set token_balance = teams.token_balance + v_delta,
        status = 'active'
    where teams.id = v_submission.team_id;
  end loop;

  perform private.refresh_team_points();
  perform private.refresh_leaderboard();
  perform private.log_admin_event(
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
set search_path = public, private
as $$
declare
  v_admin public.admin_accounts;
  v_team public.teams;
  v_case public.round2_cases;
begin
  v_admin := private.require_admin(p_admin_code);

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

  perform private.log_admin_event(
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
set search_path = public, private
as $$
declare
  v_session public.team_sessions;
  v_team public.teams;
  v_case public.round2_cases;
begin
  v_session := private.require_team_session(p_session_token);

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
set search_path = public, private
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
  v_judge := private.require_judge(p_judge_code);

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

  if exists (
    select 1
    from public.judge_scores
    where team_id = p_team_id and judge_id = v_judge.id
  ) then
    raise exception 'Judge has already submitted for this team.';
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
  );

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
set search_path = public, private
as $$
declare
  v_admin public.admin_accounts;
  v_result public.round2_results;
begin
  v_admin := private.require_admin(p_admin_code);

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

  perform private.refresh_leaderboard();
  perform private.log_admin_event(
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
set search_path = public, private
as $$
declare
  v_admin public.admin_accounts;
  v_team public.teams;
begin
  v_admin := private.require_admin(p_admin_code);

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

  perform private.refresh_team_points(v_team.id);
  perform private.refresh_leaderboard();
  perform private.log_admin_event(
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
set search_path = public, private
as $$
declare
  v_admin public.admin_accounts;
  v_team public.teams;
begin
  v_admin := private.require_admin(p_admin_code);

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

  perform private.refresh_leaderboard();
  perform private.log_admin_event(
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

insert into public.round2_cases (case_number, title, prompt, expected_swot, suggested_plan)
values
  (
    1,
    'An - Tai chinh',
    'An, 22 tuoi, sinh vien nam 4 nganh Tai chinh. GPA 3.6, xu ly so lieu tot, ngai thuyet trinh, chua tung di thuc tap. Cong ty fintech dang tuyen manh nhung yeu cau ung vien co it nhat 6 thang thuc tap.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Gioi xu ly va phan tich so lieu', 'GPA cao'),
      'weaknesses', jsonb_build_array('Ngai thuyet trinh', 'Thieu tu tin giao tiep', 'Chua co kinh nghiem thuc tap'),
      'opportunities', jsonb_build_array('Fintech dang tuyen manh', 'Nhu cau phu hop the manh phan tich du lieu'),
      'threats', jsonb_build_array('Yeu cau toi thieu 6 thang thuc tap')
    ),
    'Tim thuc tap fintech ngay hoc ky cuoi va tham gia workshop de luyen thuyet trinh.'
  ),
  (
    2,
    'Bao - Quan tri kinh doanh',
    'Bao, 23 tuoi, vua tot nghiep nganh Quan tri kinh doanh. Bao giao tiep tot, hay phan cong cong viec cho nhom, nhung hay tre deadline va yeu phan tich so lieu. Startup dang tuyen Business Development Executive va yeu cau tu quan ly tien do.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Giao tiep tot', 'Thuyet phuc gioi', 'Co kinh nghiem leadership nhom'),
      'weaknesses', jsonb_build_array('Hay tre deadline', 'Yeu phan tich so lieu'),
      'opportunities', jsonb_build_array('Startup dang tuyen Business Development Executive'),
      'threats', jsonb_build_array('Vi tri doi hoi tu quan ly tien do va lam viec doc lap')
    ),
    'Ung tuyen Business Development Executive va dung Notion hoac Trello de quan ly deadline.'
  ),
  (
    3,
    'Chi - Marketing',
    'Chi, 21 tuoi, sinh vien nam 3 nganh Marketing. Co trang lifestyle 5000 followers, gioi quay edit video, nhung tieng Anh yeu va khong co chung chi. Agency nuoc ngoai dang mo van phong o Viet Nam va tuyen Digital Marketer yeu cau giao tiep tieng Anh luu loat.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Gioi lam content', 'Co personal brand thuc te voi 5000 followers'),
      'weaknesses', jsonb_build_array('Tieng Anh yeu', 'Khong co chung chi'),
      'opportunities', jsonb_build_array('Agency nuoc ngoai dang tuyen Digital Marketer gap'),
      'threats', jsonb_build_array('Yeu cau giao tiep tieng Anh luu loat')
    ),
    'Luyen tieng Anh giao tiep va dung trang 5000 followers lam portfolio khi apply.'
  ),
  (
    4,
    'Dung - Logistics',
    'Dung, 24 tuoi, da di lam 1 nam tai cong ty logistics nho. Dang tin cay va dung gio nhung thu dong, it de xuat cai tien va ngai hoc he thong moi. Nganh logistics dang chuyen doi so manh me.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Dang tin cay', 'Dung gio', 'Duoc sep tin tuong'),
      'weaknesses', jsonb_build_array('Thu dong', 'It de xuat', 'Ngai hoc cong nghe moi'),
      'opportunities', jsonb_build_array('Chuyen doi so mo ra co hoi thang tien'),
      'threats', jsonb_build_array('Nguoi khong thich nghi se bi danh gia thieu nang dong')
    ),
    'Chu dong xin tham gia trien khai he thong moi va de xuat it nhat 1 cai tien nho moi thang.'
  ),
  (
    5,
    'Emm - CNTT',
    'Emm, 22 tuoi, sinh vien nam 4 nganh CNTT. Code gioi, co 2 du an GitHub va giai ba hackathon, nhung kho lam viec nhom va hay ap dat. Startup cong nghe rat can developer nhung teamwork la tieu chi hang dau.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Code gioi', 'Co portfolio thuc te', 'Tung dat giai hackathon'),
      'weaknesses', jsonb_build_array('Kho lam viec nhom', 'Khong chiu nhan gop y', 'Hay ap dat'),
      'opportunities', jsonb_build_array('Startup cong nghe bung no', 'Nhu cau developer cao'),
      'threats', jsonb_build_array('Teamwork la tieu chi tuyen dung hang dau')
    ),
    'Tham gia du an nhom va luyen lang nghe, tiep nhan gop y truoc khi phan bac.'
  ),
  (
    6,
    'Phong - Ke toan',
    'Phong, 23 tuoi, vua tot nghiep nganh Ke toan. Chuyen mon vung va can than nhung khong co LinkedIn, khong networking. Doanh nghiep dang tuyen gap nhung thuong yeu cau phong van nhieu vong va gioi thieu trong nganh.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Chuyen mon vung', 'Ti mi', 'Can than'),
      'weaknesses', jsonb_build_array('Khong co network', 'Khong co LinkedIn', 'Tu duy khep kin'),
      'opportunities', jsonb_build_array('Doanh nghiep tuyen gap', 'Chap nhan sinh vien moi neu co thai do cau thi'),
      'threats', jsonb_build_array('Tuyen qua gioi thieu va phong van nhieu vong')
    ),
    'Lap LinkedIn ngay va tham gia hoi nhom ke toan chuyen nghiep de xay network.'
  ),
  (
    7,
    'Giang - Luat',
    'Giang, 21 tuoi, sinh vien nam 3 nganh Luat. Hung bien tot, phan tich sac ben nhung thieu dinh huong va hay so sanh ban than. Luat cong nghe va so huu tri tue dang thieu nhan luc.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Tu duy phap ly sac ben', 'Ky nang hung bien tot'),
      'weaknesses', jsonb_build_array('Thieu dinh huong', 'Hay so sanh ban than'),
      'opportunities', jsonb_build_array('Luat cong nghe thieu nhan luc', 'Luat so huu tri tue it nguoi biet'),
      'threats', jsonb_build_array('Khong co dinh huong se bo lo co hoi ngach')
    ),
    'Tim hieu va thu thuc tap o van phong luat cong nghe hoac so huu tri tue.'
  ),
  (
    8,
    'Huy - Truyen thong',
    'Huy, 25 tuoi, da di lam 2 nam trong nganh truyen thong. Manh ve network va to chuc su kien, nhung viet content yeu. Thuong hieu dang cat giam ngan sach event truc tiep va dau tu vao content digital.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Network rong', 'Co kinh nghiem to chuc su kien thuc te'),
      'weaknesses', jsonb_build_array('Viet lach yeu', 'Khong co bang cap chuyen nganh'),
      'opportunities', jsonb_build_array('Thuong hieu dau tu manh vao content digital'),
      'threats', jsonb_build_array('Ngan sach su kien bi cat giam')
    ),
    'Tan dung network de hoc content va viet portfolio tu cac su kien da to chuc.'
  ),
  (
    9,
    'Ivy - Ngoai thuong',
    'Ivy, 22 tuoi, sinh vien nam 4 nganh Ngoai thuong. IELTS 7.5, tung trao doi 1 hoc ky tai Singapore nhung thieu quyet doan va ngai xung dot. Chuong trinh Management Trainee uu tien profile quoc te nhung rat ap luc.',
    jsonb_build_object(
      'strengths', jsonb_build_array('Tieng Anh xuat sac', 'Co kinh nghiem quoc te'),
      'weaknesses', jsonb_build_array('Thieu quyet doan', 'Hay lo lang', 'Tranh xung dot'),
      'opportunities', jsonb_build_array('Management Trainee uu tien dung profile'),
      'threats', jsonb_build_array('Ap luc cao va doi hoi ra quyet dinh nhanh')
    ),
    'Luyen ra quyet dinh nhanh qua mock interview va apply Management Trainee co mentor tot.'
  )
on conflict (case_number) do update
set title = excluded.title,
    prompt = excluded.prompt,
    expected_swot = excluded.expected_swot,
    suggested_plan = excluded.suggested_plan,
    updated_at = timezone('utc', now());

insert into public.teams (name, team_code, sort_key)
values
  ('Phong Ban 1', 'TEAM-01', 1),
  ('Phong Ban 2', 'TEAM-02', 2),
  ('Phong Ban 3', 'TEAM-03', 3),
  ('Phong Ban 4', 'TEAM-04', 4),
  ('Phong Ban 5', 'TEAM-05', 5),
  ('Phong Ban 6', 'TEAM-06', 6),
  ('Phong Ban 7', 'TEAM-07', 7),
  ('Phong Ban 8', 'TEAM-08', 8),
  ('Phong Ban 9', 'TEAM-09', 9)
on conflict (team_code) do update
set name = excluded.name,
    sort_key = excluded.sort_key,
    updated_at = timezone('utc', now());

update public.teams as teams
set round2_case_id = cases.id
from public.round2_cases as cases
where teams.sort_key = cases.case_number;

insert into public.round1_questions (question_number, prompt, answer_key, difficulty)
values
  (1, 'Quy trinh dinh vi ban than co may buoc? Ke ten?', '3 buoc: Xac dinh muc tieu -> SWOT -> Ke hoach hanh dong', 'de'),
  (2, 'Trong mo hinh ASK, kien thuc chiem 85% su thanh cong - Dung hay Sai?', 'Sai - Thai do va ky nang chiem 85%, kien thuc chi 15%', 'de-co-bay'),
  (3, 'Jeff Bezos noi: Thuong hieu cua ban la nhung gi ban noi ve chinh minh - Dung hay Sai?', 'Sai - thuong hieu la nhung gi nguoi khac noi ve ban khi ban khong co mat', 'trung-binh-co-bay'),
  (4, 'Trong SWOT ban than, yeu to nao thuoc moi truong ben ngoai?', 'Opportunities va Threats', 'trung-binh'),
  (5, 'Ke hoach hanh dong la buoc thu 2 trong quy trinh dinh vi ban than - Dung hay Sai?', 'Sai - day la buoc thu 3', 'kho-co-bay')
on conflict (question_number) do update
set prompt = excluded.prompt,
    answer_key = excluded.answer_key,
    difficulty = excluded.difficulty,
    updated_at = timezone('utc', now());

insert into public.admin_accounts (display_name, admin_code)
values ('Main Admin', 'ADMIN-UEH')
on conflict (admin_code) do update
set display_name = excluded.display_name,
    is_active = true,
    updated_at = timezone('utc', now());

insert into public.judge_accounts (display_name, judge_code, sort_order)
values
  ('Judge 1', 'JUDGE-01', 1),
  ('Judge 2', 'JUDGE-02', 2),
  ('Judge 3', 'JUDGE-03', 3)
on conflict (judge_code) do update
set display_name = excluded.display_name,
    sort_order = excluded.sort_order,
    is_active = true,
    updated_at = timezone('utc', now());

insert into public.game_state (
  singleton,
  phase,
  round_number,
  question_number,
  active_team_id,
  countdown_ends_at,
  is_submission_locked,
  projector_message
)
values (
  true,
  'lobby',
  1,
  1,
  null,
  null,
  false,
  'San sang cho Hanh Trinh Thuc Tap Sinh'
)
on conflict (singleton) do nothing;

select private.refresh_team_points();
select private.refresh_leaderboard();

revoke all on function public.require_admin(text) from public, anon, authenticated;
revoke all on function public.require_judge(text) from public, anon, authenticated;
revoke all on function public.require_team_session(text) from public, anon, authenticated;
revoke all on function public.log_admin_event(uuid, text, jsonb) from public, anon, authenticated;
revoke all on function public.refresh_team_points(uuid) from public, anon, authenticated;
revoke all on function public.refresh_leaderboard() from public, anon, authenticated;
revoke all on function public.get_public_leaderboard() from public, authenticated;
revoke all on function public.get_judge_submission_status(text) from public, authenticated;
revoke all on function public.join_team(text, text, text) from public, authenticated;
revoke all on function public.get_current_team_state(text) from public, authenticated;
revoke all on function public.submit_round1_answer(text, integer, integer, text) from public, authenticated;
revoke all on function public.get_active_presentation() from public, authenticated;
revoke all on function public.get_assigned_round2_case(text) from public, authenticated;
revoke all on function public.submit_judge_score(text, uuid, integer, integer, integer) from public, authenticated;
revoke all on function public.set_game_phase(text, public.game_phase, timestamptz, text) from public, authenticated;
revoke all on function public.mark_round1_results(text, integer, jsonb) from public, authenticated;
revoke all on function public.activate_round2_team(text, uuid) from public, authenticated;
revoke all on function public.publish_round2_result(text, uuid) from public, authenticated;
revoke all on function public.adjust_team_score(text, uuid, jsonb, text) from public, authenticated;
revoke all on function public.grant_bonus_points(text, uuid, integer, text) from public, authenticated;

grant execute on function public.get_public_leaderboard() to anon;
grant execute on function public.get_judge_submission_status(text) to anon;
grant execute on function public.join_team(text, text, text) to anon;
grant execute on function public.get_current_team_state(text) to anon;
grant execute on function public.submit_round1_answer(text, integer, integer, text) to anon;
grant execute on function public.get_active_presentation() to anon;
grant execute on function public.get_assigned_round2_case(text) to anon;
grant execute on function public.submit_judge_score(text, uuid, integer, integer, integer) to anon;
grant execute on function public.set_game_phase(text, public.game_phase, timestamptz, text) to anon;
grant execute on function public.mark_round1_results(text, integer, jsonb) to anon;
grant execute on function public.activate_round2_team(text, uuid) to anon;
grant execute on function public.publish_round2_result(text, uuid) to anon;
grant execute on function public.adjust_team_score(text, uuid, jsonb, text) to anon;
grant execute on function public.grant_bonus_points(text, uuid, integer, text) to anon;

revoke all on public.leaderboard_view from public, anon, authenticated;
revoke all on public.judge_submission_status_view from public, anon, authenticated;

commit;
