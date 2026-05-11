# Web App

Next.js frontend shell for the live game.

## Required env

Copy `.env.example` to `.env.local` and set:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## Commands

- `npm install`
- `npm run dev`
- `npm run build`

## Integration boundary

- `apps/web/lib/game-backend.ts` wraps the shared backend client in `src/backend/client.js`
- `src/shared/contracts.ts` is the source of truth for RPC shapes and shared types
