import React, { useEffect, useState } from 'react';
import { Download, X } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { ContentCategory } from '../types/vyron';
import {
  calculateFinanceSummary,
  computeBrandRollups,
  computeOperationalEfficiency,
  convertCurrency,
} from '../utils/vyronRules';
import {
  AnalyticsMetricKey,
  ChartTimeRange,
  buildAnalyticsContentPoints,
  buildChannelComparisonItems,
} from '../utils/chartSeries';
import { useI18n } from '../i18n/useI18n';
import {
  labelAttributionStatus,
  labelContentCategory,
  labelValidationStage,
} from '../i18n/domainLabels';
import { localizeContentDisplay } from '../i18n/seedTranslations';
import {
  ChartTimeframeToolbar,
  InteractiveComparisonChart,
  InteractiveSeriesConfig,
  InteractiveTimeSeriesChart,
  InteractiveTimeSeriesPoint,
} from '../components/Charts';
import { MetricBlock, PageHeader, SegmentedControl, SurfacePanel } from '../components/ui';

const CATEGORIES: ContentCategory[] = ['Descoberta', 'Conexão', 'Comercial contextual'];

export const AnalyticsView: React.FC = () => {
  const { state, globalBrandFilter, globalPeriodFilter, excludeTestData } = useVyron();
  const { lang, t, fmtCurrency, fmtCompact, fmtNumber, fmtPercent, fmtDate } = useI18n();
  const [geoTab, setGeoTab] = useState<'geo' | 'lang'>('geo');
  const [exportNotice, setExportNotice] = useState('');

  const [chartRange, setChartRange] = useState<ChartTimeRange>(globalPeriodFilter);
  const [customStart, setCustomStart] = useState('2026-10-28');
  const [customEnd, setCustomEnd] = useState('2026-11-18');
  const [comparePrev, setComparePrev] = useState(false);
  const [metric, setMetric] = useState<AnalyticsMetricKey>('views');
  const [channelFilter, setChannelFilter] = useState<string>('all');
  const [categoryFilter, setCategoryFilter] = useState<'all' | ContentCategory>('all');
  const [selectedContentPointId, setSelectedContentPointId] = useState<string | null>(null);
  const [selectedChannelId, setSelectedChannelId] = useState<string | null>(null);
  const [selectedGeoId, setSelectedGeoId] = useState<string | null>(null);

  useEffect(() => {
    setChartRange(globalPeriodFilter);
  }, [globalPeriodFilter]);

  const currency = state.settings.baseCurrency;

  const filteredChannels = state.channels.filter(
    (c) => globalBrandFilter === 'all' || c.brandId === globalBrandFilter
  );
  const filteredContents = state.contents.filter(
    (c) =>
      (globalBrandFilter === 'all' || c.brandId === globalBrandFilter) &&
      c.metrics
  );
  const finance = calculateFinanceSummary(state.financeEntries, currency, {
    brandId: globalBrandFilter,
    period: globalPeriodFilter,
    excludeTest: excludeTestData,
  });
  const efficiency = computeOperationalEfficiency(finance, state.contents, globalBrandFilter);

  const totalTraffic = filteredChannels.reduce((s, c) => s + c.views30d, 0);
  const totalClicks = filteredContents.reduce((s, c) => s + (c.metrics?.clicks ?? 0), 0);
  const totalConversions = filteredContents.reduce(
    (s, c) => s + (c.metrics?.conversions ?? 0),
    0
  );
  const conversionRate = totalClicks > 0 ? (totalConversions / totalClicks) * 100 : 2.9;

  const brandRollups = computeBrandRollups(
    state.brands,
    state.channels,
    state.products,
    state.contents,
    state.financeEntries,
    currency,
    { excludeTest: excludeTestData }
  );

  const analyticsSeriesRes = buildAnalyticsContentPoints(state.contents, currency, {
    brandId: globalBrandFilter,
    channelId: channelFilter,
    category: categoryFilter,
    range: chartRange,
    customStart,
    customEnd,
  });

  const channelComparisonRows = buildChannelComparisonItems(state.channels, state.brands, {
    brandId: globalBrandFilter,
    metric: 'views30d',
  });
  const selectedChannelRow = selectedChannelId
    ? channelComparisonRows.find((r) => r.channel.id === selectedChannelId) ?? null
    : null;

  const formatShortDateLabel = (iso: string) => fmtDate(iso).slice(0, 5);

  const metricSeriesConfig: InteractiveSeriesConfig[] = (() => {
    if (metric === 'clicks') {
      return [
        { id: 'clicks', label: t('analytics.chart.metricClicks'), color: '#315FEA', areaFill: true },
        { id: 'views', label: t('analytics.chart.metricViews'), color: '#AEB7C2', dashed: true, defaultHidden: true },
      ];
    }
    if (metric === 'conversions') {
      return [
        {
          id: 'conversions',
          label: t('analytics.chart.metricConversions'),
          color: '#D97706',
          areaFill: true,
          isEstimate: true,
        },
        { id: 'clicks', label: t('analytics.chart.metricClicks'), color: '#315FEA', defaultHidden: true },
      ];
    }
    if (metric === 'ctr') {
      return [
        {
          id: 'ctr',
          label: t('analytics.chart.metricCtr'),
          color: '#315FEA',
          areaFill: true,
          formatValue: (v) => fmtPercent(v, 2),
        },
      ];
    }
    if (metric === 'epc') {
      return [
        {
          id: 'epc',
          label: t('analytics.chart.metricEpc', { currency }),
          color: '#10B981',
          areaFill: true,
          isEstimate: true,
          formatValue: (v) => fmtCurrency(v, currency),
        },
      ];
    }
    return [
      { id: 'views', label: t('analytics.chart.primary'), color: '#315FEA', areaFill: true },
      { id: 'clicks', label: t('analytics.chart.secondary'), color: '#10B981' },
    ];
  })();

  const analyticsPoints: InteractiveTimeSeriesPoint[] = analyticsSeriesRes.items.map((item) => {
    const rawContent = state.contents.find((c) => c.id === item.contentId);
    const title = rawContent ? localizeContentDisplay(rawContent, lang).title : item.title;
    return {
      id: item.id,
      label: `${formatShortDateLabel(item.date)} · ${title.slice(0, 14)}`,
      fullDateLabel: `${fmtDate(item.date)} · ${title}`,
      isEstimate: item.isEstimate,
      values: {
        views: item.views,
        clicks: item.clicks,
        conversions: item.conversions,
        ctr: item.ctrPct,
        epc: item.epc,
      },
    };
  });

  const formatActiveAnalyticsVal = (v: number) => {
    if (metric === 'ctr') return fmtPercent(v, 2);
    if (metric === 'epc') return fmtCurrency(v, currency);
    if (metric === 'conversions') return `${Math.round(v)}`;
    return fmtCompact(v);
  };

  const selectedAnalyticsItem = selectedContentPointId
    ? analyticsSeriesRes.items.find((i) => i.id === selectedContentPointId) ?? null
    : null;
  const selectedRawContent = selectedAnalyticsItem
    ? state.contents.find((c) => c.id === selectedAnalyticsItem.contentId) ?? null
    : null;

  const geoBreakdown = [
    { id: 'br', label: t('analytics.geo.br'), sublabel: t('analytics.geo.brSub'), value: 44, formattedValue: fmtPercent(44, 0) },
    { id: 'us', label: t('analytics.geo.us'), sublabel: t('analytics.geo.usSub'), value: 33, formattedValue: fmtPercent(33, 0) },
    { id: 'eu', label: t('analytics.geo.eu'), sublabel: t('analytics.geo.euSub'), value: 16, formattedValue: fmtPercent(16, 0) },
    { id: 'other', label: t('analytics.geo.other'), sublabel: t('analytics.geo.otherSub'), value: 7, formattedValue: fmtPercent(7, 0) },
  ];

  const langBreakdown = [
    { id: 'en', label: t('analytics.lang.en'), sublabel: t('analytics.lang.enSub'), value: 54, formattedValue: fmtPercent(54, 0) },
    { id: 'pt', label: t('analytics.lang.pt'), sublabel: t('analytics.lang.ptSub'), value: 46, formattedValue: fmtPercent(46, 0) },
  ];

  const handleExportReport = () => {
    const csvRows = [
      [
        t('analytics.csv.brand'),
        t('analytics.csv.stage'),
        t('analytics.csv.views'),
        t('analytics.csv.approvedProducts'),
        t('analytics.csv.confirmedCommercial', { currency }),
      ].join(','),
      ...brandRollups.map((r) =>
        [
          `"${r.brand.name}"`,
          `"${labelValidationStage(r.brand.validationStage, lang)}"`,
          r.totalViews30d,
          r.approvedProductsCount,
          r.confirmedCommercial.toFixed(2),
        ].join(',')
      ),
    ].join('\n');
    const blob = new Blob([csvRows], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `vyron-analytics-${globalPeriodFilter}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    setExportNotice(t('analytics.exportNotice', { period: globalPeriodFilter }));
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('analytics.title')}
        subtitle={t('analytics.subtitle')}
        actions={
          <button
            type="button"
            onClick={handleExportReport}
            className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
          >
            <Download className="w-3.5 h-3.5" aria-hidden="true" />
            <span>{t('analytics.exportCsv')}</span>
          </button>
        }
      />

      {exportNotice && (
        <div className="px-4 py-2.5 rounded-md bg-emerald-500/10 border border-emerald-500/30 text-xs text-emerald-700 dark:text-emerald-300">
          {exportNotice}
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricBlock
          label={t('analytics.kpi.traffic')}
          value={fmtCompact(totalTraffic)}
          helper={t('analytics.kpi.window', { period: globalPeriodFilter })}
          tone="cobalt"
        />
        <MetricBlock
          label={t('analytics.kpi.conversions')}
          value={`${totalConversions}`}
          helper={t('analytics.kpi.clicksConv', {
            clicks: fmtCompact(totalClicks),
            rate: fmtPercent(conversionRate, 2),
          })}
        />
        <MetricBlock
          label={t('analytics.kpi.efficiency')}
          value={
            efficiency.realizedCashPerHour !== null
              ? `${fmtCurrency(efficiency.realizedCashPerHour, currency)}/h`
              : t('common.na')
          }
          helper={t('analytics.kpi.hoursScope', {
            hours: fmtNumber(efficiency.totalHumanHours, 1),
          })}
          tone="emerald"
        />
        <MetricBlock
          label={t('analytics.kpi.rpm')}
          value={fmtCurrency(
            totalTraffic > 0 ? (finance.confirmedCommercialResult / totalTraffic) * 1000 : 0,
            currency
          )}
          helper={t('analytics.kpi.rpmHelper')}
        />
      </div>

      {/* Content Evolution + Channel Comparison */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        <SurfacePanel className="lg:col-span-7 space-y-3">
          <div>
            <h2 className="font-display text-sm font-semibold mb-1">
              {t('analytics.chart.title')}
            </h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
              {t('analytics.chart.subtitle')}
            </p>
          </div>

          <ChartTimeframeToolbar
            range={chartRange}
            onRangeChange={(next) => {
              setChartRange(next);
              setSelectedContentPointId(null);
            }}
            customStart={customStart}
            customEnd={customEnd}
            onCustomStartChange={setCustomStart}
            onCustomEndChange={setCustomEnd}
            comparePrevious={comparePrev}
            onToggleComparePrevious={() => setComparePrev((v) => !v)}
            hasPreviousData={analyticsSeriesRes.previousCount > 0}
            coverageNote={t('analytics.chart.coverageNotice')}
          />

          <div className="flex flex-wrap items-center justify-between gap-2 pb-1">
            <SegmentedControl
              ariaLabel={t('analytics.chart.metricAria')}
              value={metric}
              onChange={(v) => setMetric(v as AnalyticsMetricKey)}
              options={[
                { value: 'views', label: t('analytics.chart.metricViews') },
                { value: 'clicks', label: t('analytics.chart.metricClicks') },
                { value: 'conversions', label: t('analytics.chart.metricConversions') },
                { value: 'ctr', label: t('analytics.chart.metricCtr') },
                { value: 'epc', label: t('analytics.chart.metricEpc', { currency }) },
              ]}
            />

            <div className="flex flex-wrap items-center gap-2">
              <select
                aria-label={t('analytics.chart.channelFilterAria')}
                value={channelFilter}
                onChange={(e) => {
                  setChannelFilter(e.target.value);
                  setSelectedContentPointId(null);
                }}
                className="h-8 px-2.5 text-xs rounded-md border border-black/10 dark:border-white/10 bg-[#F1F2F3]/70 dark:bg-[#101216] text-[#101216] dark:text-[#F1F2F3]"
              >
                <option value="all">{t('analytics.chart.allChannels')}</option>
                {filteredChannels.map((ch) => (
                  <option key={ch.id} value={ch.id}>
                    {ch.name}
                  </option>
                ))}
              </select>

              <select
                aria-label={t('analytics.chart.categoryFilterAria')}
                value={categoryFilter}
                onChange={(e) => {
                  setCategoryFilter(e.target.value as 'all' | ContentCategory);
                  setSelectedContentPointId(null);
                }}
                className="h-8 px-2.5 text-xs rounded-md border border-black/10 dark:border-white/10 bg-[#F1F2F3]/70 dark:bg-[#101216] text-[#101216] dark:text-[#F1F2F3]"
              >
                <option value="all">{t('analytics.chart.allCategories')}</option>
                {CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {labelContentCategory(cat, lang)}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <InteractiveTimeSeriesChart
            points={analyticsPoints}
            series={metricSeriesConfig}
            formatValue={formatActiveAnalyticsVal}
            ariaLabel={t('charts.timeSeriesAria', { label: t('analytics.chart.title') })}
            selectedPointId={selectedContentPointId}
            onSelectPoint={(pt) => setSelectedContentPointId(pt?.id ?? null)}
          />

          {selectedAnalyticsItem && selectedRawContent && (
            <div className="p-3.5 rounded-md bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 text-xs space-y-1.5">
              <div className="flex items-start justify-between gap-2">
                <div>
                  <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                    {t('analytics.chart.drillTitle', {
                      date: fmtDate(selectedAnalyticsItem.date),
                    })}
                  </div>
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    {localizeContentDisplay(selectedRawContent, lang).title} ·{' '}
                    <span className="font-mono">{selectedAnalyticsItem.trackingSrc}</span>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setSelectedContentPointId(null)}
                  aria-label={t('charts.clearPin')}
                  className="p-1 rounded text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]"
                >
                  <X className="w-3.5 h-3.5" aria-hidden="true" />
                </button>
              </div>
              <div className="font-mono tabular-nums text-[11px] text-[#101216] dark:text-[#F1F2F3]">
                {t('analytics.chart.drillMetrics', {
                  views: fmtCompact(selectedAnalyticsItem.views),
                  clicks: fmtCompact(selectedAnalyticsItem.clicks),
                  ctr: fmtPercent(selectedAnalyticsItem.ctrPct, 2),
                  epc: fmtCurrency(selectedAnalyticsItem.epc, currency),
                  conv: selectedAnalyticsItem.conversions,
                  status: labelAttributionStatus(
                    selectedRawContent.metrics?.attributionStatus ?? 'Estimativa [Em investigação]',
                    lang
                  ),
                })}
              </div>
            </div>
          )}
        </SurfacePanel>

        <SurfacePanel className="lg:col-span-5 space-y-4">
          <div>
            <h2 className="font-display text-sm font-semibold mb-1">
              {t('analytics.channelChart.title')}
            </h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
              {t('analytics.channelChart.subtitle')}
            </p>
          </div>
          <InteractiveComparisonChart
            selectedId={selectedChannelId}
            onSelect={(item) => setSelectedChannelId(item?.id ?? null)}
            items={channelComparisonRows.map((row) => ({
              id: row.channel.id,
              label: row.channel.name,
              sublabel: `${row.brandName} · ${row.channel.platform}`,
              value: row.rawValue,
              formattedValue: fmtCompact(row.rawValue),
              color: row.accentColor,
            }))}
          />
          {selectedChannelRow && (
            <div className="p-3 rounded-md bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 text-xs grid grid-cols-3 gap-2">
              <div>
                <div className="text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('analytics.channelChart.viewsLabel')}
                </div>
                <div className="font-mono tabular-nums font-semibold">
                  {fmtCompact(selectedChannelRow.channel.views30d)}
                </div>
              </div>
              <div>
                <div className="text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('analytics.channelChart.reachLabel')}
                </div>
                <div className="font-mono tabular-nums font-semibold">
                  {fmtCompact(selectedChannelRow.channel.reach30d)}
                </div>
              </div>
              <div>
                <div className="text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('analytics.channelChart.growthLabel')}
                </div>
                <div className="font-mono tabular-nums font-semibold text-emerald-700 dark:text-emerald-400">
                  {selectedChannelRow.channel.growthPct30d >= 0 ? '+' : ''}
                  {fmtPercent(selectedChannelRow.channel.growthPct30d, 1)}
                </div>
              </div>
            </div>
          )}
        </SurfacePanel>
      </div>

      {/* Geographic / Language */}
      <SurfacePanel className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h2 className="font-display text-sm font-semibold">
            {t('analytics.geo.title')}
          </h2>
          <SegmentedControl
            ariaLabel={t('analytics.geo.switchAria')}
            value={geoTab}
            onChange={(v) => {
              setGeoTab(v as 'geo' | 'lang');
              setSelectedGeoId(null);
            }}
            options={[
              { value: 'geo', label: t('analytics.geo.tabRegion') },
              { value: 'lang', label: t('analytics.geo.tabLang') },
            ]}
          />
        </div>
        <InteractiveComparisonChart
          selectedId={selectedGeoId}
          onSelect={(item) => setSelectedGeoId(item?.id ?? null)}
          items={geoTab === 'geo' ? geoBreakdown : langBreakdown}
        />
      </SurfacePanel>

      {/* Content & Product Attribution Table */}
      <SurfacePanel>
        <div className="flex flex-wrap items-center justify-between gap-2 mb-3">
          <div>
            <h2 className="font-display text-sm font-semibold">
              {t('analytics.attribution.title')}
            </h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
              {t('analytics.attribution.subtitle')}
            </p>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                <th className="py-2 pr-4">{t('analytics.attribution.colContent')}</th>
                <th className="py-2 pr-4">{t('analytics.attribution.colTag')}</th>
                <th className="py-2 pr-4">{t('analytics.attribution.colStatus')}</th>
                <th className="py-2 pr-4 text-right">{t('analytics.attribution.colViewsRet')}</th>
                <th className="py-2 pr-4 text-right">{t('analytics.attribution.colClicks')}</th>
                <th className="py-2 pr-4 text-right">{t('analytics.attribution.colConv')}</th>
                <th className="py-2 text-right">
                  {t('analytics.attribution.colRev', { currency })}
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
              {filteredContents.map((c) => {
                const localized = localizeContentDisplay(c, lang);
                const rev = c.metrics
                  ? convertCurrency(c.metrics.revenueGenerated, c.metrics.currency, currency)
                  : 0;
                const attrLabel = c.metrics?.attributionStatus
                  ? labelAttributionStatus(c.metrics.attributionStatus, lang)
                  : labelAttributionStatus('Estimativa [Em investigação]', lang);
                return (
                  <tr key={c.id}>
                    <td className="py-2.5 pr-4 font-medium">{localized.title}</td>
                    <td className="py-2.5 pr-4 font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {c.metrics?.trackingSrc ?? '-'}
                    </td>
                    <td className="py-2.5 pr-4 font-mono text-[11px] text-amber-700 dark:text-amber-400">
                      {attrLabel}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {fmtCompact(c.metrics?.views ?? 0)} ({fmtPercent(c.metrics?.retention30sPct ?? 0, 0)})
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {fmtCompact(c.metrics?.clicks ?? 0)}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {c.metrics?.conversions ?? 0}
                    </td>
                    <td className="py-2.5 text-right font-mono tabular-nums font-medium text-emerald-700 dark:text-emerald-400">
                      {fmtCurrency(rev, currency)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </SurfacePanel>

      {/* Anomalies & Future ML Readiness */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <SurfacePanel className="space-y-3">
          <h2 className="font-display text-sm font-semibold">
            {t('analytics.anomalies.title')}
          </h2>
          <ul className="space-y-2.5 text-xs">
            <li className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <div className="font-medium text-emerald-700 dark:text-emerald-400">
                {t('analytics.anomalies.item1Title')}
              </div>
              <p className="mt-1 text-[#525B68] dark:text-[#AEB7C2]">
                {t('analytics.anomalies.item1Desc')}
              </p>
            </li>
            <li className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <div className="font-medium text-amber-700 dark:text-amber-400">
                {t('analytics.anomalies.item2Title')}
              </div>
              <p className="mt-1 text-[#525B68] dark:text-[#AEB7C2]">
                {t('analytics.anomalies.item2Desc')}
              </p>
            </li>
          </ul>
        </SurfacePanel>

        <SurfacePanel className="space-y-3">
          <h2 className="font-display text-sm font-semibold">
            {t('analytics.ml.title')}
          </h2>
          <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] leading-relaxed">
            {t('analytics.ml.desc')}
          </p>
          <div className="grid grid-cols-3 gap-3 pt-2 border-t border-black/10 dark:border-white/10 text-xs">
            <div>
              <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                {t('analytics.ml.samples')}
              </div>
              <div className="font-mono tabular-nums font-semibold mt-0.5">
                {t('analytics.ml.eventsCount', {
                  count: state.products.reduce((s, p) => s + p.decisions.length, 0) + state.activities.length,
                })}
              </div>
            </div>
            <div>
              <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                {t('analytics.ml.keys')}
              </div>
              <div className="font-mono tabular-nums font-semibold mt-0.5">
                {t('analytics.ml.keysVal')}
              </div>
            </div>
            <div>
              <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                {t('analytics.ml.pipelineState')}
              </div>
              <div className="font-mono font-semibold mt-0.5 text-[#525B68] dark:text-[#AEB7C2]">
                {t('analytics.ml.planned')}
              </div>
            </div>
          </div>
        </SurfacePanel>
      </div>
    </div>
  );
};

