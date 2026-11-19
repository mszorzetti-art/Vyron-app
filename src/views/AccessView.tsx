import React, { useState } from 'react';
import { Eye, EyeOff, Lock } from 'lucide-react';
import { useVyronAccess } from '../context/VyronAccessContext';
import { useI18n } from '../i18n/useI18n';
import { VyronWordmark } from '../components/VyronBrand';

interface AccessViewProps {
  onSuccess: (options: { wasLocked: boolean }) => void;
}

export const AccessView: React.FC<AccessViewProps> = ({ onSuccess }) => {
  const { session, login } = useVyronAccess();
  const { t } = useI18n();
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');

  const lockNotice =
    session.locked && session.lockReason === 'inactivity'
      ? t('access.lockReason.inactivity')
      : session.locked && session.lockReason === 'manual'
      ? t('access.lockReason.manual')
      : session.lockReason === 'expired'
      ? t('access.lockReason.expired')
      : null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const res = login(password);
    if (!res.ok) {
      const msg = res.errorCode
        ? t(`access.error.${res.errorCode}`)
        : res.error ?? t('access.error.generic');
      setError(msg);
      return;
    }
    setPassword('');
    setError('');
    onSuccess({ wasLocked: res.wasLocked });
  };

  return (
    <div className="dark min-h-screen bg-[#101216] text-[#F1F2F3] flex flex-col items-center justify-center px-4 py-10">
      <main className="w-full max-w-[416px] space-y-5">
        <section
          aria-labelledby="vyron-access-title"
          className="bg-[#171A20] border border-[#AEB7C2]/15 rounded-xl p-7 sm:p-9 space-y-6"
        >
          {/* Brand Lockup */}
          <div className="space-y-5">
            <VyronWordmark markSize={28} />
            <div className="space-y-1.5">
              <h1
                id="vyron-access-title"
                className="font-display text-2xl font-semibold tracking-tight text-[#F1F2F3]"
              >
                {t('access.welcome')}
              </h1>
              <p className="text-sm text-[#AEB7C2]">{t('access.subtitle')}</p>
            </div>
          </div>

          {lockNotice && (
            <div
              role="status"
              className="flex items-center gap-2 px-3 py-2.5 rounded-md bg-[#292E36]/60 border border-[#AEB7C2]/15 text-xs text-[#AEB7C2]"
            >
              <Lock className="w-3.5 h-3.5 text-[#315FEA] shrink-0" aria-hidden="true" />
              <span>{lockNotice}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label
                htmlFor="vyron-access-password"
                className="block text-xs font-medium text-[#AEB7C2] mb-2"
              >
                {t('access.passwordLabel')}
              </label>
              <div className="relative">
                <input
                  id="vyron-access-password"
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  autoFocus
                  value={password}
                  onChange={(e) => {
                    setPassword(e.target.value);
                    if (error) setError('');
                  }}
                  placeholder={t('access.passwordPlaceholder')}
                  className="w-full h-11 pl-3.5 pr-11 text-sm rounded-md bg-[#101216] border border-[#AEB7C2]/20 text-[#F1F2F3] placeholder:text-[#687280] focus:outline-none focus:ring-2 focus:ring-[#315FEA] focus:border-transparent"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? t('access.hidePassword') : t('access.showPassword')}
                  aria-pressed={showPassword}
                  className="absolute right-1 top-1/2 -translate-y-1/2 w-9 h-9 inline-flex items-center justify-center rounded text-[#AEB7C2] hover:text-[#F1F2F3] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
                >
                  {showPassword ? (
                    <EyeOff className="w-4 h-4" aria-hidden="true" />
                  ) : (
                    <Eye className="w-4 h-4" aria-hidden="true" />
                  )}
                </button>
              </div>
              {error && (
                <p role="alert" className="mt-2 text-xs text-rose-400">
                  {error}
                </p>
              )}
            </div>

            <button
              type="submit"
              className="w-full h-11 px-5 rounded-md bg-[#315FEA] hover:bg-[#274FC9] text-white text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] focus-visible:ring-offset-2 focus-visible:ring-offset-[#171A20] whitespace-nowrap"
            >
              {t('access.submit')}
            </button>
          </form>

          <div className="pt-4 border-t border-[#AEB7C2]/12 flex items-center justify-between text-xs text-[#AEB7C2]">
            <span>{t('access.privateFooter')}</span>
            <span className="font-mono text-[11px] text-[#AEB7C2]/80">
              {session.idleTimeoutMinutes > 0
                ? t('access.autoLockLabel', { minutes: session.idleTimeoutMinutes })
                : t('access.manualLockLabel')}
            </span>
          </div>
        </section>

        <p className="text-center text-[11px] leading-relaxed text-[#7F8896] px-2">
          {t('access.demoDisclaimer')}
          {session.usingDefaultCredential && (
            <>
              {' '}
              {t('access.demoHint')} <span className="font-mono text-[#AEB7C2]">vyron2026</span>
            </>
          )}
        </p>
      </main>
    </div>
  );
};

