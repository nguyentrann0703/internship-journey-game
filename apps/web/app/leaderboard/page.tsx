"use client";

import Link from "next/link";
import { useEffect, useState, useTransition } from "react";

import type { PublicLeaderboardRow } from "@game-shared/contracts";

import { getBackendErrorMessage } from "@/lib/backend-errors";
import { getGameBackendClient } from "@/lib/game-backend";

const LEADERBOARD_REFRESH_INTERVAL_MS = 5000;

function getStatusTone(status: PublicLeaderboardRow["status"]) {
  switch (status) {
    case "active":
    case "submitted":
      return "good";
    case "locked":
      return "danger";
    default:
      return "neutral";
  }
}

function formatRefreshTime(date: Date | null) {
  if (!date) {
    return "Not synced yet";
  }

  return new Intl.DateTimeFormat("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit"
  }).format(date);
}

export default function LeaderboardPage() {
  const [rows, setRows] = useState<PublicLeaderboardRow[]>([]);
  const [statusMessage, setStatusMessage] = useState("Connecting to the public leaderboard...");
  const [lastUpdatedAt, setLastUpdatedAt] = useState<Date | null>(null);
  const [isRefreshing, startRefreshTransition] = useTransition();

  function getBackend() {
    return getGameBackendClient();
  }

  useEffect(() => {
    async function refreshLeaderboard() {
      try {
        const backend = getBackend();
        const nextRows = await backend.getPublicLeaderboard();
        setRows(nextRows);
        setLastUpdatedAt(new Date());
        setStatusMessage(
          nextRows.length > 0
            ? "Leaderboard synced from the live Supabase game state."
            : "No leaderboard rows available yet."
        );
      } catch (error) {
        setStatusMessage(getBackendErrorMessage(error));
      }
    }

    startRefreshTransition(() => {
      void refreshLeaderboard();
    });

    const intervalId = window.setInterval(() => {
      void refreshLeaderboard();
    }, LEADERBOARD_REFRESH_INTERVAL_MS);

    return () => window.clearInterval(intervalId);
  }, []);

  const podiumRows = rows.slice(0, 3);

  return (
    <main className="shell shell-leaderboard">
      <section className="leaderboard-hero">
        <div className="hero-copy leaderboard-hero-copy">
          <p className="eyebrow">Projector View</p>
          <h1>Live leaderboard for the internship survival game.</h1>
          <p className="summary">
            Big rank hierarchy, quick score scanning, and automatic refresh every{" "}
            {LEADERBOARD_REFRESH_INTERVAL_MS / 1000} seconds so this screen can stay on the room
            display without extra operator chrome.
          </p>
          <div className="chip-row">
            <span className="chip">Projector-safe</span>
            <span className="chip">Large type</span>
            <span className="chip">Auto refresh</span>
          </div>
        </div>

        <div className="status-card">
          <p className="status-label">Public sync state</p>
          <div className="status-grid">
            <div>
              <span className="status-key">Rows loaded</span>
              <strong>{rows.length}</strong>
            </div>
            <div>
              <span className="status-key">Last refresh</span>
              <strong>{formatRefreshTime(lastUpdatedAt)}</strong>
            </div>
          </div>
          <p className="status-note">{statusMessage}</p>
          <div className="inline-links">
            <Link href="/">Back to app overview</Link>
            <Link href="/student">Open team console</Link>
          </div>
        </div>
      </section>

      <section className="leaderboard-stage">
        <article className="panel leaderboard-podium">
          <div className="section-heading">
            <div>
              <p className="section-kicker">Top performers</p>
              <h2>Current podium</h2>
            </div>
            <button
              className="ghost-button"
              disabled={isRefreshing}
              onClick={() => {
                setStatusMessage("Refreshing leaderboard from the server...");
                startRefreshTransition(async () => {
                  try {
                    const backend = getBackend();
                    const nextRows = await backend.getPublicLeaderboard();
                    setRows(nextRows);
                    setLastUpdatedAt(new Date());
                    setStatusMessage("Leaderboard refreshed manually.");
                  } catch (error) {
                    setStatusMessage(getBackendErrorMessage(error));
                  }
                });
              }}
              type="button"
            >
              {isRefreshing ? "Refreshing..." : "Refresh now"}
            </button>
          </div>

          <div className="podium-grid">
            {podiumRows.map((row, index) => (
              <article className={`podium-card podium-card-${index + 1}`} key={row.id}>
                <p className="podium-label">Rank #{row.display_rank}</p>
                <h3>{row.name}</h3>
                <strong>{row.total_points}</strong>
                <span>Total points</span>
                <div className="podium-meta">
                  <span>R1 {row.round1_points}</span>
                  <span>R2 {row.round2_points}</span>
                  <span>Bonus {row.bonus_points}</span>
                </div>
              </article>
            ))}

            {podiumRows.length === 0 ? (
              <div className="empty-board">The leaderboard is waiting for the first live game data.</div>
            ) : null}
          </div>
        </article>

        <article className="panel leaderboard-table-panel">
          <div className="section-heading">
            <div>
              <p className="section-kicker">Full standings</p>
              <h2>All nine teams</h2>
            </div>
            <span className="pill neutral">Stable shared ranks</span>
          </div>

          <div className="leaderboard-table">
            <div className="leaderboard-table-header">
              <span>Rank</span>
              <span>Team</span>
              <span>Total</span>
              <span>Tokens</span>
              <span>R1</span>
              <span>R2</span>
              <span>Bonus</span>
              <span>Status</span>
            </div>

            {rows.map((row) => (
              <article className="leaderboard-row" key={row.id}>
                <strong className="leaderboard-rank">#{row.display_rank}</strong>
                <div className="leaderboard-team">
                  <h3>{row.name}</h3>
                  <p>Seed order {row.sort_key}</p>
                </div>
                <strong className="leaderboard-total">{row.total_points}</strong>
                <span>{row.token_balance}</span>
                <span>{row.round1_points}</span>
                <span>{row.round2_points}</span>
                <span>{row.bonus_points}</span>
                <span className={`pill ${getStatusTone(row.status)}`}>{row.status}</span>
              </article>
            ))}
          </div>

          {rows.length > 0 ? (
            <div className="callout soft">
              Shared scores keep the same displayed rank, while the stable order still follows the
              seeded team order from the backend.
            </div>
          ) : null}
        </article>
      </section>
    </main>
  );
}
