export const ROUND_ONE_BUCKETS = [
  { minTokens: 18, points: 5 },
  { minTokens: 14, points: 4 },
  { minTokens: 9, points: 3 },
  { minTokens: 4, points: 2 },
  { minTokens: 0, points: 1 }
];

export const JUDGE_RUBRIC_LIMITS = {
  scoreSwot: 2,
  scoreLogic: 2,
  scorePresentation: 1
};

export function pointsForTokens(tokens) {
  const numericTokens = Number(tokens);

  if (!Number.isInteger(numericTokens) || numericTokens < 0) {
    throw new Error("Token balance must be a non-negative integer.");
  }

  return ROUND_ONE_BUCKETS.find((bucket) => numericTokens >= bucket.minTokens).points;
}

export function judgeTotalScore({ scoreSwot, scoreLogic, scorePresentation }) {
  const scores = {
    scoreSwot: Number(scoreSwot),
    scoreLogic: Number(scoreLogic),
    scorePresentation: Number(scorePresentation)
  };

  for (const [field, limit] of Object.entries(JUDGE_RUBRIC_LIMITS)) {
    if (!Number.isInteger(scores[field]) || scores[field] < 0 || scores[field] > limit) {
      throw new Error(`${field} must be an integer between 0 and ${limit}.`);
    }
  }

  return scores.scoreSwot + scores.scoreLogic + scores.scorePresentation;
}

export function finalizedRoundTwoScore(judgeTotals) {
  if (!Array.isArray(judgeTotals) || judgeTotals.length !== 3) {
    throw new Error("Exactly three judge totals are required.");
  }

  const normalizedTotals = judgeTotals.map((value) => {
    const numericValue = Number(value);

    if (!Number.isFinite(numericValue) || numericValue < 0 || numericValue > 5) {
      throw new Error("Judge totals must be numbers between 0 and 5.");
    }

    return numericValue;
  });

  const sum = normalizedTotals.reduce((accumulator, value) => accumulator + value, 0);

  return Math.floor(sum / normalizedTotals.length);
}

export function leaderboardRows(teams) {
  const sortedTeams = [...teams].sort((left, right) => {
    if (right.totalPoints !== left.totalPoints) {
      return right.totalPoints - left.totalPoints;
    }

    return left.sortKey - right.sortKey;
  });

  let previousPoints = null;
  let currentRank = 0;

  return sortedTeams.map((team, index) => {
    if (team.totalPoints !== previousPoints) {
      currentRank = index + 1;
      previousPoints = team.totalPoints;
    }

    return {
      ...team,
      displayRank: currentRank
    };
  });
}

