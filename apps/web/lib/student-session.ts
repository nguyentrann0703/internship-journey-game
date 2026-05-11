const TEAM_CODE_STORAGE_KEY = "internship-journey.team-code";
const SESSION_TOKEN_STORAGE_KEY = "internship-journey.session-token";

export interface StoredTeamSession {
  teamCode: string;
  sessionToken: string;
}

export function createSessionToken() {
  return crypto.randomUUID();
}

export function readStoredTeamSession(): StoredTeamSession | null {
  if (typeof window === "undefined") {
    return null;
  }

  const teamCode = window.localStorage.getItem(TEAM_CODE_STORAGE_KEY);
  const sessionToken = window.localStorage.getItem(SESSION_TOKEN_STORAGE_KEY);

  if (!teamCode || !sessionToken) {
    return null;
  }

  return {
    teamCode,
    sessionToken
  };
}

export function writeStoredTeamSession(session: StoredTeamSession) {
  if (typeof window === "undefined") {
    return;
  }

  window.localStorage.setItem(TEAM_CODE_STORAGE_KEY, session.teamCode);
  window.localStorage.setItem(SESSION_TOKEN_STORAGE_KEY, session.sessionToken);
}

export function clearStoredTeamSession() {
  if (typeof window === "undefined") {
    return;
  }

  window.localStorage.removeItem(TEAM_CODE_STORAGE_KEY);
  window.localStorage.removeItem(SESSION_TOKEN_STORAGE_KEY);
}
