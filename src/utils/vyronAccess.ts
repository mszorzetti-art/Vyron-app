import { sha256Hex } from './vyronRules';

const ACCESS_HASH_SALT = 'vyron-access-v1:';

/**
 * Precomputed salted SHA-256 digest for the initial prototype demonstration gate.
 * Plaintext is never stored in localStorage or compared directly in runtime state.
 */
export const DEFAULT_DEMO_ACCESS_HASH =
  '5d54d0fc3f0bae1a86237ad40fef18177b4540a5666a1bd0c6a3717fbf4d578d';

export const DEFAULT_IDLE_TIMEOUT_MINUTES = 15;
export const DEFAULT_SESSION_MAX_HOURS = 12;
export const IDLE_TIMEOUT_OPTIONS: Array<{ value: number; label: string }> = [
  { value: 5, label: '5 minutos' },
  { value: 15, label: '15 minutos (Padrão)' },
  { value: 30, label: '30 minutos' },
  { value: 60, label: '60 minutos' },
  { value: 0, label: 'Desativado' },
];

export type LockReason = 'manual' | 'inactivity' | 'expired' | null;

export interface VyronAccessSession {
  authenticated: boolean;
  locked: boolean;
  lockReason: LockReason;
  unlockedAt: number | null;
  lastActivityAt: number | null;
  sessionExpiresAt: number | null;
  idleTimeoutMinutes: number;
  credentialHash: string;
  usingDefaultCredential: boolean;
}

export function createInitialAccessSession(
  overrides?: Partial<VyronAccessSession>
): VyronAccessSession {
  return {
    authenticated: false,
    locked: false,
    lockReason: null,
    unlockedAt: null,
    lastActivityAt: null,
    sessionExpiresAt: null,
    idleTimeoutMinutes: DEFAULT_IDLE_TIMEOUT_MINUTES,
    credentialHash: DEFAULT_DEMO_ACCESS_HASH,
    usingDefaultCredential: true,
    ...overrides,
  };
}

export function hashAccessCredential(password: string): string {
  return sha256Hex(`${ACCESS_HASH_SALT}${password}`);
}

export function verifyAccessCredential(password: string, storedHash: string): boolean {
  if (!password) return false;
  return hashAccessCredential(password) === storedHash;
}

export function shouldAutoLock(
  lastActivityAt: number | null,
  nowMs: number,
  idleTimeoutMinutes: number
): boolean {
  if (idleTimeoutMinutes <= 0 || lastActivityAt === null) return false;
  return nowMs - lastActivityAt >= idleTimeoutMinutes * 60_000;
}

export function evaluatePersistedSession(
  session: VyronAccessSession,
  nowMs = Date.now()
): VyronAccessSession {
  if (!session.authenticated) {
    return {
      ...session,
      authenticated: false,
      locked: false,
      lockReason: null,
    };
  }

  if (session.sessionExpiresAt !== null && nowMs >= session.sessionExpiresAt) {
    return {
      ...session,
      authenticated: false,
      locked: false,
      lockReason: 'expired',
      unlockedAt: null,
      lastActivityAt: null,
      sessionExpiresAt: null,
    };
  }

  if (!session.locked && shouldAutoLock(session.lastActivityAt, nowMs, session.idleTimeoutMinutes)) {
    return {
      ...session,
      locked: true,
      lockReason: 'inactivity',
    };
  }

  return session;
}

export function buildAuthenticatedSession(
  current: VyronAccessSession,
  nowMs = Date.now()
): VyronAccessSession {
  return {
    ...current,
    authenticated: true,
    locked: false,
    lockReason: null,
    unlockedAt: current.unlockedAt ?? nowMs,
    lastActivityAt: nowMs,
    sessionExpiresAt:
      current.sessionExpiresAt && current.sessionExpiresAt > nowMs
        ? current.sessionExpiresAt
        : nowMs + DEFAULT_SESSION_MAX_HOURS * 3_600_000,
  };
}
