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
import { AgentCategory, AutonomyLevel } from '../types/vyron';
import { canResumeSystemControl } from '../utils/vyronRules';
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

const AUTONOMY_LEVEL_LABELS: Record<AutonomyLevel, string> = {
  0: '0 · Manual',
  1: '1 · Leitura & Monitoramento',
  2: '2 · Rascunhos & Score',
  3: '3 · Aprovação Obrigatória',
  4: '4 · Autônomo por Política',
};

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
  const resumeGate = canResumeSystemControl(state.jobRuns);
  const orphanedCount = state.jobRuns.filter(
    (j) => j.status === 'running' || j.status === 'unknown'
  ).length;

  const openControlModal = (mode: 'halt' | 'resume') => {
    setActorInput(state.settings.ownerName);
    setReasonInput('');
    setControlError('');
    setControlModal(mode);
  };

  const handleControlSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!actorInput.trim() || !reasonInput.trim()) {
      setControlError('Informe actor e motivo obrigatórios para registro no audit_log.');
      return;
    }
    if (controlModal === 'halt') {
      const count = haltSystemControl(actorInput, reasonInput);
      setRunnerFeedback({
        ok: true,
        message: `system_controls alterado para HALTED (${count} agente(s) interrompido(s)).`,
      });
      setControlModal(null);
      return;
    }
    if (controlModal === 'resume') {
      const res = resumeSystemControl(actorInput, reasonInput);
      if (!res.ok) {
        setControlError(res.reason ?? 'Resume bloqueado por jobs pendentes.');
        return;
      }
      setRunnerFeedback({
        ok: true,
        message: 'system_controls retomado para ACTIVE após verificação limpa.',
      });
      setControlModal(null);
    }
  };

  // SUBPAGE: Automation Detail (Mockup #12)
  if (selectedAutomationId) {
    const agent = state.automations.find((a) => a.id === selectedAutomationId);
    if (!agent) {
      return (
        <EmptyState
          title="Automação não encontrada"
          description="Selecione um agente válido no catálogo."
          actionLabel="Voltar para Automações"
          onAction={() => navigate('automations', { automationId: null })}
        />
      );
    }

    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between gap-4">
          <button
            type="button"
            onClick={() => navigate('automations', { automationId: null })}
            className="inline-flex items-center gap-1.5 text-xs font-medium text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]"
          >
            <ArrowLeft className="w-3.5 h-3.5" aria-hidden="true" />
            <span>Voltar para Catálogo de Agentes</span>
          </button>
          <StatusLabel status={agent.state} />
        </div>

        <PageHeader
          title={agent.name}
          subtitle={`${agent.category} · Autonomia Nível ${agent.autonomyLevel}/4 (${AUTONOMY_LEVEL_LABELS[agent.autonomyLevel]}) · Escopo: ${
            agent.brandScope === 'Todas'
              ? 'Todas as Marcas'
              : state.brands.find((b) => b.id === agent.brandScope)?.name ?? agent.brandScope
          }`}
          actions={
            <>
              {agent.pendingApprovalCount > 0 && (
                <button
                  type="button"
                  onClick={() => approveAgentPending(agent.id)}
                  className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-emerald-600 text-white hover:bg-emerald-700 whitespace-nowrap"
                >
                  <Check className="w-3.5 h-3.5" aria-hidden="true" />
                  <span>Aprovar Fila ({agent.pendingApprovalCount})</span>
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
                    <span>Pausar Execução Demo</span>
                  </>
                ) : (
                  <>
                    <Play className="w-3.5 h-3.5" aria-hidden="true" />
                    <span>Iniciar Execução Demo</span>
                  </>
                )}
              </button>
            </>
          }
        />

        {agent.lastError && (
          <div className="p-4 rounded-lg bg-rose-500/10 border border-rose-500/30 text-xs text-rose-700 dark:text-rose-300">
            <div className="font-semibold">Falha Registrada</div>
            <p className="mt-1">{agent.lastError}</p>
          </div>
        )}

        {agent.pendingApprovalSummary && (
          <div className="p-4 rounded-lg bg-amber-500/10 border border-amber-500/30 text-xs text-amber-800 dark:text-amber-200 flex flex-wrap items-center justify-between gap-3">
            <div>
              <div className="font-semibold">Aguardando Aprovação do Proprietário</div>
              <p className="mt-1">{agent.pendingApprovalSummary}</p>
            </div>
            <button
              type="button"
              onClick={() => approveAgentPending(agent.id)}
              className="px-3.5 py-1.5 rounded bg-amber-600 text-white font-medium hover:bg-amber-700 whitespace-nowrap"
            >
              Autorizar Ações
            </button>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          {/* Flow & Dependencies */}
          <SurfacePanel className="lg:col-span-7 space-y-5">
            <div>
              <div className="flex flex-wrap items-center justify-between gap-2 mb-1.5">
                <h2 className="font-display text-sm font-semibold">
                  Responsabilidade & Fluxo de Execução
                </h2>
                <span className="font-mono text-[11px] text-[#315FEA] dark:text-[#7FA0FF]">
                  Autonomia Nível {agent.autonomyLevel}/4
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
              <div className="font-medium mb-1">Dependências Operacionais</div>
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
                Políticas, Limites & Permissões
              </h2>
            </div>

            <div className="space-y-3 text-xs">
              <label className="flex items-center justify-between gap-3 p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
                <span>Exigir aprovação humana antes de aplicar</span>
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
                  Limite Máximo de Ações / Dia
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
                  Teto de Gasto Diário Autorizado (BRL)
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
                <div className="font-medium mb-1">Módulos Permitidos</div>
                <p className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  {agent.limits.allowedModules.join(' · ')}
                </p>
              </div>
            </div>
          </SurfacePanel>
        </div>

        {/* Execution History */}
        <SurfacePanel>
          <h2 className="font-display text-sm font-semibold mb-3">
            Histórico de Execuções do Agente
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">Timestamp</th>
                  <th className="py-2 pr-4">Status</th>
                  <th className="py-2 pr-4">Resumo</th>
                  <th className="py-2 pr-4 text-right">Duração</th>
                  <th className="py-2 text-right">Registros</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {agent.history.map((h) => (
                  <tr key={h.id}>
                    <td className="py-2.5 pr-4 font-mono tabular-nums text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {h.timestamp.slice(0, 16).replace('T', ' ')}
                    </td>
                    <td className="py-2.5 pr-4">
                      <StatusLabel status={h.status} />
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
          ? `jobs reconcile concluído: ${count} execução(ões) órfã(s) marcada(s) como failed.`
          : 'jobs reconcile concluído: nenhum job órfão pendente.',
    });
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Automations & Agents"
        subtitle="Níveis de autonomia (0–4), executor em lotes (job_runs) com dry-run padrão e trava fail-closed em system_controls."
        actions={
          isHalted ? (
            <button
              type="button"
              onClick={() => openControlModal('resume')}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-rose-600 text-white hover:bg-rose-700 whitespace-nowrap"
            >
              <OctagonAlert className="w-3.5 h-3.5" aria-hidden="true" />
              <span>HALTED · Retomar Sistema</span>
            </button>
          ) : (
            <button
              type="button"
              onClick={() => openControlModal('halt')}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-rose-600 text-white hover:bg-rose-700 whitespace-nowrap"
            >
              <OctagonAlert className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Stop All Imediato</span>
            </button>
          )
        }
      />

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricBlock
          label="system_controls"
          value={state.systemControl.state}
          helper={`Actor: ${state.systemControl.actor}`}
          tone={isHalted ? 'crimson' : 'emerald'}
        />
        <MetricBlock
          label="Agentes Ativos"
          value={`${state.automations.filter((a) => a.state === 'Running').length}`}
          helper={`De ${state.automations.length} catalogados (Níveis 0–4)`}
          tone="cobalt"
        />
        <MetricBlock
          label="Aprovações"
          value={`${state.automations.reduce((s, a) => s + a.pendingApprovalCount, 0)}`}
          helper="Aguardando proprietário"
          tone="amber"
        />
        <MetricBlock
          label="job_runs Pendentes"
          value={`${orphanedCount}`}
          helper={orphanedCount > 0 ? 'Bloqueia resume até reconcile' : 'Fila íntegra'}
          tone={orphanedCount > 0 ? 'amber' : 'neutral'}
        />
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <SegmentedControl
          ariaLabel="Alternar entre Agentes e Executor em Lotes"
          value={tab}
          onChange={(v) => setTab(v as 'agents' | 'jobs')}
          options={[
            { value: 'agents', label: `Agentes & Políticas (${state.automations.length})` },
            {
              value: 'jobs',
              label: `Executor em Lotes (job_runs) & Stop All (${state.jobRuns.length})`,
            },
          ]}
        />

        {tab === 'agents' && (
          <SegmentedControl
            ariaLabel="Filtrar agentes por categoria"
            value={catFilter}
            onChange={(v) => setCatFilter(v as 'all' | AgentCategory)}
            options={[
              { value: 'all', label: 'Todas Categorias' },
              ...AGENT_CATEGORIES.map((c) => ({ value: c, label: c })),
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
            Dispensar
          </button>
        </div>
      )}

      {tab === 'agents' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {visibleAgents.map((agent) => (
            <SurfacePanel
              key={agent.id}
              className="flex flex-col justify-between hover:border-[#315FEA]/50"
            >
              <div>
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]">
                      {agent.category} · Autonomia Nível {agent.autonomyLevel}/4 · Limite{' '}
                      {agent.limits.maxActionsPerDay}/dia
                    </div>
                    <h2 className="mt-0.5 font-display text-base font-semibold">
                      {agent.name}
                    </h2>
                  </div>
                  <StatusLabel status={agent.state} />
                </div>

                <p className="mt-2.5 text-xs text-[#525B68] dark:text-[#AEB7C2] leading-relaxed">
                  {agent.responsibility}
                </p>

                {agent.lastError && (
                  <p className="mt-2.5 text-xs text-rose-600 dark:text-rose-400">
                    Erro: {agent.lastError}
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
                  {AUTONOMY_LEVEL_LABELS[agent.autonomyLevel]}
                </span>
                <div className="flex items-center gap-3">
                  <button
                    type="button"
                    disabled={isHalted}
                    onClick={() => toggleAgentRun(agent.id)}
                    className="font-medium text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3] disabled:opacity-40"
                  >
                    {agent.state === 'Running' ? 'Pausar' : 'Executar Demo'}
                  </button>
                  <button
                    type="button"
                    onClick={() => navigate('automations', { automationId: agent.id })}
                    className="font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
                  >
                    Detalhes & Limites
                  </button>
                </div>
              </div>
            </SurfacePanel>
          ))}
        </div>
      ) : (
        <div className="space-y-5">
          {/* system_controls & CLI Batch Runner */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
            <SurfacePanel className="lg:col-span-5 space-y-4">
              <div className="flex items-center justify-between gap-2">
                <h2 className="font-display text-sm font-semibold">
                  Estado de Controle (system_controls)
                </h2>
                <StatusLabel status={state.systemControl.state} />
              </div>

              <dl className="grid grid-cols-2 gap-3 text-xs">
                <div>
                  <dt className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Último Actor</dt>
                  <dd className="font-medium mt-0.5">{state.systemControl.actor}</dd>
                </div>
                <div>
                  <dt className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Atualizado em</dt>
                  <dd className="font-mono tabular-nums mt-0.5">
                    {state.systemControl.updatedAt.slice(0, 16).replace('T', ' ')}
                  </dd>
                </div>
                <div className="col-span-2">
                  <dt className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    Motivo Registrado
                  </dt>
                  <dd className="mt-0.5 text-[#101216] dark:text-[#F1F2F3]">
                    {state.systemControl.reason}
                  </dd>
                </div>
              </dl>

              {!resumeGate.allowed && (
                <div className="p-3 rounded bg-amber-500/10 border border-amber-500/30 text-xs text-amber-800 dark:text-amber-200 space-y-2">
                  <div className="font-semibold">Trava de Retomada (Lote 8)</div>
                  <p>{resumeGate.reason}</p>
                  <button
                    type="button"
                    onClick={handleReconcile}
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded bg-amber-600 text-white font-medium hover:bg-amber-700"
                  >
                    <RefreshCw className="w-3.5 h-3.5" aria-hidden="true" />
                    <span>Executar jobs reconcile</span>
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
                    autopilot control resume
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={() => openControlModal('halt')}
                    className="px-3.5 py-2 rounded bg-rose-600 text-white text-xs font-medium hover:bg-rose-700"
                  >
                    autopilot control halt
                  </button>
                )}
              </div>
            </SurfacePanel>

            <SurfacePanel className="lg:col-span-7 space-y-4">
              <div className="flex items-center gap-2">
                <Terminal className="w-4 h-4 text-[#315FEA]" aria-hidden="true" />
                <h2 className="font-display text-sm font-semibold">
                  Executor em Lotes CLI (dry-run padrão · --commit fail-closed)
                </h2>
              </div>
              <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                Simule a CLI Python do núcleo <span className="font-mono">affiliate-autopilot</span>.
                Execuções <span className="font-mono">--commit</span> falham fechadas quando{' '}
                <span className="font-mono">system_controls = HALTED</span> e o comando{' '}
                <span className="font-mono">jobs reconcile</span> resolve execuções órfãs antes do{' '}
                <span className="font-mono">resume</span>.
              </p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 text-xs">
                <button
                  type="button"
                  onClick={() => handleRunCommand('dry-run', 'pipeline.run')}
                  className="px-3.5 py-2.5 rounded border border-black/15 dark:border-white/15 text-left hover:border-[#315FEA]"
                >
                  <div className="font-mono font-semibold text-[#101216] dark:text-[#F1F2F3]">
                    autopilot pipeline.run --dry-run
                  </div>
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mt-0.5">
                    Modo padrão seguro sem gravação persistente
                  </div>
                </button>

                <button
                  type="button"
                  onClick={() => handleRunCommand('commit', 'pipeline.run')}
                  className="px-3.5 py-2.5 rounded border border-black/15 dark:border-white/15 text-left hover:border-[#315FEA]"
                >
                  <div className="font-mono font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                    autopilot pipeline.run --commit
                  </div>
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mt-0.5">
                    Bloqueado fail-closed se HALTED
                  </div>
                </button>

                <button
                  type="button"
                  onClick={() => handleRunCommand('commit', 'products.score')}
                  className="px-3.5 py-2.5 rounded border border-black/15 dark:border-white/15 text-left hover:border-[#315FEA]"
                >
                  <div className="font-mono font-semibold text-[#101216] dark:text-[#F1F2F3]">
                    autopilot products.score --commit
                  </div>
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mt-0.5">
                    Recalcula score-6.1 (v0-hipotese) por moeda
                  </div>
                </button>

                <button
                  type="button"
                  onClick={handleReconcile}
                  className="px-3.5 py-2.5 rounded border border-amber-500/40 bg-amber-500/8 text-left hover:border-amber-500"
                >
                  <div className="font-mono font-semibold text-amber-800 dark:text-amber-300">
                    autopilot jobs reconcile
                  </div>
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mt-0.5">
                    Marca execuções running órfãs (&gt;30m) como failed
                  </div>
                </button>
              </div>
            </SurfacePanel>
          </div>

          {/* job_runs ledger table */}
          <SurfacePanel>
            <div className="flex items-center justify-between gap-3 mb-4">
              <h2 className="font-display text-sm font-semibold">
                Histórico de Execuções em Lote (job_runs)
              </h2>
              <span className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                {state.jobRuns.length} registros
              </span>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    <th className="py-2 pr-4">ID</th>
                    <th className="py-2 pr-4">Task</th>
                    <th className="py-2 pr-4">Modo</th>
                    <th className="py-2 pr-4">Início</th>
                    <th className="py-2 pr-4 text-right">Registros</th>
                    <th className="py-2 pr-4">Status</th>
                    <th className="py-2">Resumo / Erro</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                  {state.jobRuns.map((job) => (
                    <tr key={job.id}>
                      <td className="py-2.5 pr-4 font-mono tabular-nums">#{job.id}</td>
                      <td className="py-2.5 pr-4 font-mono font-medium">{job.taskName}</td>
                      <td className="py-2.5 pr-4 font-mono whitespace-nowrap text-[#525B68] dark:text-[#AEB7C2]">
                        {job.mode}
                      </td>
                      <td className="py-2.5 pr-4 font-mono tabular-nums whitespace-nowrap text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {job.startedAt.slice(0, 16).replace('T', ' ')}
                      </td>
                      <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                        {job.recordsProcessed}
                      </td>
                      <td className="py-2.5 pr-4">
                        <StatusLabel status={job.status} />
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
                  ))}
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
            ? 'Acionar Stop All (autopilot control halt)'
            : 'Retomar Sistema (autopilot control resume)'
        }
        subtitle={
          controlModal === 'halt'
            ? 'Bloqueia --commit e publicações externas imediatamente (fail-closed).'
            : 'Exige actor, motivo e zero job_runs em estado running ou unknown.'
        }
        onClose={() => setControlModal(null)}
      >
        <form onSubmit={handleControlSubmit} className="space-y-4 text-xs">
          {controlModal === 'resume' && !resumeGate.allowed && (
            <div className="p-3 rounded bg-amber-500/12 border border-amber-500/35 text-amber-800 dark:text-amber-200 space-y-2">
              <div className="font-semibold">Resume Bloqueado por Job Órfão</div>
              <p>{resumeGate.reason}</p>
              <button
                type="button"
                onClick={() => {
                  handleReconcile();
                  setControlError('');
                }}
                className="px-3 py-1.5 rounded bg-amber-600 text-white font-medium hover:bg-amber-700"
              >
                Executar jobs reconcile
              </button>
            </div>
          )}

          <div>
            <label htmlFor="auto-ctrl-actor" className="block font-medium mb-1">
              Actor (Responsável) *
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
              Motivo (audit_log) *
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
                  ? 'Ex.: Verificação manual antes de liberar próximo lote.'
                  : 'Ex.: Jobs reconciliados e checks pré-envio validados.'
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
              Cancelar
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
                ? 'Confirmar Stop All (HALTED)'
                : 'Confirmar Retomada (ACTIVE)'}
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
