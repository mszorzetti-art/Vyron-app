import React, { useState } from 'react';
import {
  ArrowLeft,
  Check,
  OctagonAlert,
  Pause,
  Play,
  RefreshCw,
  ShieldCheck,
  Terminal,
} from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { AgentCategory, JobRun } from '../types/vyron';
import { canResumeSystemControl } from '../utils/vyronRules';
import { useI18n } from '../i18n/useI18n';
import {
  labelAgentCategory,
  labelAgentExecutionStatus,
  labelAgentState,
  labelAutonomyLevel,
  labelJobMode,
  labelJobStatus,
  labelSystemControlState,
} from '../i18n/domainLabels';
import {
  localizeActor,
  localizeAgent,
  localizeJobRun,
  localizeSystemControlReason,
} from '../i18n/seedTranslations';
import {
  EmptyState,
  MetricBlock,
  ModalDialog,
  PageHeader,
  SegmentedControl,
  StatusLabel,
  SurfacePanel,
} from '../components/ui';

const AGENT_CATEGORIES: AgentCategory[] = [
  'Research',
  'Product Intelligence',
  'Content',
  'Analytics',
  'Finance',
  'Operations',
];

export const AutomationsView: React.FC = () => {
  const {
    state,
    selectedAutomationId,
    navigate,
    toggleAgentRun,
    updateAgentLimits,
    approveAgentPending,
    runPipelineDemo,
    reconcileJobsDemo,
    haltSystemControl,
    resumeSystemControl,
  } = useVyron();
  const { lang, t, fmtDateTime } = useI18n();

  const [tab, setTab] = useState<'agents' | 'jobs'>('agents');
  const [catFilter, setCatFilter] = useState<'all' | AgentCategory>('all');
  const [runnerFeedback, setRunnerFeedback] = useState<{
    ok: boolean;
    message: string;
  } | null>(null);

  const [controlModal, setControlModal] = useState<'halt' | 'resume' | null>(null);
  const [actorInput, setActorInput] = useState(state.settings.ownerName);
  const [reasonInput, setReasonInput] = useState('');
  const [controlError, setControlError] = useState('');

  const isHalted = state.systemControl.state === 'HALTED';
  const resumeGate = canResumeSystemControl(state.jobRuns, lang);
  const orphanedCount = state.jobRuns.filter(
    (j) => j.status === 'running' || j.status === 'unknown'
  ).length;

  const formatModuleLabel = (mod: string): string => {
    switch (mod) {
      case 'overview':
        return t('nav.overview');
      case 'brands':
        return t('nav.brands');
      case 'products':
        return t('nav.products');
      case 'content':
        return t('nav.content');
      case 'channels':
        return t('nav.channels');
      case 'analytics':
        return t('nav.analytics');
      case 'finance':
        return t('nav.finance');
      case 'automations':
        return t('nav.automations');
      case 'activity':
        return t('nav.activity');
      case 'notifications':
        return t('nav.notifications');
      case 'settings':
        return t('nav.settings');
      default:
        return mod;
    }
  };

  const formatTaskLabel = (taskName: JobRun['taskName']): string => {
    switch (taskName) {
      case 'pipeline.run':
        return t('automations.jobs.taskPipelineRun');
      case 'products.score':
        return t('automations.jobs.taskProductsScore');
      case 'products.import':
        return t('automations.jobs.taskProductsImport');
      case 'jobs.reconcile':
        return t('automations.jobs.taskJobsReconcile');
    }
  };

  const openControlModal = (mode: 'halt' | 'resume') => {
    setActorInput(state.settings.ownerName);
    setReasonInput('');
    setControlError('');
    setControlModal(mode);
  };

  const handleControlSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!actorInput.trim() || !reasonInput.trim()) {
      setControlError(t('controls.modal.missingFields'));
      return;
    }
    if (controlModal === 'halt') {
      const count = haltSystemControl(actorInput, reasonInput);
      setRunnerFeedback({
        ok: true,
        message: t('automations.feedback.halted', { count }),
      });
      setControlModal(null);
      return;
    }
    if (controlModal === 'resume') {
      const res = resumeSystemControl(actorInput, reasonInput);
      if (!res.ok) {
        setControlError(res.reason ?? t('controls.modal.resumeBlockedDefault'));
        return;
      }
      setRunnerFeedback({
        ok: true,
        message: t('automations.feedback.resumed'),
      });
      setControlModal(null);
    }
  };

  // SUBPAGE: Automation Detail
  if (selectedAutomationId) {
    const rawAgent = state.automations.find((a) => a.id === selectedAutomationId);
    if (!rawAgent) {
      return (
        <EmptyState
          title={t('automations.detail.notFoundTitle')}
          description={t('automations.detail.notFoundDesc')}
          actionLabel={t('automations.detail.back')}
          onAction={() => navigate('automations', { automationId: null })}
        />
      );
    }

    const agent = localizeAgent(rawAgent, lang);
    const scopeLabel =
      agent.brandScope === 'Todas'
        ? t('automations.detail.allBrands')
        : state.brands.find((b) => b.id === agent.brandScope)?.name ?? agent.brandScope;

    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between gap-4">
          <button
            type="button"
            onClick={() => navigate('automations', { automationId: null })}
            className="inline-flex items-center gap-1.5 text-xs font-medium text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]"
          >
            <ArrowLeft className="w-3.5 h-3.5" aria-hidden="true" />
            <span>{t('automations.detail.back')}</span>
          </button>
          <StatusLabel status={labelAgentState(agent.state, lang)} statusKey={agent.state} />
        </div>

        <PageHeader
          title={agent.name}
          subtitle={t('automations.detail.subtitle', {
            category: labelAgentCategory(agent.category, lang),
            level: agent.autonomyLevel,
            levelLabel: labelAutonomyLevel(agent.autonomyLevel, lang),
            scope: scopeLabel,
          })}
          actions={
            <>
              {agent.pendingApprovalCount > 0 && (
                <button
                  type="button"
                  onClick={() => approveAgentPending(agent.id)}
                  className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-emerald-600 text-white hover:bg-emerald-700 whitespace-nowrap"
                >
                  <Check className="w-3.5 h-3.5" aria-hidden="true" />
                  <span>{t('automations.detail.approveQueue', { count: agent.pendingApprovalCount })}</span>
                </button>
              )}
              <button
                type="button"
                disabled={isHalted}
                onClick={() => toggleAgentRun(agent.id)}
                className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] disabled:opacity-45 whitespace-nowrap"
              >
                {agent.state === 'Running' ? (
                  <>
                    <Pause className="w-3.5 h-3.5" aria-hidden="true" />
                    <span>{t('automations.detail.pauseDemo')}</span>
                  </>
                ) : (
                  <>
                    <Play className="w-3.5 h-3.5" aria-hidden="true" />
                    <span>{t('automations.detail.startDemo')}</span>
                  </>
                )}
              </button>
            </>
          }
        />

        {agent.lastError && (
          <div className="p-4 rounded-lg bg-rose-500/10 border border-rose-500/30 text-xs text-rose-700 dark:text-rose-300">
            <div className="font-semibold">{t('automations.detail.errorTitle')}</div>
            <p className="mt-1">{agent.lastError}</p>
          </div>
        )}

        {agent.pendingApprovalSummary && (
          <div className="p-4 rounded-lg bg-amber-500/10 border border-amber-500/30 text-xs text-amber-800 dark:text-amber-200 flex flex-wrap items-center justify-between gap-3">
            <div>
              <div className="font-semibold">{t('automations.detail.pendingTitle')}</div>
              <p className="mt-1">{agent.pendingApprovalSummary}</p>
            </div>
            <button
              type="button"
              onClick={() => approveAgentPending(agent.id)}
              className="px-3.5 py-1.5 rounded bg-amber-600 text-white font-medium hover:bg-amber-700 whitespace-nowrap"
            >
              {t('automations.detail.authorizeActions')}
            </button>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          {/* Flow & Dependencies */}
          <SurfacePanel className="lg:col-span-7 space-y-5">
            <div>
              <div className="flex flex-wrap items-center justify-between gap-2 mb-1.5">
                <h2 className="font-display text-sm font-semibold">
                  {t('automations.detail.flowTitle')}
                </h2>
                <span className="font-mono text-[11px] text-[#315FEA] dark:text-[#7FA0FF]">
                  {t('automations.detail.levelBadge', { level: agent.autonomyLevel })}
                </span>
              </div>
              <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                {agent.responsibility}
              </p>
            </div>

            <ol className="space-y-2.5">
              {agent.flowSteps.map((step, i) => (
                <li
                  key={step}
                  className="flex items-center gap-3 p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 text-xs"
                >
                  <span className="font-mono text-[11px] font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                    0{i + 1}
                  </span>
                  <span>{step}</span>
                </li>
              ))}
            </ol>

            <div className="pt-3 border-t border-black/10 dark:border-white/10 text-xs">
              <div className="font-medium mb-1">{t('automations.detail.dependencies')}</div>
              <p className="text-[#525B68] dark:text-[#AEB7C2]">
                {agent.dependencies.join(' · ')}
              </p>
            </div>
          </SurfacePanel>

          {/* Policy Limits & Permissions */}
          <SurfacePanel className="lg:col-span-5 space-y-4">
            <div className="flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-[#315FEA]" aria-hidden="true" />
              <h2 className="font-display text-sm font-semibold">
                {t('automations.detail.policiesTitle')}
              </h2>
            </div>

            <div className="space-y-3 text-xs">
              <label className="flex items-center justify-between gap-3 p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
                <span>{t('automations.detail.requireApproval')}</span>
                <input
                  type="checkbox"
                  checked={agent.limits.requireHumanApproval}
                  onChange={(e) =>
                    updateAgentLimits(agent.id, {
                      ...agent.limits,
                      requireHumanApproval: e.target.checked,
                    })
                  }
                  className="accent-[#315FEA]"
                />
              </label>

              <div>
                <label htmlFor="agent-max-actions" className="block font-medium mb-1">
                  {t('automations.detail.maxActions')}
                </label>
                <input
                  id="agent-max-actions"
                  type="number"
                  min="1"
                  max="200"
                  value={agent.limits.maxActionsPerDay}
                  onChange={(e) =>
                    updateAgentLimits(agent.id, {
                      ...agent.limits,
                      maxActionsPerDay: Math.max(1, Number(e.target.value) || 1),
                    })
                  }
                  className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                />
              </div>

              <div>
                <label htmlFor="agent-max-spend" className="block font-medium mb-1">
                  {t('automations.detail.maxSpend')}
                </label>
                <input
                  id="agent-max-spend"
                  type="number"
                  min="0"
                  value={agent.limits.maxDailySpendBRL}
                  onChange={(e) =>
                    updateAgentLimits(agent.id, {
                      ...agent.limits,
                      maxDailySpendBRL: Math.max(0, Number(e.target.value) || 0),
                    })
                  }
                  className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                />
              </div>

              <div className="pt-2 border-t border-black/10 dark:border-white/10">
                <div className="font-medium mb-1">{t('automations.detail.allowedModules')}</div>
                <p className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  {agent.limits.allowedModules.map(formatModuleLabel).join(' · ')}
                </p>
              </div>
            </div>
          </SurfacePanel>
        </div>

        {/* Execution History */}
        <SurfacePanel>
          <h2 className="font-display text-sm font-semibold mb-3">
            {t('automations.detail.historyTitle')}
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">{t('automations.detail.colTimestamp')}</th>
                  <th className="py-2 pr-4">{t('common.status')}</th>
                  <th className="py-2 pr-4">{t('automations.detail.colSummary')}</th>
                  <th className="py-2 pr-4 text-right">{t('automations.detail.colDuration')}</th>
                  <th className="py-2 text-right">{t('automations.detail.colRecords')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {agent.history.map((h) => (
                  <tr key={h.id}>
                    <td className="py-2.5 pr-4 font-mono tabular-nums text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {fmtDateTime(h.timestamp)}
                    </td>
                    <td className="py-2.5 pr-4">
                      <StatusLabel
                        status={labelAgentExecutionStatus(h.status, lang)}
                        statusKey={h.status}
                      />
                    </td>
                    <td className="py-2.5 pr-4">{h.summary}</td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {h.durationSec}s
                    </td>
                    <td className="py-2.5 text-right font-mono tabular-nums">
                      {h.recordsAffected}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </SurfacePanel>
      </div>
    );
  }

  const visibleAgents = state.automations.filter(
    (a) => catFilter === 'all' || a.category === catFilter
  );

  const handleRunCommand = (
    mode: 'dry-run' | 'commit',
    taskName: 'pipeline.run' | 'products.score'
  ) => {
    const res = runPipelineDemo(mode, taskName);
    setRunnerFeedback({ ok: res.ok, message: res.message });
  };

  const handleReconcile = () => {
    const count = reconcileJobsDemo();
    setRunnerFeedback({
      ok: true,
      message:
        count > 0
          ? t('automations.feedback.reconciled', { count })
          : t('automations.feedback.reconciledNone'),
    });
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('automations.title')}
        subtitle={t('automations.subtitle')}
        actions={
          isHalted ? (
            <button
              type="button"
              onClick={() => openControlModal('resume')}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-rose-600 text-white hover:bg-rose-700 whitespace-nowrap"
            >
              <OctagonAlert className="w-3.5 h-3.5" aria-hidden="true" />
              <span>{t('automations.haltedResume')}</span>
            </button>
          ) : (
            <button
              type="button"
              onClick={() => openControlModal('halt')}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-rose-600 text-white hover:bg-rose-700 whitespace-nowrap"
            >
              <OctagonAlert className="w-3.5 h-3.5" aria-hidden="true" />
              <span>{t('automations.stopAllImmediate')}</span>
            </button>
          )
        }
      />

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricBlock
          label={t('automations.kpi.controls')}
          value={labelSystemControlState(state.systemControl.state, lang)}
          helper={t('automations.kpi.actor', {
            actor: localizeActor(state.systemControl.actor, lang),
          })}
          tone={isHalted ? 'crimson' : 'emerald'}
        />
        <MetricBlock
          label={t('automations.kpi.activeAgents')}
          value={`${state.automations.filter((a) => a.state === 'Running').length}`}
          helper={t('automations.kpi.activeAgentsHelper', {
            total: state.automations.length,
          })}
          tone="cobalt"
        />
        <MetricBlock
          label={t('automations.kpi.approvals')}
          value={`${state.automations.reduce((s, a) => s + a.pendingApprovalCount, 0)}`}
          helper={t('automations.kpi.approvalsHelper')}
          tone="amber"
        />
        <MetricBlock
          label={t('automations.kpi.pendingJobs')}
          value={`${orphanedCount}`}
          helper={
            orphanedCount > 0
              ? t('automations.kpi.pendingJobsBlocked')
              : t('automations.kpi.pendingJobsOk')
          }
          tone={orphanedCount > 0 ? 'amber' : 'neutral'}
        />
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <SegmentedControl
          ariaLabel={t('automations.tabAria')}
          value={tab}
          onChange={(v) => setTab(v as 'agents' | 'jobs')}
          options={[
            {
              value: 'agents',
              label: t('automations.tabAgents', { count: state.automations.length }),
            },
            {
              value: 'jobs',
              label: t('automations.tabJobs', { count: state.jobRuns.length }),
            },
          ]}
        />

        {tab === 'agents' && (
          <SegmentedControl
            ariaLabel={t('automations.catFilterAria')}
            value={catFilter}
            onChange={(v) => setCatFilter(v as 'all' | AgentCategory)}
            options={[
              { value: 'all', label: t('automations.allCategories') },
              ...AGENT_CATEGORIES.map((c) => ({
                value: c,
                label: labelAgentCategory(c, lang),
              })),
            ]}
          />
        )}
      </div>

      {runnerFeedback && (
        <div
          role="status"
          className={`p-3.5 rounded-lg border text-xs flex flex-wrap items-center justify-between gap-3 ${
            runnerFeedback.ok
              ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-800 dark:text-emerald-200'
              : 'bg-rose-500/10 border-rose-500/30 text-rose-700 dark:text-rose-300'
          }`}
        >
          <span>{runnerFeedback.message}</span>
          <button
            type="button"
            onClick={() => setRunnerFeedback(null)}
            className="text-[11px] font-medium underline"
          >
            {t('common.dismiss')}
          </button>
        </div>
      )}

      {tab === 'agents' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {visibleAgents.map((rawAgent) => {
            const agent = localizeAgent(rawAgent, lang);
            return (
              <SurfacePanel
                key={agent.id}
                className="flex flex-col justify-between hover:border-[#315FEA]/50"
              >
                <div>
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <div className="text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]">
                        {labelAgentCategory(agent.category, lang)} ·{' '}
                        {t('automations.card.meta', {
                          level: agent.autonomyLevel,
                          max: agent.limits.maxActionsPerDay,
                        })}
                      </div>
                      <h2 className="mt-0.5 font-display text-base font-semibold">
                        {agent.name}
                      </h2>
                    </div>
                    <StatusLabel
                      status={labelAgentState(agent.state, lang)}
                      statusKey={agent.state}
                    />
                  </div>

                  <p className="mt-2.5 text-xs text-[#525B68] dark:text-[#AEB7C2] leading-relaxed">
                    {agent.responsibility}
                  </p>

                  {agent.lastError && (
                    <p className="mt-2.5 text-xs text-rose-600 dark:text-rose-400">
                      {t('automations.card.errorPrefix', { error: agent.lastError })}
                    </p>
                  )}
                  {agent.pendingApprovalSummary && (
                    <p className="mt-2.5 text-xs text-amber-700 dark:text-amber-300">
                      {agent.pendingApprovalSummary}
                    </p>
                  )}
                </div>

                <div className="mt-4 pt-3 border-t border-black/10 dark:border-white/10 flex flex-wrap items-center justify-between gap-2 text-xs">
                  <span className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    {agent.autonomyLevel} · {labelAutonomyLevel(agent.autonomyLevel, lang)}
                  </span>
                  <div className="flex items-center gap-3">
                    <button
                      type="button"
                      disabled={isHalted}
                      onClick={() => toggleAgentRun(agent.id)}
                      className="font-medium text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3] disabled:opacity-40"
                    >
                      {agent.state === 'Running'
                        ? t('automations.card.pause')
                        : t('automations.card.runDemo')}
                    </button>
                    <button
                      type="button"
                      onClick={() => navigate('automations', { automationId: agent.id })}
                      className="font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
                    >
                      {t('automations.card.detailsLimits')}
                    </button>
                  </div>
                </div>
              </SurfacePanel>
            );
          })}
        </div>
      ) : (
        <div className="space-y-5">
          {/* System Controls & Batch Runner */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
            <SurfacePanel className="lg:col-span-5 space-y-4">
              <div className="flex items-center justify-between gap-2">
                <h2 className="font-display text-sm font-semibold">
                  {t('automations.jobs.controlStateTitle')}
                </h2>
                <StatusLabel
                  status={labelSystemControlState(state.systemControl.state, lang)}
                  statusKey={state.systemControl.state}
                />
              </div>

              <dl className="grid grid-cols-2 gap-3 text-xs">
                <div>
                  <dt className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    {t('automations.jobs.lastActor')}
                  </dt>
                  <dd className="font-medium mt-0.5">
                    {localizeActor(state.systemControl.actor, lang)}
                  </dd>
                </div>
                <div>
                  <dt className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    {t('automations.jobs.updatedAt')}
                  </dt>
                  <dd className="font-mono tabular-nums mt-0.5">
                    {fmtDateTime(state.systemControl.updatedAt)}
                  </dd>
                </div>
                <div className="col-span-2">
                  <dt className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    {t('automations.jobs.reason')}
                  </dt>
                  <dd className="mt-0.5 text-[#101216] dark:text-[#F1F2F3]">
                    {localizeSystemControlReason(state.systemControl.reason, lang)}
                  </dd>
                </div>
              </dl>

              {!resumeGate.allowed && (
                <div className="p-3 rounded bg-amber-500/10 border border-amber-500/30 text-xs text-amber-800 dark:text-amber-200 space-y-2">
                  <div className="font-semibold">{t('automations.jobs.resumeLockTitle')}</div>
                  <p>{resumeGate.reason}</p>
                  <button
                    type="button"
                    onClick={handleReconcile}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded bg-amber-600 text-white font-medium hover:bg-amber-700"
                  >
                    <RefreshCw className="w-3.5 h-3.5" aria-hidden="true" />
                    <span>{t('automations.jobs.reconcileBtn')}</span>
                  </button>
                </div>
              )}

              <div className="pt-2 border-t border-black/10 dark:border-white/10 flex flex-wrap gap-2">
                {isHalted ? (
                  <button
                    type="button"
                    onClick={() => openControlModal('resume')}
                    className="px-3.5 py-2 rounded bg-[#315FEA] text-white text-xs font-medium hover:bg-[#274FC9]"
                  >
                    {t('automations.jobs.cliResume')}
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={() => openControlModal('halt')}
                    className="px-3.5 py-2 rounded bg-rose-600 text-white text-xs font-medium hover:bg-rose-700"
                  >
                    {t('automations.jobs.cliHalt')}
                  </button>
                )}
              </div>
            </SurfacePanel>

            <SurfacePanel className="lg:col-span-7 space-y-4">
              <div className="flex items-center gap-2">
                <Terminal className="w-4 h-4 text-[#315FEA]" aria-hidden="true" />
                <h2 className="font-display text-sm font-semibold">
                  {t('automations.jobs.runnerTitle')}
                </h2>
              </div>
              <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                {t('automations.jobs.runnerDesc')}
              </p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 text-xs">
                <button
                  type="button"
                  onClick={() => handleRunCommand('dry-run', 'pipeline.run')}
                  className="px-3.5 py-2.5 rounded border border-black/15 dark:border-white/15 text-left hover:border-[#315FEA]"
                >
                  <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                    {t('automations.jobs.cmdDryRunTitle')}
                  </div>
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mt-0.5">
                    {t('automations.jobs.cmdDryRunDesc')}
                  </div>
                </button>

                <button
                  type="button"
                  onClick={() => handleRunCommand('commit', 'pipeline.run')}
                  className="px-3.5 py-2.5 rounded border border-black/15 dark:border-white/15 text-left hover:border-[#315FEA]"
                >
                  <div className="font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                    {t('automations.jobs.cmdCommitTitle')}
                  </div>
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mt-0.5">
                    {t('automations.jobs.cmdCommitDesc')}
                  </div>
                </button>

                <button
                  type="button"
                  onClick={() => handleRunCommand('commit', 'products.score')}
                  className="px-3.5 py-2.5 rounded border border-black/15 dark:border-white/15 text-left hover:border-[#315FEA]"
                >
                  <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                    {t('automations.jobs.cmdScoreTitle')}
                  </div>
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mt-0.5">
                    {t('automations.jobs.cmdScoreDesc')}
                  </div>
                </button>

                <button
                  type="button"
                  onClick={handleReconcile}
                  className="px-3.5 py-2.5 rounded border border-amber-500/40 bg-amber-500/8 text-left hover:border-amber-500"
                >
                  <div className="font-semibold text-amber-800 dark:text-amber-300">
                    {t('automations.jobs.cmdReconcileTitle')}
                  </div>
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mt-0.5">
                    {t('automations.jobs.cmdReconcileDesc')}
                  </div>
                </button>
              </div>
            </SurfacePanel>
          </div>

          {/* Job Runs ledger table */}
          <SurfacePanel>
            <div className="flex items-center justify-between gap-3 mb-4">
              <h2 className="font-display text-sm font-semibold">
                {t('automations.jobs.ledgerTitle', { count: state.jobRuns.length })}
              </h2>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    <th className="py-2 pr-4">{t('automations.jobs.colId')}</th>
                    <th className="py-2 pr-4">{t('automations.jobs.colTask')}</th>
                    <th className="py-2 pr-4">{t('automations.jobs.colMode')}</th>
                    <th className="py-2 pr-4">{t('automations.jobs.colStarted')}</th>
                    <th className="py-2 pr-4 text-right">{t('automations.jobs.colRecords')}</th>
                    <th className="py-2 pr-4">{t('common.status')}</th>
                    <th className="py-2">{t('automations.jobs.colSummary')}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                  {state.jobRuns.map((rawJob) => {
                    const job = localizeJobRun(rawJob, lang);
                    return (
                      <tr key={job.id}>
                        <td className="py-2.5 pr-4 font-mono tabular-nums">#{job.id}</td>
                        <td className="py-2.5 pr-4 font-medium">{formatTaskLabel(job.taskName)}</td>
                        <td className="py-2.5 pr-4 whitespace-nowrap text-[#525B68] dark:text-[#AEB7C2]">
                          {labelJobMode(job.mode, lang)}
                        </td>
                        <td className="py-2.5 pr-4 font-mono tabular-nums whitespace-nowrap text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                          {fmtDateTime(job.startedAt)}
                        </td>
                        <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                          {job.recordsProcessed}
                        </td>
                        <td className="py-2.5 pr-4">
                          <StatusLabel
                            status={labelJobStatus(job.status, lang)}
                            statusKey={job.status}
                          />
                        </td>
                        <td className="py-2.5">
                          <div>{job.summary}</div>
                          {job.error && (
                            <div className="text-[11px] text-rose-600 dark:text-rose-400 mt-0.5">
                              {job.error}
                            </div>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </SurfacePanel>
        </div>
      )}

      {/* Actor + Reason Modal for Halt / Resume */}
      <ModalDialog
        open={controlModal !== null}
        title={
          controlModal === 'halt'
            ? t('controls.modal.haltTitle')
            : t('controls.modal.resumeTitle')
        }
        subtitle={
          controlModal === 'halt'
            ? t('controls.modal.haltSubtitle')
            : t('controls.modal.resumeSubtitle')
        }
        onClose={() => setControlModal(null)}
      >
        <form onSubmit={handleControlSubmit} className="space-y-4 text-xs">
          {controlModal === 'resume' && !resumeGate.allowed && (
            <div className="p-3 rounded bg-amber-500/12 border border-amber-500/35 text-amber-800 dark:text-amber-200 space-y-2">
              <div className="font-semibold">{t('controls.modal.orphanWarningTitle')}</div>
              <p>{resumeGate.reason}</p>
              <button
                type="button"
                onClick={() => {
                  handleReconcile();
                  setControlError('');
                }}
                className="px-3 py-1.5 rounded bg-amber-600 text-white font-medium hover:bg-amber-700"
              >
                {t('controls.modal.reconcileNow')}
              </button>
            </div>
          )}

          <div>
            <label htmlFor="auto-ctrl-actor" className="block font-medium mb-1">
              {t('controls.modal.actorLabel')}
            </label>
            <input
              id="auto-ctrl-actor"
              required
              value={actorInput}
              onChange={(e) => setActorInput(e.target.value)}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>

          <div>
            <label htmlFor="auto-ctrl-reason" className="block font-medium mb-1">
              {t('controls.modal.reasonLabel')}
            </label>
            <textarea
              id="auto-ctrl-reason"
              required
              rows={2}
              value={reasonInput}
              onChange={(e) => {
                setReasonInput(e.target.value);
                setControlError('');
              }}
              placeholder={
                controlModal === 'halt'
                  ? t('controls.modal.haltPlaceholder')
                  : t('controls.modal.resumePlaceholder')
              }
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>

          {controlError && (
            <p className="text-rose-600 dark:text-rose-400 font-medium">{controlError}</p>
          )}

          <div className="flex justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => setControlModal(null)}
              className="px-3.5 py-2 rounded border border-black/15 dark:border-white/15"
            >
              {t('common.cancel')}
            </button>
            <button
              type="submit"
              disabled={controlModal === 'resume' && !resumeGate.allowed}
              className={`px-4 py-2 rounded text-white font-medium disabled:opacity-45 ${
                controlModal === 'halt'
                  ? 'bg-rose-600 hover:bg-rose-700'
                  : 'bg-[#315FEA] hover:bg-[#274FC9]'
              }`}
            >
              {controlModal === 'halt'
                ? t('controls.modal.confirmHalt')
                : t('controls.modal.confirmResume')}
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};

