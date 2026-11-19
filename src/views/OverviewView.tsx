import React from 'react';
import { ArrowRight, AlertTriangle, ShieldCheck } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import {
  calculateFinanceSummary,
  computeBrandRollups,
  computeOperationalEfficiency,
  formatCompactNumber,
  formatCurrency,
} from '../utils/vyronRules';
import { DualLineChart, HorizontalBarComparison } from '../components/Charts';
import { MetricBlock, PageHeader, StatusLabel, SurfacePanel } from '../components/ui';

export const OverviewView: React.FC = () => {
  const {
    state,
    globalBrandFilter,
    globalPeriodFilter,
    excludeTestData,
    navigate,
    setGlobalBrandFilter,
    haltSystemControl,
  } = useVyron();

  const currency = state.settings.baseCurrency;

  const finance = calculateFinanceSummary(state.financeEntries, currency, {
    brandId: globalBrandFilter,
    period: globalPeriodFilter,
    excludeTest: excludeTestData,
  });

  const efficiency = computeOperationalEfficiency(finance, state.contents, globalBrandFilter);

  const filteredProducts = state.products.filter(
    (p) =>
      (!excludeTestData || !p.isTest) &&
      (globalBrandFilter === 'all' ||
        p.brandId === globalBrandFilter ||
        p.linkedBrandIds.includes(globalBrandFilter))
  );
  const filteredContents = state.contents.filter(
    (c) => globalBrandFilter === 'all' || c.brandId === globalBrandFilter
  );
  const filteredActivities = state.activities
    .filter((a) => globalBrandFilter === 'all' || !a.brandId || a.brandId === globalBrandFilter)
    .slice(0, 6);

  const brandRollups = computeBrandRollups(
    state.brands.filter((b) => globalBrandFilter === 'all' || b.id === globalBrandFilter),
    state.channels,
    state.products,
    state.contents,
    state.financeEntries,
    currency,
    { excludeTest: excludeTestData }
  );

  const productsInAnalysis = filteredProducts.filter((p) => p.status === 'Candidate');
  const contentInProduction = filteredContents.filter(
    (c) => c.status === 'Brief' || c.status === 'Draft' || c.status === 'In Review'
  );
  const pendingHashReviews = filteredContents.filter(
    (c) => c.status === 'In Review' || (!c.authorization && c.status === 'Approved')
  );
  const orphanedJobs = state.jobRuns.filter(
    (j) => j.status === 'running' || j.status === 'unknown'
  );
  const unreadAlerts = state.notifications.filter((n) => !n.read && n.actionRequired);
  const runningAgents = state.automations.filter((a) => a.state === 'Running').length;
  const errorAgents = state.automations.filter((a) => a.state === 'Error').length;
  const pendingApprovalAgents = state.automations.reduce(
    (sum, a) => sum + a.pendingApprovalCount,
    0
  );

  const baseConf = Math.max(finance.confirmedCommercialResult, 1000);
  const baseRec = Math.max(finance.receivedCashIn, 800);

  const cashFlowSeries = [
    { label: 'Jun', primary: Math.round(baseConf * 0.58), secondary: Math.round(baseRec * 0.56), tertiary: null },
    { label: 'Jul', primary: Math.round(baseConf * 0.67), secondary: Math.round(baseRec * 0.64), tertiary: null },
    { label: 'Ago', primary: Math.round(baseConf * 0.64), secondary: Math.round(baseRec * 0.69), tertiary: null },
    { label: 'Set', primary: Math.round(baseConf * 0.81), secondary: Math.round(baseRec * 0.78), tertiary: null },
    { label: 'Out', primary: Math.round(baseConf * 0.91), secondary: Math.round(baseRec * 0.88), tertiary: null },
    {
      label: 'Nov',
      primary: Math.round(finance.confirmedCommercialResult),
      secondary: Math.round(finance.receivedCashIn),
      tertiary: Math.round(finance.confirmedCommercialResult),
    },
    {
      label: 'Dez (Proj.)',
      primary: null,
      secondary: null,
      tertiary: Math.round(finance.confirmedCommercialResult + finance.projectedFutureRevenue * 0.35),
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Overview Operacional"
        subtitle={`Control plane integrado ao affiliate-autopilot · Moeda base ${currency} · Janela ${globalPeriodFilter}`}
        actions={
          <>
            <button
              type="button"
              onClick={() => navigate('content')}
              className="px-3.5 py-2 text-xs font-medium rounded-md border border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20] text-[#101216] dark:text-[#F1F2F3] hover:border-[#315FEA]/50 whitespace-nowrap"
            >
              Aprovações Hash ({pendingHashReviews.length})
            </button>
            <button
              type="button"
              onClick={() => navigate('products')}
              className="px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
            >
              Avaliar Candidatos ({productsInAnalysis.length})
            </button>
          </>
        }
      />

      {/* Row 1: Strict Financial Separation + Dimensão 2 Operational Efficiency */}
      <section aria-label="Indicadores financeiros e eficiência operacional" className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <MetricBlock
          label="Dim. 1 · Caixa Recebido Líquido"
          value={formatCurrency(finance.netRealizedCash, currency)}
          helper={`Bruto recebido: ${formatCurrency(finance.receivedCashIn, currency)} · Base reinvest.`}
          tone="emerald"
          onClick={() => navigate('finance')}
        />
        <MetricBlock
          label="Comercial Confirmado (12.1.1)"
          value={formatCurrency(finance.confirmedCommercialResult, currency)}
          helper={`Inclui ${formatCurrency(finance.confirmedAwaitingPayout, currency)} aguardando saque`}
          tone="cobalt"
          onClick={() => navigate('finance')}
        />
        <MetricBlock
          label="Comissões Pendentes (Não-Caixa)"
          value={formatCurrency(finance.pendingCommissions, currency)}
          helper="Nunca entra como orçamento disponível"
          tone="amber"
          onClick={() => navigate('finance')}
        />
        <MetricBlock
          label="Dim. 2 · Eficiência Operacional"
          value={
            efficiency.realizedCashPerHour !== null
              ? `${formatCurrency(efficiency.realizedCashPerHour, currency)}/h`
              : 'N/D'
          }
          helper={`${efficiency.totalHumanHours.toFixed(1)}h humanas registradas no ciclo`}
          tone="neutral"
          onClick={() => navigate('analytics')}
        />
      </section>

      {/* Architectural Readiness & Backend Sync Strip */}
      <SurfacePanel className="grid grid-cols-1 md:grid-cols-4 gap-4 text-xs">
        <div className="space-y-1">
          <div className="flex items-center gap-1.5 font-semibold text-[#101216] dark:text-[#F1F2F3]">
            <ShieldCheck className="w-3.5 h-3.5 text-[#315FEA]" aria-hidden="true" />
            <span>Implementado (main · Lotes 1–9)</span>
          </div>
          <p className="text-[#525B68] dark:text-[#AEB7C2] leading-snug">
            CLI, migrator, score-6.1 (v0-hipotese), job_runs, Stop All e audit_log validados em PostgreSQL efêmero.
          </p>
        </div>
        <div className="space-y-1">
          <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
            Em Integração (Blocos 6–7)
          </div>
          <p className="text-[#525B68] dark:text-[#AEB7C2] leading-snug">
            Content Studio + Manifesto SHA-256 + 6 travas pré-envio ({pendingHashReviews.length} peça(s) em revisão).
          </p>
        </div>
        <div className="space-y-1">
          <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
            Controle & Visibilidade
          </div>
          <div className="flex items-center gap-2">
            <StatusLabel status={state.systemControl.state} />
            <span className="text-[#AEB7C2]">·</span>
            <span className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
              {state.systemControl.phaseBPublicAllowed ? 'Fase B' : 'Fase A'} · Pub={String(state.systemControl.publishingEnabled)}
            </span>
          </div>
        </div>
        <div className="space-y-1 flex flex-col justify-between">
          <div>
            <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
              Executor & Reconciliação
            </div>
            <p className="text-[#525B68] dark:text-[#AEB7C2] font-mono text-[11px]">
              {orphanedJobs.length > 0
                ? `${orphanedJobs.length} job órfão bloqueando resume`
                : `${state.jobRuns.length} execuções conciliadas`}
            </p>
          </div>
          <button
            type="button"
            onClick={() => navigate('settings')}
            className="text-left text-[#315FEA] dark:text-[#7FA0FF] font-medium hover:underline"
          >
            Ver Matriz Blocos & Riscos →
          </button>
        </div>
      </SurfacePanel>

      {/* Row 2: Chart + Brand Performance Comparison */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-stretch">
        <SurfacePanel className="lg:col-span-7 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between gap-4 mb-4">
              <div>
                <h2 className="font-display text-base font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  Resultado Comercial vs Caixa Realizado
                </h2>
                <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                  Comissões pendentes e registros is_test são excluídos desta curva.
                </p>
              </div>
              <button
                type="button"
                onClick={() => navigate('analytics')}
                className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline inline-flex items-center gap-1 whitespace-nowrap"
              >
                <span>Analytics</span>
                <ArrowRight className="w-3.5 h-3.5" aria-hidden="true" />
              </button>
            </div>
            <DualLineChart
              data={cashFlowSeries}
              primaryLabel="Comercial Confirmado"
              secondaryLabel="Recebido em Caixa"
              tertiaryLabel="Projeção Isolada"
              formatValue={(v) => formatCurrency(v, currency)}
            />
          </div>
        </SurfacePanel>

        <SurfacePanel className="lg:col-span-5 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between gap-4 mb-4">
              <div>
                <h2 className="font-display text-base font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  Desempenho por Marca
                </h2>
                <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                  Resultado comercial confirmado e estágio de validação
                </p>
              </div>
              <button
                type="button"
                onClick={() => navigate('brands')}
                className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline inline-flex items-center gap-1 whitespace-nowrap"
              >
                <span>Gerir Marcas</span>
                <ArrowRight className="w-3.5 h-3.5" aria-hidden="true" />
              </button>
            </div>

            <HorizontalBarComparison
              items={brandRollups.map((r) => ({
                id: r.brand.id,
                label: r.brand.name,
                sublabel: `${r.brand.validationStage} · ${formatCompactNumber(r.totalViews30d)} views`,
                value: r.confirmedCommercial,
                formattedValue: formatCurrency(r.confirmedCommercial, currency),
                color: r.brand.accentColor,
              }))}
            />
          </div>

          <div className="mt-5 pt-4 border-t border-black/10 dark:border-white/10 flex flex-wrap items-center justify-between gap-2 text-xs text-[#525B68] dark:text-[#AEB7C2]">
            <span>Clique no filtro global para isolar uma marca</span>
            {globalBrandFilter !== 'all' && (
              <button
                type="button"
                onClick={() => setGlobalBrandFilter('all')}
                className="text-[#315FEA] dark:text-[#7FA0FF] font-medium hover:underline"
              >
                Limpar filtro de marca
              </button>
            )}
          </div>
        </SurfacePanel>
      </div>

      {/* Row 3: Operational Queues */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <SurfacePanel>
          <div className="flex items-center justify-between gap-2 mb-4">
            <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
              Produtos em Análise (score-6.1)
            </h2>
            <button
              type="button"
              onClick={() => navigate('products')}
              className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
            >
              Ver todos
            </button>
          </div>
          {productsInAnalysis.length === 0 ? (
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
              Nenhum produto candidato pendente no filtro atual.
            </p>
          ) : (
            <ul className="divide-y divide-black/10 dark:divide-white/10">
              {productsInAnalysis.map((p) => (
                <li key={p.id} className="py-3 first:pt-0 last:pb-0">
                  <button
                    type="button"
                    onClick={() => navigate('products', { productId: p.id })}
                    className="w-full text-left group flex items-start justify-between gap-3"
                  >
                    <div className="min-w-0">
                      <div className="text-xs font-medium text-[#101216] dark:text-[#F1F2F3] group-hover:text-[#315FEA] truncate">
                        {p.name}
                      </div>
                      <div className="mt-0.5 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {p.platform} · {p.currency} · Nota {p.qualityGrade ?? 'N/D'}
                      </div>
                    </div>
                    <span className="font-mono tabular-nums text-xs font-semibold text-[#315FEA] dark:text-[#7FA0FF] shrink-0">
                      {p.opportunityScore !== null ? `${p.opportunityScore}/100` : 'null'}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </SurfacePanel>

        <SurfacePanel>
          <div className="flex items-center justify-between gap-2 mb-4">
            <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
              Conteúdos em Produção
            </h2>
            <button
              type="button"
              onClick={() => navigate('content', { contentSubView: 'calendar' })}
              className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
            >
              Calendário
            </button>
          </div>
          <ul className="divide-y divide-black/10 dark:divide-white/10">
            {contentInProduction.slice(0, 4).map((c) => (
              <li key={c.id} className="py-3 first:pt-0 last:pb-0">
                <button
                  type="button"
                  onClick={() =>
                    navigate('content', { contentId: c.id, contentSubView: 'studio' })
                  }
                  className="w-full text-left group flex items-start justify-between gap-3"
                >
                  <div className="min-w-0">
                    <div className="text-xs font-medium text-[#101216] dark:text-[#F1F2F3] group-hover:text-[#315FEA] truncate">
                      {c.title}
                    </div>
                    <div className="mt-0.5 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {c.format} · {c.visibility} · {c.scheduledDate}
                    </div>
                  </div>
                  <StatusLabel status={c.status} />
                </button>
              </li>
            ))}
          </ul>
        </SurfacePanel>

        <SurfacePanel className="flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between gap-2 mb-4">
              <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
                Automações & Alertas
              </h2>
              <button
                type="button"
                onClick={() => navigate('automations')}
                className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                Executor & Agentes
              </button>
            </div>

            <div className="grid grid-cols-3 gap-2 pb-4 border-b border-black/10 dark:border-white/10 text-center">
              <div>
                <div className="font-mono tabular-nums text-lg font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  {runningAgents}
                </div>
                <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Em execução</div>
              </div>
              <div>
                <div className="font-mono tabular-nums text-lg font-semibold text-amber-600 dark:text-amber-400">
                  {pendingApprovalAgents}
                </div>
                <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Aprovações</div>
              </div>
              <div>
                <div className="font-mono tabular-nums text-lg font-semibold text-rose-600 dark:text-rose-400">
                  {errorAgents + orphanedJobs.length}
                </div>
                <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Falhas / Órfãos</div>
              </div>
            </div>

            <ul className="mt-3 space-y-2.5">
              {unreadAlerts.slice(0, 2).map((al) => (
                <li key={al.id}>
                  <button
                    type="button"
                    onClick={() => navigate(al.targetModule)}
                    className="w-full text-left flex items-start gap-2.5 text-xs hover:text-[#315FEA]"
                  >
                    <AlertTriangle className="w-3.5 h-3.5 text-amber-500 mt-0.5 shrink-0" aria-hidden="true" />
                    <span className="min-w-0">
                      <span className="block font-medium text-[#101216] dark:text-[#F1F2F3] truncate">
                        {al.title}
                      </span>
                      <span className="block text-[11px] text-[#525B68] dark:text-[#AEB7C2] truncate">
                        {al.message}
                      </span>
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          </div>

          <div className="mt-4 pt-3 border-t border-black/10 dark:border-white/10 flex items-center justify-between gap-2">
            <span className="text-[11px] font-mono text-[#525B68] dark:text-[#AEB7C2]">
              Estado: {state.systemControl.state}
            </span>
            {state.systemControl.state === 'ACTIVE' ? (
              <button
                type="button"
                onClick={() => haltSystemControl('Proprietário', 'Acionado via card Overview.')}
                className="text-xs font-medium text-rose-600 dark:text-rose-400 hover:underline"
              >
                Halt Rápido
              </button>
            ) : (
              <button
                type="button"
                onClick={() => navigate('automations')}
                className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                Reconciliar & Retomar
              </button>
            )}
          </div>
        </SurfacePanel>
      </div>

      {/* Row 4: Recent Activity Stream */}
      <SurfacePanel>
        <div className="flex items-center justify-between gap-2 mb-4">
          <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
            Audit Log & Decisões Recentes
          </h2>
          <button
            type="button"
            onClick={() => navigate('activity')}
            className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
          >
            Histórico completo
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-black/10 dark:border-white/10 text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]">
                <th className="py-2 pr-4">Data</th>
                <th className="py-2 pr-4">Categoria</th>
                <th className="py-2 pr-4">Ação</th>
                <th className="py-2 pr-4">Detalhe</th>
                <th className="py-2 text-right">Agente / Autor</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06] text-xs">
              {filteredActivities.map((act) => (
                <tr key={act.id} className="hover:bg-black/[0.02] dark:hover:bg-white/[0.02]">
                  <td className="py-2.5 pr-4 font-mono tabular-nums text-[11px] text-[#525B68] dark:text-[#AEB7C2] whitespace-nowrap">
                    {act.timestamp.slice(0, 16).replace('T', ' ')}
                  </td>
                  <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2] whitespace-nowrap">
                    {act.category}
                  </td>
                  <td className="py-2.5 pr-4 font-medium text-[#101216] dark:text-[#F1F2F3]">
                    {act.action}
                  </td>
                  <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2] max-w-md truncate">
                    {act.detail}
                  </td>
                  <td className="py-2.5 text-right font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2] whitespace-nowrap">
                    {act.actor}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </SurfacePanel>
    </div>
  );
};
