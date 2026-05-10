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
    round2_case_id: string;
  };
  game_state: {
    phase: GamePhase;
    question_number: number | null;
    active_team_id: string | null;
    countdown_ends_at: string | null;
    projector_message: string | null;
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
  submitRound1Answer(
    sessionToken: string,
    questionNumber: number,
    betAmount: number,
    answerText: string
  ): Promise<unknown>;
  getAssignedRound2Case(sessionToken: string): Promise<unknown>;
  getActivePresentation(): Promise<unknown>;
  submitJudgeScore(
    judgeCode: string,
    teamId: string,
    scoreSwot: number,
    scoreLogic: number,
    scorePresentation: number
  ): Promise<unknown>;
  setGamePhase(
    adminCode: string,
    phase: GamePhase,
    countdownEndsAt?: string | null,
    projectorMessage?: string | null
  ): Promise<unknown>;
  markRound1Results(
    adminCode: string,
    questionNumber: number,
    teamResults: TeamResultInput[]
  ): Promise<unknown>;
  activateRound2Team(adminCode: string, teamId: string): Promise<unknown>;
  publishRound2Result(adminCode: string, teamId: string): Promise<unknown>;
  adjustTeamScore(
    adminCode: string,
    teamId: string,
    patch: ScorePatch,
    note?: string | null
  ): Promise<unknown>;
  grantBonusPoints(
    adminCode: string,
    teamId: string,
    points?: number,
    note?: string | null
  ): Promise<unknown>;
}
