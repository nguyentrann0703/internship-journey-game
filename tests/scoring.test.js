import test from "node:test";
import assert from "node:assert/strict";

import {
  finalizedRoundTwoScore,
  judgeTotalScore,
  leaderboardRows,
  pointsForTokens
} from "../src/backend/scoring.js";

test("pointsForTokens maps round one buckets correctly", () => {
  assert.equal(pointsForTokens(18), 5);
  assert.equal(pointsForTokens(14), 4);
  assert.equal(pointsForTokens(9), 3);
  assert.equal(pointsForTokens(4), 2);
  assert.equal(pointsForTokens(0), 1);
});

test("judgeTotalScore validates rubric bounds", () => {
  assert.equal(
    judgeTotalScore({
      scoreSwot: 2,
      scoreLogic: 1,
      scorePresentation: 1
    }),
    4
  );

  assert.throws(
    () =>
      judgeTotalScore({
        scoreSwot: 3,
        scoreLogic: 1,
        scorePresentation: 1
      }),
    /scoreSwot/
  );
});

test("finalizedRoundTwoScore floors the judge average", () => {
  assert.equal(finalizedRoundTwoScore([5, 4, 4]), 4);
  assert.equal(finalizedRoundTwoScore([5, 5, 4]), 4);
});

test("leaderboardRows preserves shared ranks and stable order", () => {
  const rows = leaderboardRows([
    { name: "Team 3", totalPoints: 7, sortKey: 3 },
    { name: "Team 1", totalPoints: 10, sortKey: 1 },
    { name: "Team 2", totalPoints: 10, sortKey: 2 }
  ]);

  assert.deepEqual(
    rows.map((row) => ({
      name: row.name,
      displayRank: row.displayRank
    })),
    [
      { name: "Team 1", displayRank: 1 },
      { name: "Team 2", displayRank: 1 },
      { name: "Team 3", displayRank: 3 }
    ]
  );
});

