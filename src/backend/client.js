function createRpcInvoker({ supabaseUrl, anonKey, headers = {} }) {
  if (!supabaseUrl || !anonKey) {
    throw new Error("supabaseUrl and anonKey are required.");
  }

  return async function invoke(functionName, body) {
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/${functionName}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: anonKey,
        Authorization: `Bearer ${anonKey}`,
        ...headers
      },
      body: JSON.stringify(body ?? {})
    });

    if (!response.ok) {
      const message = await response.text();
      throw new Error(`${functionName} failed: ${message}`);
    }

    return response.json();
  };
}

export function createGameBackendClient(config) {
  const invoke = createRpcInvoker(config);

  return {
    joinTeam(teamCode, sessionToken, userAgent) {
      return invoke("join_team", {
        p_team_code: teamCode,
        p_session_token: sessionToken,
        p_user_agent: userAgent ?? null
      });
    },
    getCurrentTeamState(sessionToken) {
      return invoke("get_current_team_state", {
        p_session_token: sessionToken
      });
    },
    getPublicLeaderboard() {
      return invoke("get_public_leaderboard", {});
    },
    submitRound1Answer(sessionToken, questionNumber, betAmount, answerText) {
      return invoke("submit_round1_answer", {
        p_session_token: sessionToken,
        p_question_number: questionNumber,
        p_bet_amount: betAmount,
        p_answer_text: answerText
      });
    },
    getActivePresentation() {
      return invoke("get_active_presentation", {});
    },
    getAssignedRound2Case(sessionToken) {
      return invoke("get_assigned_round2_case", {
        p_session_token: sessionToken
      });
    },
    submitJudgeScore(judgeCode, teamId, scoreSwot, scoreLogic, scorePresentation) {
      return invoke("submit_judge_score", {
        p_judge_code: judgeCode,
        p_team_id: teamId,
        p_score_swot: scoreSwot,
        p_score_logic: scoreLogic,
        p_score_presentation: scorePresentation
      });
    },
    setGamePhase(adminCode, phase, countdownEndsAt, projectorMessage) {
      return invoke("set_game_phase", {
        p_admin_code: adminCode,
        p_phase: phase,
        p_countdown_ends_at: countdownEndsAt ?? null,
        p_projector_message: projectorMessage ?? null
      });
    },
    markRound1Results(adminCode, questionNumber, teamResults) {
      return invoke("mark_round1_results", {
        p_admin_code: adminCode,
        p_question_number: questionNumber,
        p_team_results: teamResults
      });
    },
    activateRound2Team(adminCode, teamId) {
      return invoke("activate_round2_team", {
        p_admin_code: adminCode,
        p_team_id: teamId
      });
    },
    getJudgeSubmissionStatus(adminCode) {
      return invoke("get_judge_submission_status", {
        p_admin_code: adminCode
      });
    },
    publishRound2Result(adminCode, teamId) {
      return invoke("publish_round2_result", {
        p_admin_code: adminCode,
        p_team_id: teamId
      });
    },
    adjustTeamScore(adminCode, teamId, patch, note) {
      return invoke("adjust_team_score", {
        p_admin_code: adminCode,
        p_team_id: teamId,
        p_patch: patch,
        p_note: note ?? null
      });
    },
    grantBonusPoints(adminCode, teamId, points = 2, note) {
      return invoke("grant_bonus_points", {
        p_admin_code: adminCode,
        p_team_id: teamId,
        p_points: points,
        p_note: note ?? null
      });
    }
  };
}
