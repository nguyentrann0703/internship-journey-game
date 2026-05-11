import Link from "next/link";

import { getPublicEnv } from "@/lib/env";

const interfaceSurfaces = [
  {
    title: "Student Flow",
    detail: "Team login, session restore, and round 1 answer submission."
  },
  {
    title: "Admin Flow",
    detail: "Phase control, result marking, round 2 activation, and score publication."
  },
  {
    title: "Public Flow",
    detail: "Projector-safe leaderboard and active presentation overlays."
  }
];

export default function HomePage() {
  const env = getPublicEnv();

  return (
    <main className="shell">
      <section className="hero">
        <div className="hero-copy">
          <p className="eyebrow">Internship Journey Control Surface</p>
          <h1>Next.js frontend shell is ready for Supabase-backed game flows.</h1>
          <p className="summary">
            This app is set up as a DOM-first game interface layer: low chrome, projector-aware,
            and ready to wrap the backend RPC surface without leaking raw integration details into
            individual pages.
          </p>
          <div className="chip-row">
            <span className="chip">App Router</span>
            <span className="chip">Supabase RPC wrapper</span>
            <span className="chip">Shared contracts</span>
          </div>
        </div>

        <div className="status-card">
          <p className="status-label">Environment readiness</p>
          <div className="status-grid">
            <div>
              <span className="status-key">Supabase URL</span>
              <strong>{env.supabaseUrl ? "Configured" : "Missing"}</strong>
            </div>
            <div>
              <span className="status-key">Anon key</span>
              <strong>{env.supabaseAnonKey ? "Configured" : "Missing"}</strong>
            </div>
          </div>
          <p className="status-note">
            Put your values in <code>apps/web/.env.local</code> using the keys from{" "}
            <code>.env.example</code>.
          </p>
        </div>
      </section>

      <section className="panel-grid">
        {interfaceSurfaces.map((surface) => (
          <article className="panel" key={surface.title}>
            <h2>{surface.title}</h2>
            <p>{surface.detail}</p>
          </article>
        ))}
      </section>

      <section className="panel-grid panel-grid-links">
        <Link className="panel panel-link" href="/student">
          <h2>Open Student Console</h2>
          <p>Team login, session recovery, and round 1 submission are ready to wire against live RPCs.</p>
        </Link>
        <Link className="panel panel-link" href="/leaderboard">
          <h2>Open Leaderboard View</h2>
          <p>Projector-safe standings with auto refresh, large type, and stable rank presentation.</p>
        </Link>
      </section>
    </main>
  );
}
