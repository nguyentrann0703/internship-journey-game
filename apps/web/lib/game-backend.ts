import { createGameBackendClient } from "@game-backend/client.js";
import type { GameBackendClient } from "@game-shared/contracts";

import { assertPublicEnv } from "@/lib/env";

let backendClient: GameBackendClient | null = null;

export function getGameBackendClient(): GameBackendClient {
  if (backendClient) {
    return backendClient;
  }

  const env = assertPublicEnv();

  backendClient = createGameBackendClient({
    supabaseUrl: env.supabaseUrl,
    anonKey: env.supabaseAnonKey
  }) as GameBackendClient;

  return backendClient;
}
