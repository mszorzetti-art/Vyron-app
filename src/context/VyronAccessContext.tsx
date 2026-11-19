import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import {
  DEFAULT_DEMO_ACCESS_HASH,
  LockReason,
  VyronAccessSession,
  buildAuthenticatedSession,
  createInitialAccessSession,
  evaluatePersistedSession,
  hashAccessCredential,
  shouldAutoLock,
  verifyAccessCredential,
} from '../utils/vyronAccess';

export const ACCESS_STORAGE_KEY = 'vyron_access_session_v1';

export type AccessErrorCode =
  | 'emptyPassword'
  | 'wrongPassword'
  | 'currentWrong'
  | 'newTooShort';

interface VyronAccessContextValue {
  session: VyronAccessSession;
  isAuthorized: boolean;
  login: (password: string) => {
    ok: boolean;
    error?: string;
    errorCode?: AccessErrorCode;
    wasLocked: boolean;
  };
  lock: (reason?: Exclude<LockReason, null>) => void;
  logout: () => void;
  setIdleTimeoutMinutes: (minutes: number) => void;
  updateAccessPassword: (
    currentPassword: string,
    newPassword: string
  ) => { ok: boolean; error?: string; errorCode?: AccessErrorCode };
}

const VyronAccessContext = createContext<VyronAccessContextValue | null>(null);

function loadInitialAccessSession(): VyronAccessSession {
  try {
    const raw = localStorage.getItem(ACCESS_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw) as Partial<VyronAccessSession>;
      const hydrated = createInitialAccessSession({
        ...parsed,
        credentialHash:
          typeof parsed.credentialHash === 'string' && parsed.credentialHash.length === 64
            ? parsed.credentialHash
            : DEFAULT_DEMO_ACCESS_HASH,
      });
      return evaluatePersistedSession(hydrated, Date.now());
    }
  } catch {
    // Ignore invalid storage
  }
  return createInitialAccessSession();
}

export const VyronAccessProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [session, setSession] = useState<VyronAccessSession>(loadInitialAccessSession);
  const lastTouchRef = useRef<number>(Date.now());

  useEffect(() => {
    try {
      localStorage.setItem(ACCESS_STORAGE_KEY, JSON.stringify(session));
    } catch {
      // Ignore quota issues
    }
  }, [session]);

  const lock = useCallback((reason: Exclude<LockReason, null> = 'manual') => {
    setSession((prev) => {
      if (!prev.authenticated) return prev;
      return {
        ...prev,
        locked: true,
        lockReason: reason,
      };
    });
  }, []);

  const logout = useCallback(() => {
    setSession((prev) => ({
      ...prev,
      authenticated: false,
      locked: false,
      lockReason: null,
      unlockedAt: null,
      lastActivityAt: null,
      sessionExpiresAt: null,
    }));
  }, []);

  // Track owner activity when unlocked & enforce automatic inactivity lock
  useEffect(() => {
    if (!session.authenticated || session.locked) return;

    const recordActivity = () => {
      const now = Date.now();
      if (now - lastTouchRef.current < 10_000) return;
      lastTouchRef.current = now;
      setSession((prev) =>
        prev.authenticated && !prev.locked ? { ...prev, lastActivityAt: now } : prev
      );
    };

    const checkInactivity = () => {
      const now = Date.now();
      setSession((prev) => {
        if (!prev.authenticated || prev.locked) return prev;
        if (prev.sessionExpiresAt !== null && now >= prev.sessionExpiresAt) {
          return {
            ...prev,
            authenticated: false,
            locked: false,
            lockReason: 'expired',
            unlockedAt: null,
            lastActivityAt: null,
            sessionExpiresAt: null,
          };
        }
        if (shouldAutoLock(prev.lastActivityAt, now, prev.idleTimeoutMinutes)) {
          return {
            ...prev,
            locked: true,
            lockReason: 'inactivity',
          };
        }
        return prev;
      });
    };

    const handleVisibility = () => {
      if (document.visibilityState === 'visible') {
        checkInactivity();
      }
    };

    const events: Array<keyof WindowEventMap> = ['pointerdown', 'keydown', 'scroll'];
    events.forEach((ev) => window.addEventListener(ev, recordActivity, { passive: true }));
    document.addEventListener('visibilitychange', handleVisibility);
    const interval = window.setInterval(checkInactivity, 15_000);

    return () => {
      events.forEach((ev) => window.removeEventListener(ev, recordActivity));
      document.removeEventListener('visibilitychange', handleVisibility);
      window.clearInterval(interval);
    };
  }, [session.authenticated, session.locked, session.idleTimeoutMinutes]);

  const login: VyronAccessContextValue['login'] = (password) => {
    if (!password.trim()) {
      return {
        ok: false,
        error: 'Informe a senha de acesso para continuar.',
        errorCode: 'emptyPassword',
        wasLocked: session.locked,
      };
    }

    if (!verifyAccessCredential(password, session.credentialHash)) {
      return {
        ok: false,
        error: 'Senha incorreta. Verifique e tente novamente.',
        errorCode: 'wrongPassword',
        wasLocked: session.locked,
      };
    }

    const wasLocked = session.locked;
    const now = Date.now();
    lastTouchRef.current = now;
    setSession((prev) => buildAuthenticatedSession(prev, now));
    return { ok: true, wasLocked };
  };

  const setIdleTimeoutMinutes = (minutes: number) => {
    const safeMinutes = Math.max(0, Math.min(240, Math.round(minutes)));
    setSession((prev) => ({
      ...prev,
      idleTimeoutMinutes: safeMinutes,
      lastActivityAt: prev.authenticated && !prev.locked ? Date.now() : prev.lastActivityAt,
    }));
  };

  const updateAccessPassword: VyronAccessContextValue['updateAccessPassword'] = (
    currentPassword,
    newPassword
  ) => {
    if (!verifyAccessCredential(currentPassword, session.credentialHash)) {
      return {
        ok: false,
        error: 'A senha atual informada está incorreta.',
        errorCode: 'currentWrong',
      };
    }
    if (newPassword.trim().length < 6) {
      return {
        ok: false,
        error: 'Defina uma nova senha com pelo menos 6 caracteres.',
        errorCode: 'newTooShort',
      };
    }
    const nextHash = hashAccessCredential(newPassword);
    setSession((prev) => ({
      ...prev,
      credentialHash: nextHash,
      usingDefaultCredential: nextHash === DEFAULT_DEMO_ACCESS_HASH,
    }));
    return { ok: true };
  };

  const isAuthorized = session.authenticated && !session.locked;

  return (
    <VyronAccessContext.Provider
      value={{
        session,
        isAuthorized,
        login,
        lock,
        logout,
        setIdleTimeoutMinutes,
        updateAccessPassword,
      }}
    >
      {children}
    </VyronAccessContext.Provider>
  );
};

export function useVyronAccess(): VyronAccessContextValue {
  const ctx = useContext(VyronAccessContext);
  if (!ctx) {
    throw new Error('useVyronAccess must be used within VyronAccessProvider');
  }
  return ctx;
}
