import React, { useState } from 'react';
import { Lock, LogOut, OctagonAlert, RefreshCw, RotateCcw } from 'lucide-react';
import { useVyronAccess } from '../context/VyronAccessContext';
import { useVyron } from '../context/VyronContext';
import { CurrencyCode, ThemeMode } from '../types/vyron';
import { IDLE_TIMEOUT_OPTIONS } from '../utils/vyronAccess';
import { canResumeSystemControl } from '../utils/vyronRules';
import { useI18n } from '../i18n/useI18n';
import {
  labelIntegrationConfigStatus,
  labelRiskStatus,
  labelSystemControlState,
} from '../i18n/domainLabels';
import { localizeIntegration, localizeRisk } from '../i18n/seedTranslations';
import {
  PageHeader,
  SegmentedControl,
  StatusLabel,
  SurfacePanel,
} from '../components/ui';

export const SettingsView: React.FC = () => {
  const {
    state,
    setTheme,
    setBaseCurrency,
    updateSettings,
    toggleSystemFlags,
    haltSystemControl,
    resumeSystemControl,
    reconcileJobsDemo,
    resetDemoData,
  } = useVyron();
  const {
    session,
    lock,
    logout,
    setIdleTimeoutMinutes,
    updateAccessPassword,
  } = useVyronAccess();
  const { lang, t } = useI18n();

  const [controlFeedback, setControlFeedback] = useState<{
    ok: boolean;
    message: string;
  } | null>(null);
  const [currentPwd, setCurrentPwd] = useState('');
  const [newPwd, setNewPwd] = useState('');
  const [pwdFeedback, setPwdFeedback] = useState<{
    ok: boolean;
    message: string;
  } | null>(null);

  const s = state.settings;
  const isHalted = state.systemControl.state === 'HALTED';
  const resumeGate = canResumeSystemControl(state.jobRuns, lang);

  const architectureBlocks = [
    {
      group: t('settings.arch.grp1Title'),
      statusKey: 'Active',
      statusLabel: lang === 'EN-US' ? 'Active' : 'Ativo',
      items: [t('settings.arch.grp1Item1'), t('settings.arch.grp1Item2')],
    },
    {
      group: t('settings.arch.grp2Title'),
      statusKey: 'In Review',
      statusLabel: lang === 'EN-US' ? 'In Integration' : 'Em integração',
      items: [t('settings.arch.grp2Item1'), t('settings.arch.grp2Item2')],
    },
    {
      group: t('settings.arch.grp3Title'),
      statusKey: 'Draft',
      statusLabel: lang === 'EN-US' ? 'Planned' : 'Planejado',
      items: [t('settings.arch.grp3Item1'), t('settings.arch.grp3Item2')],
    },
  ];

  const handleHalt = () => {
    const count = haltSystemControl(s.ownerName, t('settings.haltReason'));
    setControlFeedback({
      ok: true,
      message: t('settings.haltFeedback', { count }),
    });
  };

  const handleResume = () => {
    const res = resumeSystemControl(s.ownerName, t('settings.resumeReason'));
    if (!res.ok) {
      setControlFeedback({
        ok: false,
        message: res.reason ?? t('settings.resumeBlockedFallback'),
      });
      return;
    }
    setControlFeedback({
      ok: true,
      message: t('settings.resumeFeedback'),
    });
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('settings.title')}
        subtitle={t('settings.subtitle')}
        actions={
          <button
            type="button"
            onClick={resetDemoData}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-medium rounded-md border border-black/15 dark:border-white/15 hover:border-[#315FEA] whitespace-nowrap"
          >
            <RotateCcw className="w-3.5 h-3.5" aria-hidden="true" />
            <span>{t('settings.resetDemo')}</span>
          </button>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Owner Profile & Preferences */}
        <SurfacePanel className="lg:col-span-6 space-y-5">
          <h2 className="font-display text-sm font-semibold">{t('settings.profileTitle')}</h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
            <div>
              <label htmlFor="owner-name" className="block font-medium mb-1">
                {t('settings.ownerNameLabel')}
              </label>
              <input
                id="owner-name"
                value={s.ownerName}
                onChange={(e) => updateSettings({ ownerName: e.target.value })}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div>
              <label htmlFor="owner-email" className="block font-medium mb-1">
                {t('settings.ownerEmailLabel')}
              </label>
              <input
                id="owner-email"
                value={s.ownerEmail}
                onChange={(e) => updateSettings({ ownerEmail: e.target.value })}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
          </div>

          <div className="space-y-3 text-xs pt-2 border-t border-black/10 dark:border-white/10">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <div className="font-medium">{t('settings.themeLabel')}</div>
                <div className="text-[#525B68] dark:text-[#AEB7C2]">{t('settings.themeDesc')}</div>
              </div>
              <SegmentedControl
                ariaLabel={t('settings.themeAria')}
                value={s.theme}
                onChange={(th) => setTheme(th as ThemeMode)}
                options={[
                  { value: 'dark', label: t('settings.themeDark') },
                  { value: 'light', label: t('settings.themeLight') },
                ]}
              />
            </div>

            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <div className="font-medium">{t('settings.currencyLabel')}</div>
                <div className="text-[#525B68] dark:text-[#AEB7C2]">
                  {t('settings.currencyDesc')}
                </div>
              </div>
              <SegmentedControl
                ariaLabel={t('settings.currencyAria')}
                value={s.baseCurrency}
                onChange={(c) => setBaseCurrency(c as CurrencyCode)}
                options={[
                  { value: 'BRL', label: 'BRL' },
                  { value: 'USD', label: 'USD' },
                  { value: 'EUR', label: 'EUR' },
                ]}
              />
            </div>

            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <div className="font-medium">{t('settings.languageLabel')}</div>
                <div className="text-[#525B68] dark:text-[#AEB7C2]">
                  {t('settings.languageDesc')}
                </div>
              </div>
              <SegmentedControl
                ariaLabel={t('settings.languageAria')}
                value={s.uiLanguage}
                onChange={(l) => updateSettings({ uiLanguage: l as 'PT-BR' | 'EN-US' })}
                options={[
                  { value: 'PT-BR', label: 'PT-BR' },
                  { value: 'EN-US', label: 'EN-US' },
                ]}
              />
            </div>
          </div>
        </SurfacePanel>

        {/* Autonomy Policies, Publishing Switches, Validity Windows & Security Stop All */}
        <SurfacePanel className="lg:col-span-6 space-y-5">
          <h2 className="font-display text-sm font-semibold">{t('settings.policiesTitle')}</h2>

          <div className="space-y-2.5 text-xs">
            <label className="flex items-center justify-between gap-3 p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <span>
                <span className="font-medium block">{t('settings.publishingLabel')}</span>
                <span className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('settings.publishingDesc')}
                </span>
              </span>
              <input
                type="checkbox"
                checked={state.systemControl.publishingEnabled}
                onChange={(e) => toggleSystemFlags({ publishingEnabled: e.target.checked })}
                className="accent-[#315FEA]"
              />
            </label>

            <label className="flex items-center justify-between gap-3 p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <span>
                <span className="font-medium block">{t('settings.publicAllowedLabel')}</span>
                <span className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('settings.publicAllowedDesc')}
                </span>
              </span>
              <input
                type="checkbox"
                checked={state.systemControl.phaseBPublicAllowed}
                onChange={(e) => toggleSystemFlags({ phaseBPublicAllowed: e.target.checked })}
                className="accent-[#315FEA]"
              />
            </label>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-1">
              <div>
                <label htmlFor="auth-validity-hours" className="block font-medium mb-1">
                  {t('settings.authValidityLabel')}
                </label>
                <input
                  id="auth-validity-hours"
                  type="number"
                  min={1}
                  max={720}
                  value={s.defaultAuthValidityHours}
                  onChange={(e) =>
                    updateSettings({
                      defaultAuthValidityHours: Math.max(1, Number(e.target.value) || 24),
                    })
                  }
                  className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                />
              </div>

              <div>
                <label htmlFor="evidence-freshness-hours" className="block font-medium mb-1">
                  {t('settings.evidenceFreshnessLabel')}
                </label>
                <input
                  id="evidence-freshness-hours"
                  type="number"
                  min={1}
                  max={720}
                  value={s.evidenceFreshnessMaxHours}
                  onChange={(e) =>
                    updateSettings({
                      evidenceFreshnessMaxHours: Math.max(1, Number(e.target.value) || 48),
                    })
                  }
                  className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                />
              </div>

              <div>
                <label htmlFor="max-daily-spend" className="block font-medium mb-1">
                  {t('settings.maxDailySpendLabel')}
                </label>
                <input
                  id="max-daily-spend"
                  type="number"
                  min={0}
                  value={s.maxGlobalDailySpendBRL}
                  onChange={(e) =>
                    updateSettings({
                      maxGlobalDailySpendBRL: Math.max(0, Number(e.target.value) || 0),
                    })
                  }
                  className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                />
              </div>
            </div>
          </div>

          {controlFeedback && (
            <div
              role="status"
              className={`p-3 rounded border text-xs flex flex-wrap items-center justify-between gap-2 ${
                controlFeedback.ok
                  ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-800 dark:text-emerald-200'
                  : 'bg-amber-500/10 border-amber-500/30 text-amber-800 dark:text-amber-200'
              }`}
            >
              <span>{controlFeedback.message}</span>
              {!resumeGate.allowed && (
                <button
                  type="button"
                  onClick={() => {
                    const count = reconcileJobsDemo();
                    setControlFeedback({
                      ok: true,
                      message: t('settings.reconciledNotice', { count }),
                    });
                  }}
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded bg-amber-600 text-white font-medium hover:bg-amber-700"
                >
                  <RefreshCw className="w-3 h-3" aria-hidden="true" />
                  <span>{t('settings.reconcileNow')}</span>
                </button>
              )}
            </div>
          )}

          <div className="pt-3 border-t border-black/10 dark:border-white/10 flex flex-wrap items-center justify-between gap-3 text-xs">
            <div>
              <div className="font-semibold text-rose-700 dark:text-rose-400">
                {t('settings.emergencyTitle', {
                  controls: t('automations.kpi.controls'),
                  state: labelSystemControlState(state.systemControl.state, lang),
                })}
              </div>
              <p className="text-[#525B68] dark:text-[#AEB7C2]">{t('settings.emergencyDesc')}</p>
            </div>
            {isHalted ? (
              <button
                type="button"
                onClick={handleResume}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded bg-emerald-600 text-white font-medium hover:bg-emerald-700 whitespace-nowrap"
              >
                {t('settings.releaseAutonomy')}
              </button>
            ) : (
              <button
                type="button"
                onClick={handleHalt}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded bg-rose-600 text-white font-medium hover:bg-rose-700 whitespace-nowrap"
              >
                <OctagonAlert className="w-3.5 h-3.5" aria-hidden="true" />
                <span>{t('settings.triggerStopAll')}</span>
              </button>
            )}
          </div>
        </SurfacePanel>
      </div>

      {/* Architecture Roadmap */}
      <SurfacePanel className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div>
            <h2 className="font-display text-sm font-semibold">{t('settings.arch.title')}</h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">{t('settings.arch.subtitle')}</p>
          </div>
          <span className="font-mono text-[11px] text-[#315FEA] dark:text-[#7FA0FF]">
            {state.systemControl.phaseBPublicAllowed
              ? t('settings.arch.phaseB')
              : t('settings.arch.phaseA')}
          </span>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {architectureBlocks.map((blk) => (
            <div
              key={blk.group}
              className="p-4 rounded-md bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 space-y-2.5 text-xs"
            >
              <div className="flex items-center justify-between gap-2">
                <span className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  {blk.group}
                </span>
                <StatusLabel status={blk.statusLabel} statusKey={blk.statusKey} />
              </div>
              <ul className="space-y-2 text-[#525B68] dark:text-[#AEB7C2] leading-relaxed">
                {blk.items.map((line) => (
                  <li key={line}>{line}</li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </SurfacePanel>

      {/* Risk Register Matrix */}
      <SurfacePanel className="space-y-3">
        <div>
          <h2 className="font-display text-sm font-semibold">{t('settings.risks.title')}</h2>
          <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">{t('settings.risks.subtitle')}</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                <th className="py-2 pr-4">{t('settings.risks.colId')}</th>
                <th className="py-2 pr-4">{t('settings.risks.colPriority')}</th>
                <th className="py-2 pr-4">{t('settings.risks.colRisk')}</th>
                <th className="py-2 pr-4">{t('settings.risks.colControl')}</th>
                <th className="py-2 text-right">{t('common.status')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
              {state.risks.map((rawRisk) => {
                const risk = localizeRisk(rawRisk, lang);
                return (
                  <tr key={risk.id}>
                    <td className="py-2.5 pr-4 font-mono text-[11px] whitespace-nowrap">{risk.id}</td>
                    <td className="py-2.5 pr-4 font-mono font-semibold">
                      <span
                        className={
                          risk.priority === 'P0'
                            ? 'text-rose-600 dark:text-rose-400'
                            : risk.priority === 'P1'
                            ? 'text-amber-700 dark:text-amber-400'
                            : 'text-[#525B68] dark:text-[#AEB7C2]'
                        }
                      >
                        {risk.priority}
                      </span>
                    </td>
                    <td className="py-2.5 pr-4 font-medium">{risk.title}</td>
                    <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2]">
                      {risk.controlSummary}
                    </td>
                    <td className="py-2.5 text-right">
                      <StatusLabel
                        status={labelRiskStatus(risk.status, lang)}
                        statusKey={risk.status}
                      />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </SurfacePanel>

      {/* Vyron Access & Session Security (Independent from Stop All) */}
      <SurfacePanel className="space-y-4">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <h2 className="font-display text-sm font-semibold">{t('settings.access.title')}</h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] mt-0.5">
              {t('settings.access.subtitle', { name: s.ownerName })}
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={() => lock('manual')}
              className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-medium rounded-md border border-black/15 dark:border-white/15 hover:border-[#315FEA] whitespace-nowrap"
            >
              <Lock className="w-3.5 h-3.5 text-[#315FEA]" aria-hidden="true" />
              <span>{t('nav.lockVyron')}</span>
            </button>
            <button
              type="button"
              onClick={logout}
              className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-medium rounded-md border border-rose-500/35 text-rose-700 dark:text-rose-400 hover:bg-rose-500/10 whitespace-nowrap"
            >
              <LogOut className="w-3.5 h-3.5" aria-hidden="true" />
              <span>{t('nav.logout')}</span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 pt-2 border-t border-black/10 dark:border-white/10 text-xs">
          <div className="lg:col-span-5 space-y-2">
            <label htmlFor="idle-timeout-select" className="block font-medium">
              {t('settings.access.autoLockLabel')}
            </label>
            <select
              id="idle-timeout-select"
              value={session.idleTimeoutMinutes}
              onChange={(e) => setIdleTimeoutMinutes(Number(e.target.value))}
              className="w-full h-9 px-3 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
            >
              {IDLE_TIMEOUT_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {t(`access.timeout.${opt.value}` as Parameters<typeof t>[0])}
                </option>
              ))}
            </select>
            <p className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
              {t('settings.access.autoLockDesc')}
            </p>
          </div>

          <form
            className="lg:col-span-7 space-y-2.5"
            onSubmit={(e) => {
              e.preventDefault();
              const res = updateAccessPassword(currentPwd, newPwd);
              if (!res.ok) {
                setPwdFeedback({
                  ok: false,
                  message: res.errorCode
                    ? t(`access.error.${res.errorCode}`)
                    : res.error ?? t('settings.access.pwdErrorFallback'),
                });
                return;
              }
              setCurrentPwd('');
              setNewPwd('');
              setPwdFeedback({
                ok: true,
                message: t('settings.access.pwdUpdated'),
              });
            }}
          >
            <div className="font-medium">{t('settings.access.updatePwdTitle')}</div>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
              <input
                type="password"
                value={currentPwd}
                onChange={(e) => {
                  setCurrentPwd(e.target.value);
                  setPwdFeedback(null);
                }}
                placeholder={t('settings.access.currentPwdPlaceholder')}
                aria-label={t('settings.access.currentPwdAria')}
                className="h-9 px-3 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
              <input
                type="password"
                value={newPwd}
                onChange={(e) => {
                  setNewPwd(e.target.value);
                  setPwdFeedback(null);
                }}
                placeholder={t('settings.access.newPwdPlaceholder')}
                aria-label={t('settings.access.newPwdAria')}
                className="h-9 px-3 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
              <button
                type="submit"
                className="h-9 px-4 rounded bg-[#315FEA] hover:bg-[#274FC9] text-white font-medium whitespace-nowrap"
              >
                {t('settings.access.savePwd')}
              </button>
            </div>
            {pwdFeedback && (
              <p
                role="status"
                className={
                  pwdFeedback.ok
                    ? 'text-[11px] text-emerald-700 dark:text-emerald-400'
                    : 'text-[11px] text-rose-600 dark:text-rose-400'
                }
              >
                {pwdFeedback.message}
              </p>
            )}
          </form>
        </div>
      </SurfacePanel>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Notification Preferences */}
        <SurfacePanel className="lg:col-span-5 space-y-3">
          <h2 className="font-display text-sm font-semibold">{t('settings.notifPrefs.title')}</h2>
          <div className="space-y-2 text-xs">
            {(
              [
                ['financialAlerts', t('settings.notifPrefs.financialAlerts')],
                ['commissionsReceived', t('settings.notifPrefs.commissionsReceived')],
                ['opportunities', t('settings.notifPrefs.opportunities')],
                ['pendingApprovals', t('settings.notifPrefs.pendingApprovals')],
                ['automationFailures', t('settings.notifPrefs.automationFailures')],
                ['operationalEvents', t('settings.notifPrefs.operationalEvents')],
              ] as const
            ).map(([key, label]) => (
              <label
                key={key}
                className="flex items-center justify-between py-2 border-b border-black/[0.06] dark:border-white/[0.06] last:border-0"
              >
                <span>{label}</span>
                <input
                  type="checkbox"
                  checked={s.notificationPrefs[key]}
                  onChange={(e) =>
                    updateSettings({
                      notificationPrefs: {
                        ...s.notificationPrefs,
                        [key]: e.target.checked,
                      },
                    })
                  }
                  className="accent-[#315FEA]"
                />
              </label>
            ))}
          </div>
        </SurfacePanel>

        {/* Integrations Registry (Demo State) */}
        <SurfacePanel className="lg:col-span-7">
          <h2 className="font-display text-sm font-semibold mb-1">
            {t('settings.integrations.title')}
          </h2>
          <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] mb-4">
            {t('settings.integrations.subtitle')}
          </p>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">{t('settings.integrations.colName')}</th>
                  <th className="py-2 pr-4">{t('settings.integrations.colCategory')}</th>
                  <th className="py-2 pr-4">{t('settings.integrations.colChecked')}</th>
                  <th className="py-2 text-right">{t('common.status')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {s.integrations.map((rawInt) => {
                  const int = localizeIntegration(rawInt, lang);
                  return (
                    <tr key={int.id}>
                      <td className="py-2.5 pr-4 font-medium">{int.name}</td>
                      <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2]">
                        {int.category}
                      </td>
                      <td className="py-2.5 pr-4 font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {int.lastChecked}
                      </td>
                      <td className="py-2.5 text-right">
                        <StatusLabel
                          status={labelIntegrationConfigStatus(int.status, lang)}
                          statusKey={int.status}
                        />
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </SurfacePanel>
      </div>
    </div>
  );
};

