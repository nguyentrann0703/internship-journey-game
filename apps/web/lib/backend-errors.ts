const INVALID_TEAM_SESSION_MESSAGE = "Invalid team session.";
const INVALID_TEAM_CODE_MESSAGE = "Invalid team code.";

export function getBackendErrorMessage(error: unknown) {
  if (error instanceof Error) {
    return error.message;
  }

  return "Unexpected error. Please try again.";
}

export function isInvalidTeamSessionError(error: unknown) {
  return getBackendErrorMessage(error).includes(INVALID_TEAM_SESSION_MESSAGE);
}

export function isInvalidTeamCodeError(error: unknown) {
  return getBackendErrorMessage(error).includes(INVALID_TEAM_CODE_MESSAGE);
}
