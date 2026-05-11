"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState, useTransition } from "react";

import type { TeamStateResponse } from "@game-shared/contracts";

import {
  getBackendErrorMessage,
  isInvalidTeamCodeError,
  isInvalidTeamSessionError
} from "@/lib/backend-errors";
import { getGameBackendClient } from "@/lib/game-backend";
import {
  clearStoredTeamSession,
  createSessionToken,
  readStoredTeamSession,
  writeStoredTeamSession
} from "@/lib/student-session";
import { playUiSound } from "@/lib/ui-sound";

const TEAM_CODE_HINT = "Use one of the seeded team codes: TEAM-01 to TEAM-09.";
const LOGIN_SOUND_SRC = "/assets/audio/login-confirm.ogg";
const SUBMIT_SOUND_SRC = "/assets/audio/submit-confirm.ogg";
const LIVE_REFRESH_INTERVAL_MS = 5000;

function isRound1Open(state: TeamStateResponse | null) {
  if (!state) {
    return false;
  }

  return (
    state.game_state.phase === "round1_question_open" && state.game_state.is_submission_locked === false
  );
}

function formatPhase(phase: TeamStateResponse["game_state"]["phase"]) {
  return phase.replaceAll("_", " ");
}

function formatCountdown(countdownEndsAt: string | null) {
  if (!countdownEndsAt) {
    return "No timer active";
  }

  return new Intl.DateTimeFormat("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit"
  }).format(new Date(countdownEndsAt));
}

function getCountdownRemainingMs(countdownEndsAt: string | null, nowMs: number) {
  if (!countdownEndsAt) {
    return null;
  }

  return Math.max(new Date(countdownEndsAt).getTime() - nowMs, 0);
}

function formatRemainingTime(remainingMs: number | null) {
  if (remainingMs === null) {
    return "No timer active";
  }

  const totalSeconds = Math.ceil(remainingMs / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;

  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

export default function StudentPage() {
  const [teamCode, setTeamCode] = useState("");
  const [betAmount, setBetAmount] = useState(1);
  const [answerText, setAnswerText] = useState("");
  const [state, setState] = useState<TeamStateResponse | null>(null);
  const [sessionToken, setSessionToken] = useState<string | null>(null);
  const [statusMessage, setStatusMessage] = useState(TEAM_CODE_HINT);
  const [sessionNotice, setSessionNotice] = useState<string | null>(null);
  const [nowMs, setNowMs] = useState(() => Date.now());
  const [isBooting, startBootTransition] = useTransition();
  const [isAuthenticating, startAuthTransition] = useTransition();
  const [isSubmitting, startSubmitTransition] = useTransition();

  function getBackend() {
    return getGameBackendClient();
  }

  useEffect(() => {
    const intervalId = window.setInterval(() => {
      setNowMs(Date.now());
    }, 1000);

    return () => window.clearInterval(intervalId);
  }, []);

  useEffect(() => {
    const storedSession = readStoredTeamSession();

    if (!storedSession) {
      return;
    }

    setTeamCode(storedSession.teamCode);
    setSessionToken(storedSession.sessionToken);
    setStatusMessage("Recovering previous team session...");

    startBootTransition(async () => {
      try {
        const backend = getBackend();
        const nextState = await backend.getCurrentTeamState(storedSession.sessionToken);
        setState(nextState);
        setSessionNotice(null);
        setStatusMessage("Session restored. Your team can continue from this device.");
      } catch (error) {
        if (isInvalidTeamSessionError(error)) {
          clearStoredTeamSession();
          setSessionToken(null);
          setState(null);
          setSessionNotice(
            "Phiên đăng nhập của đội đã được mở ở thiết bị khác. Vui lòng nhập lại team code để tiếp tục."
          );
          setStatusMessage(TEAM_CODE_HINT);
          return;
        }

        setStatusMessage(getBackendErrorMessage(error));
      }
    });
  }, []);

  useEffect(() => {
    if (!sessionToken) {
      return;
    }

    const intervalId = window.setInterval(() => {
      void refreshTeamState(sessionToken).catch(() => {});
    }, LIVE_REFRESH_INTERVAL_MS);

    return () => window.clearInterval(intervalId);
  }, [sessionToken]);

  function handleLogout() {
    clearStoredTeamSession();
    setSessionToken(null);
    setState(null);
    setAnswerText("");
    setSessionNotice("Session on this device was cleared.");
    setStatusMessage(TEAM_CODE_HINT);
  }

  function handleTeamSessionInvalid() {
    clearStoredTeamSession();
    setSessionToken(null);
    setState(null);
    setAnswerText("");
    setSessionNotice(
      "Phiên đăng nhập của đội đã được mở ở thiết bị khác. Vui lòng nhập lại team code để tiếp tục."
    );
    setStatusMessage(TEAM_CODE_HINT);
  }

  async function refreshTeamState(activeSessionToken: string) {
    try {
      const backend = getBackend();
      const nextState = await backend.getCurrentTeamState(activeSessionToken);
      setState(nextState);
      return nextState;
    } catch (error) {
      if (isInvalidTeamSessionError(error)) {
        handleTeamSessionInvalid();
        return null;
      }

      throw error;
    }
  }

  function handleJoinTeam(formData: FormData) {
    const rawCode = String(formData.get("teamCode") ?? "").trim().toUpperCase();

    if (!rawCode) {
      setStatusMessage("Please enter a team code.");
      return;
    }

    setStatusMessage("Connecting your team session...");
    setSessionNotice(null);

    startAuthTransition(async () => {
      const nextSessionToken = createSessionToken();

      try {
        const backend = getBackend();
        const nextState = await backend.joinTeam(
          rawCode,
          nextSessionToken,
          typeof navigator === "undefined" ? "unknown" : navigator.userAgent
        );

        writeStoredTeamSession({
          teamCode: rawCode,
          sessionToken: nextSessionToken
        });

        setTeamCode(rawCode);
        setSessionToken(nextSessionToken);
        setState(nextState);
        setAnswerText(nextState.latest_submission?.answer_text ?? "");
        setBetAmount(nextState.latest_submission?.bet_amount ?? 1);
        setStatusMessage("Team session is live. This device is now the active control point.");
        playUiSound(LOGIN_SOUND_SRC);
      } catch (error) {
        if (isInvalidTeamCodeError(error)) {
          setStatusMessage("Team code not found. Double-check the seeded code and try again.");
          return;
        }

        setStatusMessage(getBackendErrorMessage(error));
      }
    });
  }

  function handleSubmitRound1(formData: FormData) {
    if (!sessionToken || !state) {
      setStatusMessage("Please join a team before sending an answer.");
      return;
    }

    const currentQuestion = state.game_state.question_number;
    const submittedBet = Number(formData.get("betAmount"));
    const submittedAnswer = String(formData.get("answerText") ?? "").trim();

    if (!currentQuestion) {
      setStatusMessage("No active round 1 question is available right now.");
      return;
    }

    if (!submittedAnswer) {
      setStatusMessage("Please enter an answer before submitting.");
      return;
    }

    setStatusMessage("Sending round 1 answer to the game backend...");

    startSubmitTransition(async () => {
      try {
        const backend = getBackend();
        await backend.submitRound1Answer(sessionToken, currentQuestion, submittedBet, submittedAnswer);
        const nextState = await refreshTeamState(sessionToken);

        if (!nextState) {
          return;
        }

        setAnswerText(nextState.latest_submission?.answer_text ?? submittedAnswer);
        setBetAmount(nextState.latest_submission?.bet_amount ?? submittedBet);
        setStatusMessage("Answer submitted. Your latest round 1 payload is now locked on the server.");
        playUiSound(SUBMIT_SOUND_SRC);
      } catch (error) {
        if (isInvalidTeamSessionError(error)) {
          handleTeamSessionInvalid();
          return;
        }

        setStatusMessage(getBackendErrorMessage(error));
      }
    });
  }

  const latestSubmissionLabel = state?.latest_submission
    ? `Q${state.latest_submission.question_number} • Bet ${state.latest_submission.bet_amount}`
    : "No round 1 submission yet";

  const teamStatusTone = state?.team.status === "submitted" ? "good" : "neutral";
  const countdownRemainingMs = getCountdownRemainingMs(state?.game_state.countdown_ends_at ?? null, nowMs);
  const isCountdownExpired = countdownRemainingMs === 0 && state?.game_state.countdown_ends_at !== null;
  const canSubmit = isRound1Open(state) && !isCountdownExpired;
  const activeQuestion = state?.game_state.question_number ?? 1;
  const lockStateLabel = canSubmit
    ? "Live and accepting answers"
    : state?.game_state.is_submission_locked || isCountdownExpired
      ? "Submission locked"
      : "Waiting for round 1 open";
  const lockStateTone = canSubmit ? "good" : "danger";

  return (
    <main className="shell shell-student">
      <section className="student-hero">
        <div className="hero-copy student-hero-copy">
          <p className="eyebrow">Student Console</p>
          <h1>One calm team control screen for login, recovery, and round 1 decisions.</h1>
          <p className="summary">
            This surface keeps the play flow readable on phones and laptops: single-session team
            access, instant session restore, and one focused answer form when round 1 opens.
          </p>
          <div className="chip-row">
            <span className="chip">Single active session</span>
            <span className="chip">Local recovery</span>
            <span className="chip">Round 1 ready</span>
          </div>
        </div>

        <div className="status-card">
          <p className="status-label">Session status</p>
          <div className="status-grid">
            <div>
              <span className="status-key">Stored team code</span>
              <strong>{teamCode || "None yet"}</strong>
            </div>
            <div>
              <span className="status-key">Active session token</span>
              <strong>{sessionToken ? "Present on this device" : "Not created"}</strong>
            </div>
          </div>
          <p className="status-note">{statusMessage}</p>
          {sessionNotice ? <p className="callout warning">{sessionNotice}</p> : null}
          <div className="inline-links">
            <Link href="/">Back to app overview</Link>
          </div>
        </div>
      </section>

      <section className="student-grid">
        <article className="panel control-panel">
          <div className="section-heading">
            <div>
              <p className="section-kicker">Team access</p>
              <h2>Join with your team code</h2>
            </div>
            {state ? (
              <button className="ghost-button" type="button" onClick={handleLogout}>
                Clear this device
              </button>
            ) : null}
          </div>

          <form action={handleJoinTeam} className="stack-form">
            <label className="field">
              <span>Team code</span>
              <input
                autoComplete="off"
                defaultValue={teamCode}
                name="teamCode"
                onChange={(event) => setTeamCode(event.target.value.toUpperCase())}
                placeholder="TEAM-01"
                type="text"
              />
            </label>
            <p className="field-hint">{TEAM_CODE_HINT}</p>
            <button className="primary-button" disabled={isAuthenticating || isBooting} type="submit">
              {isAuthenticating ? "Connecting..." : "Join team"}
            </button>
          </form>
        </article>

        <article className="panel scoreboard-panel">
          <div className="section-heading">
            <div>
              <p className="section-kicker">Team state</p>
              <h2>{state?.team.name ?? "Waiting for login"}</h2>
            </div>
            <span className={`pill ${teamStatusTone}`}>{state?.team.status ?? "offline"}</span>
          </div>

          {state ? (
            <>
              <div className="stat-grid">
                <div className="stat-tile">
                  <span>Tokens</span>
                  <strong>{state.team.token_balance}</strong>
                </div>
                <div className="stat-tile">
                  <span>Round 1 points</span>
                  <strong>{state.team.round1_points}</strong>
                </div>
                <div className="stat-tile">
                  <span>Total points</span>
                  <strong>{state.team.total_points}</strong>
                </div>
                <div className="stat-tile">
                  <span>Rank</span>
                  <strong>#{state.team.display_rank}</strong>
                </div>
              </div>

              <div className="meta-strip">
                <div>
                  <span className="status-key">Phase</span>
                  <strong>{formatPhase(state.game_state.phase)}</strong>
                </div>
                <div>
                  <span className="status-key">Question</span>
                  <strong>{state.game_state.question_number ?? "Pending"}</strong>
                </div>
                <div>
                  <span className="status-key">Timer</span>
                  <strong>{formatCountdown(state.game_state.countdown_ends_at)}</strong>
                </div>
              </div>

              <div className="live-lock-card">
                <div className="section-heading section-heading-compact">
                  <div>
                    <p className="section-kicker">Live lock state</p>
                    <h3>{formatRemainingTime(countdownRemainingMs)}</h3>
                  </div>
                  <span className={`pill ${lockStateTone}`}>{lockStateLabel}</span>
                </div>
                <div className="timer-track" aria-hidden="true">
                  <div
                    className={`timer-fill ${canSubmit ? "open" : "closed"}`}
                    style={{
                      width:
                        countdownRemainingMs === null
                          ? "18%"
                          : `${Math.min(Math.max((countdownRemainingMs / 60000) * 100, 6), 100)}%`
                    }}
                  />
                </div>
                <p className="field-hint">
                  This screen refreshes the server state every {LIVE_REFRESH_INTERVAL_MS / 1000} seconds and
                  also treats an expired countdown as locally locked.
                </p>
              </div>

              <div className="latest-card">
                <div>
                  <p className="section-kicker">Latest payload</p>
                  <h3>{latestSubmissionLabel}</h3>
                </div>
                <p>{state.latest_submission?.answer_text ?? "Your latest answer will appear here."}</p>
              </div>
            </>
          ) : (
            <p className="empty-copy">
              No active team session yet. Join with a seeded team code to pull the live game state.
            </p>
          )}
        </article>
      </section>

      <section className="student-grid student-grid-bottom">
        <article className="panel control-panel">
          <div className="section-heading">
            <div>
              <p className="section-kicker">Round 1 action</p>
              <h2>Submit the current answer</h2>
            </div>
            <span className={`pill ${canSubmit ? "good" : "neutral"}`}>
              {canSubmit ? "Open now" : "Locked"}
            </span>
          </div>

          <form action={handleSubmitRound1} className="stack-form">
            <div className="field-row">
              <label className="field">
                <span>Question</span>
                <input disabled value={`Q${activeQuestion}`} />
              </label>
              <label className="field">
                <span>Bet</span>
                <select
                  name="betAmount"
                  onChange={(event) => setBetAmount(Number(event.target.value))}
                  value={betAmount}
                >
                  {[1, 2, 3, 4, 5].map((value) => (
                    <option key={value} value={value}>
                      {value} token{value > 1 ? "s" : ""}
                    </option>
                  ))}
                </select>
              </label>
            </div>

            <label className="field">
              <span>Answer</span>
              <textarea
                name="answerText"
                onChange={(event) => setAnswerText(event.target.value)}
                placeholder="Type your round 1 answer here"
                rows={5}
                value={answerText}
              />
            </label>

            <div className="field-hint field-hint-strong">
              Submission is only accepted when the phase is <code>round1_question_open</code> and
              the server has not locked the timer.
            </div>

            <button
              className="primary-button"
              disabled={!canSubmit || isSubmitting || isBooting || !state}
              type="submit"
            >
              {isSubmitting ? "Submitting..." : "Submit round 1 answer"}
            </button>
          </form>

          <div className="inline-links inline-links-secondary">
            <button
              className="ghost-button"
              disabled={!sessionToken || isBooting}
              onClick={() => {
                if (!sessionToken) {
                  return;
                }

                setStatusMessage("Refreshing live team state...");
                void refreshTeamState(sessionToken)
                  .then((nextState) => {
                    if (!nextState) {
                      return;
                    }

                    setStatusMessage("Live team state refreshed from the server.");
                  })
                  .catch((error) => {
                    setStatusMessage(getBackendErrorMessage(error));
                  });
              }}
              type="button"
            >
              Refresh live state
            </button>
          </div>
        </article>

        <article className="panel scene-panel">
          <div className="section-heading">
            <div>
              <p className="section-kicker">Field mood</p>
              <h2>Intern office briefing</h2>
            </div>
            <span className="pill neutral">Pixel scene</span>
          </div>

          <div className="scene-frame">
            <Image
              alt="Pixel office scene used as the student console atmosphere card."
              className="scene-image"
              height={256}
              priority
              src="/assets/scene/pixel-office.png"
              width={256}
            />
          </div>

          <div className="callout soft">
            One agreed device should control the team during live play. If another device logs in
            with the same team code, this screen will be asked to re-enter the code on the next
            refresh or submit.
          </div>

          <div className="tip-list">
            <div>
              <span className="status-key">Login cue</span>
              <strong>TEAM-01 to TEAM-09</strong>
            </div>
            <div>
              <span className="status-key">Submit cue</span>
              <strong>Audio feedback enabled</strong>
            </div>
            <div>
              <span className="status-key">Art source</span>
              <strong>PixelOffice + Monogram</strong>
            </div>
          </div>
        </article>
      </section>
    </main>
  );
}
