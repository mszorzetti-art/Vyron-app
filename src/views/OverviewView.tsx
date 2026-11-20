import React, { useEffect, useState } from 'react';
import { ArrowRight, AlertTriangle, ShieldCheck, X } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import {
  calculateFinanceSummary,
  computeBrandRollups,
  computeOperationalEfficiency,
  convertCurrency,
} from '../utils/vyronRules';
import { ChartTimeRange, buildOverviewFinanceSeries } from '../utils/chartSeries';
import { useI18n } from '../i18n/useI18n';
import {
  labelActivityCategory,
  labelCommissionStage,
  labelContentFormat,
  labelContentStatus,
  labelContentVisibility,
  labelFinanceType,
  labelProductGradeBadge,
  labelSystemControlState,
  labelValidationStage,
} from '../i18n/domainLabels';
import {
  localizeActivity,
  localizeContentDisplay,
  localizeFinanceEntry,
  localizeNotification,
  localizeProduct,
} from '../i18n/seedTranslations';
import {
  ChartTimeframeToolbar,
  InteractiveComparisonChart,
  InteractiveSeriesConfig,
  InteractiveTimeSeriesChart,
  InteractiveTimeSeriesPoint,
} from '../components/Charts';
import { MetricBlock, PageHeader, SegmentedControl, StatusLabel, SurfacePanel } from '../components/ui';

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
  const { lang, t, fmtCurrency, fmtNumber, fmtCompact, fmtDate, fmtDateTime } = useI18n();

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

  const [chartRange, setChartRange] = useState<ChartTimeRange>(globalPeriodFilter);
  const [customStart, setCustomStart] = useState('2026-10-28');
  const [customEnd, setCustomEnd] = useState('2026-11-18');
  const [chartMode, setChartMode] = useState<'cumulative' | 'daily'>('cumulative');
  const [comparePrev, setComparePrev] = useState(false);
  const [selectedPointId, setSelectedPointId] = useState<string | null>(null);
  const [selectedBrandChartId, setSelectedBrandChartId] = useState<string | null>(null);

  useEffect(() => {
    setChartRange(globalPeriodFilter);
  }, [globalPeriodFilter]);

  const financeSeriesRes = buildOverviewFinanceSeries(state.financeEntries, currency, {
    brandId: globalBrandFilter,
    range: chartRange,
    customStart,
    customEnd,
    excludeTest: excludeTestData,
    includeProjection: true,
    mode: chartMode,
  });

  const formatShortDateLabel = (iso: string) => {
    const full = fmtDate(iso);
    return full.slice(0, 5);
  };

  const interactivePoints: InteractiveTimeSeriesPoint[] = financeSeriesRes.points.map((pt) => ({
    id: pt.id,
    label: pt.isProjection ? `${formatShortDateLabel(pt.date)} (${t('charts.projectionPrefix')})` : formatShortDateLabel(pt.date),
    fullDateLabel: fmtDate(pt.date),
    isProjection: pt.isProjection,
    values: {
      confirmed: pt.confirmedCommercial,
      received: pt.receivedCash,
      pending: pt.pendingCommissions,
      projection: pt.projection,
      ...(comparePrev && financeSeriesRes.hasPreviousData
        ? { previousConfirmed: pt.previousConfirmed }
        : {}),
    },
  }));

  const overviewSeriesConfig: InteractiveSeriesConfig[] = [
    { id: 'confirmed', label: t('overview.chart.primary'), color: '#315FEA', areaFill: true },
    { id: 'received', label: t('overview.chart.secondary'), color: '#10B981' },
    { id: 'pending', label: t('overview.chart.pending'), color: '#D97706' },
    {
      id: 'projection',
      label: t('overview.chart.tertiary'),
      color: '#AEB7C2',
      dashed: true,
      isProjection: true,
    },
    ...(comparePrev && financeSeriesRes.hasPreviousData
      ? [
          {
            id: 'previousConfirmed',
            label: t('charts.prevPeriodSeries'),
            color: '#7FA0FF',
            dashed: true,
          },
        ]
      : []),
  ];

  const selectedOverviewPoint = selectedPointId
    ? financeSeriesRes.points.find((p) => p.id === selectedPointId) ?? null
    : null;

  const selectedOverviewEntries = selectedOverviewPoint
    ? state.financeEntries
        .filter((e) => selectedOverviewPoint.entryIds.includes(e.id))
        .map((e) => localizeFinanceEntry(e, lang))
    : [];

  const selectedBrandRollup = selectedBrandChartId
    ? brandRollups.find((r) => r.brand.id === selectedBrandChartId) ?? null
    : null;

  const currPrefix = currency === 'BRL' ? 'R$' : currency === 'USD' ? '$' : '€';

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('overview.title')}
        subtitle={t('overview.subtitle', { currency, period: globalPeriodFilter })}
        actions={
          <>
            <button
              type="button"
              onClick={() => navigate('content')}
              className="px-3.5 py-2 text-xs font-medium rounded-md border border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20] text-[#101216] dark:text-[#F1F2F3] hover:border-[#315FEA]/50 whitespace-nowrap"
            >
              {t('overview.cta.hashApprovals', { count: pendingHashReviews.length })}
            </button>
            <button
              type="button"
              onClick={() => navigate('products')}
              className="px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
            >
              {t('overview.cta.evaluateCandidates', { count: productsInAnalysis.length })}
            </button>
          </>
        }
      />

      {/* Row 1: Strict Financial Separation + Operational Efficiency */}
      <section aria-label={t('overview.kpiSectionAria')} className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <MetricBlock
          label={t('overview.kpi.netCash')}
          value={fmtCurrency(finance.netRealizedCash, currency)}
          helper={t('overview.kpi.netCashHelper', {
            amount: fmtCurrency(finance.receivedCashIn, currency),
          })}
          tone="emerald"
          onClick={() => navigate('finance')}
        />
        <MetricBlock
          label={t('overview.kpi.confirmedCommercial')}
          value={fmtCurrency(finance.confirmedCommercialResult, currency)}
          helper={t('overview.kpi.confirmedHelper', {
            amount: fmtCurrency(finance.confirmedAwaitingPayout, currency),
          })}
          tone="cobalt"
          onClick={() => navigate('finance')}
        />
        <MetricBlock
          label={t('overview.kpi.pendingCommissions')}
          value={fmtCurrency(finance.pendingCommissions, currency)}
          helper={t('overview.kpi.pendingHelper')}
          tone="amber"
          onClick={() => navigate('finance')}
        />
        <MetricBlock
          label={t('overview.kpi.efficiency')}
          value={
            efficiency.realizedCashPerHour !== null
              ? `${fmtCurrency(efficiency.realizedCashPerHour, currency)}/h`
              : t('common.na')
          }
          helper={t('overview.kpi.efficiencyHelper', {
            hours: fmtNumber(efficiency.totalHumanHours, 1),
          })}
          tone="neutral"
          onClick={() => navigate('analytics')}
        />
      </section>

      {/* Architectural Readiness & Operational Strip */}
      <SurfacePanel className="grid grid-cols-1 md:grid-cols-4 gap-4 text-xs">
        <div className="space-y-1">
          <div className="flex items-center gap-1.5 font-semibold text-[#101216] dark:text-[#F1F2F3]">
            <ShieldCheck className="w-3.5 h-3.5 text-[#315FEA]" aria-hidden="true" />
            <span>{t('overview.readiness.implementedTitle')}</span>
          </div>
          <p className="text-[#525B68] dark:text-[#AEB7C2] leading-snug">
            {t('overview.readiness.implementedDesc')}
          </p>
        </div>
        <div className="space-y-1">
          <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
            {t('overview.readiness.integrationTitle')}
          </div>
          <p className="text-[#525B68] dark:text-[#AEB7C2] leading-snug">
            {t('overview.readiness.integrationDesc', { count: pendingHashReviews.length })}
          </p>
        </div>
        <div className="space-y-1.5">
          <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
            {t('overview.readiness.controlTitle')}
          </div>
          <div className="space-y-1">
            <div>
              <StatusLabel
                status={labelSystemControlState(state.systemControl.state, lang)}
                statusKey={state.systemControl.state}
              />
            </div>
            <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
              {state.systemControl.phaseBPublicAllowed
                ? t('common.publicOp')
                : t('common.privateEnv')}{' '}
              ·{' '}
              {state.systemControl.publishingEnabled
                ? t('overview.readiness.publishingOn')
                : t('overview.readiness.publishingOff')}
            </div>
          </div>
        </div>
        <div className="space-y-1 flex flex-col justify-between">
          <div>
            <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
              {t('overview.readiness.executorTitle')}
            </div>
            <p className="text-[#525B68] dark:text-[#AEB7C2] text-[11px]">
              {orphanedJobs.length > 0
                ? t('overview.readiness.orphanCount', { count: orphanedJobs.length })
                : t('overview.readiness.reconciledCount', { count: state.jobRuns.length })}
            </p>
          </div>
          <button
            type="button"
            onClick={() => navigate('settings')}
            className="text-left text-[#315FEA] dark:text-[#7FA0FF] font-medium hover:underline"
          >
            {t('overview.readiness.viewMatrix')}
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
                  {t('overview.chart.title')}
                </h2>
                <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                  {t('overview.chart.subtitle')}
                </p>
              </div>
              <button
                type="button"
                onClick={() => navigate('analytics')}
                className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline inline-flex items-center gap-1 whitespace-nowrap"
              >
                <span>{t('nav.analytics')}</span>
                <ArrowRight className="w-3.5 h-3.5" aria-hidden="true" />
              </button>
            </div>
            <ChartTimeframeToolbar
              range={chartRange}
              onRangeChange={(next) => {
                setChartRange(next);
                setSelectedPointId(null);
              }}
              customStart={customStart}
              customEnd={customEnd}
              onCustomStartChange={setCustomStart}
              onCustomEndChange={setCustomEnd}
              comparePrevious={comparePrev}
              onToggleComparePrevious={() => setComparePrev((v) => !v)}
              hasPreviousData={financeSeriesRes.hasPreviousData}
              coverageNote={t('charts.coverageNote')}
              extraControls={
                <SegmentedControl
                  ariaLabel={t('overview.chart.title')}
                  value={chartMode}
                  onChange={(v) => setChartMode(v as 'cumulative' | 'daily')}
                  options={[
                    { value: 'cumulative', label: t('overview.chart.modeCumulative') },
                    { value: 'daily', label: t('overview.chart.modeDaily') },
                  ]}
                />
              }
            />

            <InteractiveTimeSeriesChart
              points={interactivePoints}
              series={overviewSeriesConfig}
              formatValue={(v) => fmtCurrency(v, currency)}
              formatYAxis={(v) => `${currPrefix} ${fmtCompact(v)}`}
              ariaLabel={t('charts.timeSeriesAria', { label: t('overview.chart.title') })}
              selectedPointId={selectedPointId}
              onSelectPoint={(pt) => setSelectedPointId(pt?.id ?? null)}
            />

            {selectedOverviewPoint && (
              <div className="mt-4 p-3.5 rounded-md bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 space-y-2.5 text-xs">
                <div className="flex items-center justify-between gap-2">
                  <div>
                    <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                      {t('overview.chart.drillTitle', { date: fmtDate(selectedOverviewPoint.date) })}
                    </div>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {t('overview.chart.drillCount', { count: selectedOverviewEntries.length })}
                      {selectedOverviewPoint.isProjection
                        ? ` · ${t('overview.chart.drillProjectionNote')}`
                        : ''}
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setSelectedPointId(null)}
                    aria-label={t('charts.clearPin')}
                    className="p-1 rounded text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]"
                  >
                    <X className="w-3.5 h-3.5" aria-hidden="true" />
                  </button>
                </div>

                {selectedOverviewEntries.length === 0 ? (
                  <p className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    {t('overview.chart.drillEmpty')}
                  </p>
                ) : (
                  <ul className="divide-y divide-black/10 dark:divide-white/10">
                    {selectedOverviewEntries.map((entry) => {
                      const brand = state.brands.find((b) => b.id === entry.brandId);
                      const converted = convertCurrency(entry.amount, entry.currency, currency);
                      const isOutflow = entry.type === 'Expense' || entry.type === 'Reinvestment';
                      return (
                        <li key={entry.id} className="py-2 first:pt-0 last:pb-0 flex items-start justify-between gap-3">
                          <div className="min-w-0">
                            <div className="font-medium text-[#101216] dark:text-[#F1F2F3] truncate">
                              {entry.description}
                            </div>
                            <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] truncate">
                              {brand?.name ?? entry.brandId} · {entry.platform} ·{' '}
                              {labelFinanceType(entry.type, lang)} ·{' '}
                              {entry.isProjection
                                ? t('charts.projectionBadge')
                                : labelCommissionStage(entry.stage, lang)}
                            </div>
                          </div>
                          <div className="font-mono tabular-nums text-right shrink-0">
                            <div
                              className={
                                isOutflow
                                  ? 'text-rose-600 dark:text-rose-400 font-medium'
                                  : 'font-semibold text-[#101216] dark:text-[#F1F2F3]'
                              }
                            >
                              {isOutflow ? '-' : ''}
                              {fmtCurrency(converted, currency)}
                            </div>
                            {entry.currency !== currency && (
                              <div className="text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                                {fmtCurrency(entry.amount, entry.currency)}
                              </div>
                            )}
                          </div>
                        </li>
                      );
                    })}
                  </ul>
                )}
              </div>
            )}
          </div>
        </SurfacePanel>

        <SurfacePanel className="lg:col-span-5 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between gap-4 mb-4">
              <div>
                <h2 className="font-display text-base font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  {t('overview.brands.title')}
                </h2>
                <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                  {t('overview.brands.subtitle')}
                </p>
              </div>
              <button
                type="button"
                onClick={() => navigate('brands')}
                className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline inline-flex items-center gap-1 whitespace-nowrap"
              >
                <span>{t('overview.brands.manage')}</span>
                <ArrowRight className="w-3.5 h-3.5" aria-hidden="true" />
              </button>
            </div>

            <InteractiveComparisonChart
              selectedId={selectedBrandChartId}
              onSelect={(item) => setSelectedBrandChartId(item?.id ?? null)}
              items={brandRollups.map((r) => ({
                id: r.brand.id,
                label: r.brand.name,
                sublabel: `${labelValidationStage(r.brand.validationStage, lang)} · ${fmtCompact(r.totalViews30d)} ${t('overview.brands.viewsSuffix')}`,
                value: r.confirmedCommercial,
                formattedValue: fmtCurrency(r.confirmedCommercial, currency),
                color: r.brand.accentColor,
              }))}
            />

            {selectedBrandRollup && (
              <div className="mt-4 p-3 rounded-md bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 text-xs space-y-2">
                <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  {selectedBrandRollup.brand.name}
                </div>
                <div className="text-[11px] font-mono tabular-nums text-[#525B68] dark:text-[#AEB7C2]">
                  {t('overview.brands.selectedSummary', {
                    received: fmtCurrency(selectedBrandRollup.receivedCash, currency),
                    pending: fmtCurrency(selectedBrandRollup.pendingCommissions, currency),
                    products: selectedBrandRollup.approvedProductsCount,
                  })}
                </div>
                <div className="flex flex-wrap items-center gap-2 pt-1">
                  <button
                    type="button"
                    onClick={() => setGlobalBrandFilter(selectedBrandRollup.brand.id)}
                    className="px-2.5 py-1 rounded border border-[#315FEA]/40 text-[11px] font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:bg-[#315FEA]/10"
                  >
                    {t('overview.brands.isolateBrand')}
                  </button>
                  <button
                    type="button"
                    onClick={() => navigate('brands', { brandId: selectedBrandRollup.brand.id })}
                    className="px-2.5 py-1 rounded bg-[#315FEA] text-white text-[11px] font-medium hover:bg-[#274FC9]"
                  >
                    {t('overview.brands.openBrand')}
                  </button>
                </div>
              </div>
            )}
          </div>

          <div className="mt-5 pt-4 border-t border-black/10 dark:border-white/10 flex flex-wrap items-center justify-between gap-2 text-xs text-[#525B68] dark:text-[#AEB7C2]">
            <span>{t('overview.brands.filterHint')}</span>
            {globalBrandFilter !== 'all' && (
              <button
                type="button"
                onClick={() => setGlobalBrandFilter('all')}
                className="text-[#315FEA] dark:text-[#7FA0FF] font-medium hover:underline"
              >
                {t('overview.brands.clearFilter')}
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
              {t('overview.products.title')}
            </h2>
            <button
              type="button"
              onClick={() => navigate('products')}
              className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
            >
              {t('overview.products.viewAll')}
            </button>
          </div>
          {productsInAnalysis.length === 0 ? (
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
              {t('overview.products.empty')}
            </p>
          ) : (
            <ul className="divide-y divide-black/10 dark:divide-white/10">
              {productsInAnalysis.map((rawP) => {
                const p = localizeProduct(rawP, lang);
                return (
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
                          {p.platform} · {p.currency} · {labelProductGradeBadge(p.qualityGrade, lang)}
                        </div>
                      </div>
                      <span className="font-mono tabular-nums text-xs font-semibold text-[#315FEA] dark:text-[#7FA0FF] shrink-0">
                        {p.opportunityScore !== null
                          ? `${p.opportunityScore}/100`
                          : t('products.notInformed')}
                      </span>
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
        </SurfacePanel>

        <SurfacePanel>
          <div className="flex items-center justify-between gap-2 mb-4">
            <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
              {t('overview.content.title')}
            </h2>
            <button
              type="button"
              onClick={() => navigate('content', { contentSubView: 'calendar' })}
              className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
            >
              {t('overview.content.calendar')}
            </button>
          </div>
          <ul className="divide-y divide-black/10 dark:divide-white/10">
            {contentInProduction.slice(0, 4).map((c) => {
              const display = localizeContentDisplay(c, lang);
              return (
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
                        {display.title}
                      </div>
                      <div className="mt-0.5 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {labelContentFormat(c.format, lang)} ·{' '}
                        {labelContentVisibility(c.visibility, lang)} · {fmtDate(c.scheduledDate)}
                      </div>
                    </div>
                    <StatusLabel status={labelContentStatus(c.status, lang)} statusKey={c.status} />
                  </button>
                </li>
              );
            })}
          </ul>
        </SurfacePanel>

        <SurfacePanel className="flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between gap-2 mb-4">
              <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
                {t('overview.automations.title')}
              </h2>
              <button
                type="button"
                onClick={() => navigate('automations')}
                className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                {t('overview.automations.cta')}
              </button>
            </div>

            <div className="grid grid-cols-3 gap-2 pb-4 border-b border-black/10 dark:border-white/10 text-center">
              <div>
                <div className="font-mono tabular-nums text-lg font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  {runningAgents}
                </div>
                <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('overview.automations.running')}
                </div>
              </div>
              <div>
                <div className="font-mono tabular-nums text-lg font-semibold text-amber-600 dark:text-amber-400">
                  {pendingApprovalAgents}
                </div>
                <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('overview.automations.approvals')}
                </div>
              </div>
              <div>
                <div className="font-mono tabular-nums text-lg font-semibold text-rose-600 dark:text-rose-400">
                  {errorAgents + orphanedJobs.length}
                </div>
                <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('overview.automations.failures')}
                </div>
              </div>
            </div>

            <ul className="mt-3 space-y-2.5">
              {unreadAlerts.slice(0, 2).map((rawAl) => {
                const al = localizeNotification(rawAl, lang);
                return (
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
                );
              })}
            </ul>
          </div>

          <div className="mt-4 pt-3 border-t border-black/10 dark:border-white/10 flex items-center justify-between gap-2">
            <span className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
              {t('overview.automations.stateLabel', {
                state: labelSystemControlState(state.systemControl.state, lang),
              })}
            </span>
            {state.systemControl.state === 'ACTIVE' ? (
              <button
                type="button"
                onClick={() =>
                  haltSystemControl(state.settings.ownerName || t('common.owner'), t('overview.haltReasonCard'))
                }
                className="text-xs font-medium text-rose-600 dark:text-rose-400 hover:underline"
              >
                {t('overview.automations.quickHalt')}
              </button>
            ) : (
              <button
                type="button"
                onClick={() => navigate('automations')}
                className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                {t('overview.automations.reconcileResume')}
              </button>
            )}
          </div>
        </SurfacePanel>
      </div>

      {/* Row 4: Recent Activity Stream */}
      <SurfacePanel>
        <div className="flex items-center justify-between gap-2 mb-4">
          <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
            {t('overview.activity.title')}
          </h2>
          <button
            type="button"
            onClick={() => navigate('activity')}
            className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
          >
            {t('overview.activity.fullHistory')}
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-black/10 dark:border-white/10 text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]">
                <th className="py-2 pr-4">{t('common.date')}</th>
                <th className="py-2 pr-4">{t('common.category')}</th>
                <th className="py-2 pr-4">{t('common.action')}</th>
                <th className="py-2 pr-4">{t('common.detail')}</th>
                <th className="py-2 text-right">{t('overview.activity.colAuthor')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06] text-xs">
              {filteredActivities.map((rawAct) => {
                const act = localizeActivity(rawAct, lang);
                return (
                  <tr key={act.id} className="hover:bg-black/[0.02] dark:hover:bg-white/[0.02]">
                    <td className="py-2.5 pr-4 font-mono tabular-nums text-[11px] text-[#525B68] dark:text-[#AEB7C2] whitespace-nowrap">
                      {fmtDateTime(act.timestamp)}
                    </td>
                    <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2] whitespace-nowrap">
                      {labelActivityCategory(act.category, lang)}
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
                );
              })}
            </tbody>
          </table>
        </div>
      </SurfacePanel>
    </div>
  );
};

