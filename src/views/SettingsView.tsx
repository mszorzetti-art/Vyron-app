import React, { useState } from 'react';
import { OctagonAlert, RefreshCw, RotateCcw } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { CurrencyCode, ThemeMode } from '../types/vyron';
import { canResumeSystemControl } from '../utils/vyronRules';
import {
  PageHeader,
  SegmentedControl,
  StatusLabel,
  SurfacePanel,
} from '../components/ui';

const ARCHITECTURE_BLOCKS = [
  {
    group: 'Implementado no Repositório (main · Lotes 1–9)',
    status: 'Active',
    items: [
      'Blocos 0–4: Fundação SQLAlchemy + Alembic, Catálogo Compartilhado (platform, external_id), is_test isolado e score-6.1 (v0-hipotese) por moeda sem FX mixing.',
      'Bloco 5 (Lotes 7–9): Executor em lotes (job_runs), --dry-run padrão, --commit fail-closed, jobs reconcile para órfãos, system_controls (ACTIVE/HALTED) e audit_log append-only.',
    ],
  },
  {
    group: 'Em Integração (Fase A Operacional)',
    status: 'In Review',
    items: [
      'Bloco 6: Content Studio (Brief -> Draft -> In Review -> Approved -> Published/Rejected), dossiê com níveis de fonte (1–4) e histórico de rejeição estruturado.',
      'Bloco 7: Autorização individual por hash SHA-256 com herança zero, expiração explícita e 6 travas obrigatórias pré-envio.',
    ],
  },
  {
    group: 'Planejado (Próximos Ciclos)',
    status: 'Draft',
    items: [
      'Blocos 8–10: Conectores reais de canais (YouTube/Instagram/TikTok/Web), atribuição real de cliques/conversões e conciliação bancária/FX automática.',
      'Blocos 11–12 & Fase F: Compliance Intelligence regional (BR/FR-UE), reclassificação A/B/C e modelos calibrados de ML após base empírica auditada.',
    ],
  },
];

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

  const [controlFeedback, setControlFeedback] = useState<{
    ok: boolean;
    message: string;
  } | null>(null);

  const s = state.settings;
  const isHalted = state.systemControl.state === 'HALTED';
  const resumeGate = canResumeSystemControl(state.jobRuns);

  const handleHalt = () => {
    const count = haltSystemControl(
      s.ownerName,
      'Stop All acionado pelo proprietário via Settings & Governança.'
    );
    setControlFeedback({
      ok: true,
      message: `system_controls definido como HALTED (${count} agente(s) interrompido(s)).`,
    });
  };

  const handleResume = () => {
    const res = resumeSystemControl(
      s.ownerName,
      'Retomada solicitada pelo proprietário via Settings & Governança.'
    );
    if (!res.ok) {
      setControlFeedback({
        ok: false,
        message: res.reason ?? 'Retomada bloqueada enquanto houver job_runs pendentes.',
      });
      return;
    }
    setControlFeedback({
      ok: true,
      message: 'system_controls retomado para ACTIVE.',
    });
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Settings & Governança"
        subtitle="Preferências do proprietário, switches de publicação (Fase A/B), validade de hash/evidência, matriz RISK_REGISTER e estado dos blocos."
        actions={
          <button
            type="button"
            onClick={resetDemoData}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-medium rounded-md border border-black/15 dark:border-white/15 hover:border-[#315FEA] whitespace-nowrap"
          >
            <RotateCcw className="w-3.5 h-3.5" aria-hidden="true" />
            <span>Restaurar Dados Demo</span>
          </button>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Owner Profile & Preferences */}
        <SurfacePanel className="lg:col-span-6 space-y-5">
          <h2 className="font-display text-sm font-semibold">
            Perfil do Proprietário & Preferências
          </h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
            <div>
              <label htmlFor="owner-name" className="block font-medium mb-1">
                Nome do Proprietário (Actor)
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
                E-mail Operacional
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
                <div className="font-medium">Tema da Interface</div>
                <div className="text-[#525B68] dark:text-[#AEB7C2]">
                  Obsidian Black (#101216) ou Cool White (#F1F2F3)
                </div>
              </div>
              <SegmentedControl
                ariaLabel="Selecionar tema"
                value={s.theme}
                onChange={(t) => setTheme(t as ThemeMode)}
                options={[
                  { value: 'dark', label: 'Obsidian Escuro' },
                  { value: 'light', label: 'Cool White Claro' },
                ]}
              />
            </div>

            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <div className="font-medium">Moeda Base Consolidada</div>
                <div className="text-[#525B68] dark:text-[#AEB7C2]">
                  Overview/Finanças (ranking de produtos permanece por moeda nativa)
                </div>
              </div>
              <SegmentedControl
                ariaLabel="Selecionar moeda base"
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
                <div className="font-medium">Idioma da Interface</div>
                <div className="text-[#525B68] dark:text-[#AEB7C2]">
                  Escopo operacional padrão
                </div>
              </div>
              <SegmentedControl
                ariaLabel="Selecionar idioma"
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
          <h2 className="font-display text-sm font-semibold">
            Políticas de Publicação, Validade & Segurança
          </h2>

          <div className="space-y-2.5 text-xs">
            <label className="flex items-center justify-between gap-3 p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <span>
                <span className="font-medium block">PUBLISHING_ENABLED (Switch Global)</span>
                <span className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  Desligado por padrão em modo seguro (bloqueia Check #6 pré-envio)
                </span>
              </span>
              <input
                type="checkbox"
                checked={state.systemControl.publishingEnabled}
                onChange={(e) =>
                  toggleSystemFlags({ publishingEnabled: e.target.checked })
                }
                className="accent-[#315FEA]"
              />
            </label>

            <label className="flex items-center justify-between gap-3 p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <span>
                <span className="font-medium block">Permitir Visibilidade Pública (Fase B)</span>
                <span className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  Na Fase A, apenas peças private/unlisted passam no Check #6
                </span>
              </span>
              <input
                type="checkbox"
                checked={state.systemControl.phaseBPublicAllowed}
                onChange={(e) =>
                  toggleSystemFlags({ phaseBPublicAllowed: e.target.checked })
                }
                className="accent-[#315FEA]"
              />
            </label>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-1">
              <div>
                <label htmlFor="auth-validity-hours" className="block font-medium mb-1">
                  Validade Padrão Hash (h)
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
                  Frescor de Evidência (h)
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
                  Teto Diário Global (BRL)
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
                      message: `${count} job(s) órfão(s) reconciliado(s). Retomada desbloqueada.`,
                    });
                  }}
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded bg-amber-600 text-white font-medium hover:bg-amber-700"
                >
                  <RefreshCw className="w-3 h-3" aria-hidden="true" />
                  <span>Executar jobs reconcile</span>
                </button>
              )}
            </div>
          )}

          <div className="pt-3 border-t border-black/10 dark:border-white/10 flex flex-wrap items-center justify-between gap-3 text-xs">
            <div>
              <div className="font-semibold text-rose-700 dark:text-rose-400">
                Controle de Emergência (system_controls = {state.systemControl.state})
              </div>
              <p className="text-[#525B68] dark:text-[#AEB7C2]">
                Interrompe agentes e bloqueia --commit / envios até reconciliação limpa.
              </p>
            </div>
            {isHalted ? (
              <button
                type="button"
                onClick={handleResume}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded bg-emerald-600 text-white font-medium hover:bg-emerald-700 whitespace-nowrap"
              >
                Liberar Autonomia (ACTIVE)
              </button>
            ) : (
              <button
                type="button"
                onClick={handleHalt}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded bg-rose-600 text-white font-medium hover:bg-rose-700 whitespace-nowrap"
              >
                <OctagonAlert className="w-3.5 h-3.5" aria-hidden="true" />
                <span>Acionar Stop All</span>
              </button>
            )}
          </div>
        </SurfacePanel>
      </div>

      {/* Roadmap de Blocos 0-12 & Fases A/B */}
      <SurfacePanel className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div>
            <h2 className="font-display text-sm font-semibold">
              Roadmap de Arquitetura (Blocos 0–12 & Fases A/B)
            </h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
              Separação explícita entre núcleo implementado em <span className="font-mono">main</span>, módulos em integração e ciclos futuros.
            </p>
          </div>
          <span className="font-mono text-[11px] text-[#315FEA] dark:text-[#7FA0FF]">
            {state.systemControl.phaseBPublicAllowed ? 'Fase B · Pública' : 'Fase A · Não Pública'}
          </span>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {ARCHITECTURE_BLOCKS.map((blk) => (
            <div
              key={blk.group}
              className="p-4 rounded-md bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 space-y-2.5 text-xs"
            >
              <div className="flex items-center justify-between gap-2">
                <span className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  {blk.group}
                </span>
                <StatusLabel status={blk.status} />
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

      {/* RISK_REGISTER Matrix */}
      <SurfacePanel className="space-y-3">
        <div>
          <h2 className="font-display text-sm font-semibold">
            Matriz de Riscos (RISK_REGISTER) & Controles Pendentes
          </h2>
          <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
            Itens P0, P1 e P2 auditados para governança de publicação, dados financeiros, atribuição e infraestrutura.
          </p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                <th className="py-2 pr-4">ID</th>
                <th className="py-2 pr-4">Prioridade</th>
                <th className="py-2 pr-4">Risco</th>
                <th className="py-2 pr-4">Controle / Mitigação</th>
                <th className="py-2 text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
              {state.risks.map((risk) => (
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
                    <StatusLabel status={risk.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </SurfacePanel>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Notification Preferences */}
        <SurfacePanel className="lg:col-span-5 space-y-3">
          <h2 className="font-display text-sm font-semibold">
            Preferências de Notificação
          </h2>
          <div className="space-y-2 text-xs">
            {(
              [
                ['financialAlerts', 'Alertas financeiros e divergências'],
                ['commissionsReceived', 'Comissões recebidas em caixa'],
                ['opportunities', 'Novas oportunidades detectadas'],
                ['pendingApprovals', 'Aprovações pendentes'],
                ['automationFailures', 'Falhas de automação'],
                ['operationalEvents', 'Eventos operacionais gerais'],
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
            Registro de Integrações (Estado Demonstrativo)
          </h2>
          <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] mb-4">
            Nenhuma credencial real ou chamada externa está ativa nesta fase de protótipo.
          </p>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">Integração</th>
                  <th className="py-2 pr-4">Categoria</th>
                  <th className="py-2 pr-4">Última Verificação</th>
                  <th className="py-2 text-right">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {s.integrations.map((int) => (
                  <tr key={int.id}>
                    <td className="py-2.5 pr-4 font-medium">{int.name}</td>
                    <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2]">
                      {int.category}
                    </td>
                    <td className="py-2.5 pr-4 font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {int.lastChecked}
                    </td>
                    <td className="py-2.5 text-right">
                      <StatusLabel status={int.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </SurfacePanel>
      </div>
    </div>
  );
};
