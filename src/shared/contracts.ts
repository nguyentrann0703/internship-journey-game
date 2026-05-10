export type GamePhase =
  | "lobby"
  | "round1_question_open"
  | "round1_betting_locked"
  | "round1_reveal"
  | "round2_case_draw"
  | "round2_discussion"
  | "round2_presentation"
  | "bonus"
  | "results"
  | "paused";

export type UserRole = "team" | "judge" | "admin" | "public";

export type TeamStatus = "waiting" | "active" | "submitted" | "locked" | "offline";

export interface TeamResultInput {
  team_id: string;
  is_correct: boolean;
}

export interface ScorePatch {
  token_balance?: number;
  round2_points?: number;
  bonus_points?: number;
}

export interface PublicLeaderboardRow {
  id: string;
  name: string;
  sort_key: number;
  token_balance: number;
  round1_points: number;
  round2_points: number;
  bonus_points: number;
  total_points: number;
  display_rank: number;
  status: TeamStatus;
}

export interface JudgeSubmissionStatusRow {
  team_id: string;
  team_name: string;
  round2_case_id: string | null;
  judge_submission_count: number;
  submitted_by: string[] | null;
}

export interface ActivePresentationResponse {
  phase: GamePhase;
  active_team: null | {
    id: string;
    name: string;
    display_rank: number;
  };
  round2_case: null | {
    id: string;
    case_number: number;
    title: string;
    prompt: string;
  };
  judge_submission_count: number;
}

export interface AssignedRound2CaseResponse {
  team_id: string;
  team_name: string;
  case: {
    id: string;
    case_number: number;
    title: string;
    prompt: string;
  };
}

export interface Round1SubmissionResponse {
  id: string;
  team_id: string;
  question_number: number;
  bet_amount: number;
  answer_text: string;
  is_correct: boolean | null;
  token_delta: number;
}

export interface JudgeScoreSubmissionResponse {
  team_id: string;
  judge_count: number;
  average_score: number | null;
  final_score: number | null;
  is_finalized: boolean;
}

export interface Round2ResultResponse {
  team_id: string;
  round2_case_id: string;
  judge_count: number;
  average_score: number | null;
  final_score: number | null;
  is_finalized: boolean;
  is_published: boolean;
  finalized_at: string | null;
  published_at: string | null;
}

export interface TeamStateResponse {
  team: {
    id: string;
    name: string;
    token_balance: number;
    round1_points: number;
    round2_points: number;
    bonus_points: number;
    total_points: number;
    display_rank: number;
    status: TeamStatus;
    round2_case_id: string;
  };
  game_state: {
    phase: GamePhase;
    round_number: number;
    question_number: number | null;
    active_team_id: string | null;
    countdown_ends_at: string | null;
    projector_message: string | null;
    is_submission_locked: boolean;
  };
  latest_submission: null | {
    question_number: number;
    bet_amount: number;
    answer_text: string;
    is_correct: boolean | null;
  };
}

export interface GameBackendClient {
  joinTeam(teamCode: string, sessionToken: string, userAgent?: string): Promise<TeamStateResponse>;
  getCurrentTeamState(sessionToken: string): Promise<TeamStateResponse>;
  getPublicLeaderboard(): Promise<PublicLeaderboardRow[]>;
  submitRound1Answer(
    sessionToken: string,
    questionNumber: number,
    betAmount: number,
    answerText: string
  ): Promise<Round1SubmissionResponse>;
  getAssignedRound2Case(sessionToken: string): Promise<AssignedRound2CaseResponse>;
  getActivePresentation(): Promise<ActivePresentationResponse>;
  submitJudgeScore(
    judgeCode: string,
    teamId: string,
    scoreSwot: number,
    scoreLogic: number,
    scorePresentation: number
  ): Promise<JudgeScoreSubmissionResponse>;
  setGamePhase(
    adminCode: string,
    phase: GamePhase,
    countdownEndsAt?: string | null,
    projectorMessage?: string | null
  ): Promise<TeamStateResponse["game_state"]>;
  markRound1Results(
    adminCode: string,
    questionNumber: number,
    teamResults: TeamResultInput[]
  ): Promise<Array<{ team_id: string; token_balance: number; token_delta: number }>>;
  activateRound2Team(adminCode: string, teamId: string): Promise<ActivePresentationResponse>;
  getJudgeSubmissionStatus(adminCode: string): Promise<JudgeSubmissionStatusRow[]>;
  publishRound2Result(adminCode: string, teamId: string): Promise<Round2ResultResponse>;
  adjustTeamScore(
    adminCode: string,
    teamId: string,
    patch: ScorePatch,
    note?: string | null
  ): Promise<TeamStateResponse["team"]>;
  grantBonusPoints(
    adminCode: string,
    teamId: string,
    points?: number,
    note?: string | null
  ): Promise<TeamStateResponse["team"]>;
}
