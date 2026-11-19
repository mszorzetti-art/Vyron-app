import React, { useState } from 'react';
import { Download } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import {
  calculateFinanceSummary,
  computeBrandRollups,
  computeOperationalEfficiency,
  convertCurrency,
} from '../utils/vyronRules';
import { useI18n } from '../i18n/useI18n';
import { labelAttributionStatus, labelValidationStage } from '../i18n/domainLabels';
import { localizeContentDisplay } from '../i18n/seedTranslations';
import { DualLineChart, HorizontalBarComparison } from '../components/Charts';
import { MetricBlock, PageHeader, SegmentedControl, SurfacePanel } from '../components/ui';

export const AnalyticsView: React.FC = () => {
  const { state, globalBrandFilter, globalPeriodFilter, excludeTestData } = useVyron();
  const { lang, t, fmtCurrency, fmtCompact, fmtNumber, fmtPercent } = useI18n();
  const [geoTab, setGeoTab] = useState<'geo' | 'lang'>('geo');
  const [exportNotice, setExportNotice] = useState('');

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

  const trafficSeries = [
    { label: t('analytics.chart.week1'), primary: Math.round(totalTraffic * 0.19), secondary: Math.round(totalConversions * 0.18) * 100 },
    { label: t('analytics.chart.week2'), primary: Math.round(totalTraffic * 0.23), secondary: Math.round(totalConversions * 0.22) * 100 },
    { label: t('analytics.chart.week3'), primary: Math.round(totalTraffic * 0.27), secondary: Math.round(totalConversions * 0.28) * 100 },
    { label: t('analytics.chart.week4'), primary: Math.round(totalTraffic * 0.31), secondary: Math.round(totalConversions * 0.32) * 100 },
  ];

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

      {/* Trends + Geographic / Language */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        <SurfacePanel className="lg:col-span-7">
          <h2 className="font-display text-sm font-semibold mb-1">
            {t('analytics.chart.title')}
          </h2>
          <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] mb-4">
            {t('analytics.chart.subtitle')}
          </p>
          <DualLineChart
            data={trafficSeries}
            primaryLabel={t('analytics.chart.primary')}
            secondaryLabel={t('analytics.chart.secondary')}
            formatValue={(v) => fmtCompact(v)}
          />
        </SurfacePanel>

        <SurfacePanel className="lg:col-span-5 space-y-4">
          <div className="flex items-center justify-between gap-2">
            <h2 className="font-display text-sm font-semibold">
              {t('analytics.geo.title')}
            </h2>
            <SegmentedControl
              ariaLabel={t('analytics.geo.switchAria')}
              value={geoTab}
              onChange={(v) => setGeoTab(v as 'geo' | 'lang')}
              options={[
                { value: 'geo', label: t('analytics.geo.tabRegion') },
                { value: 'lang', label: t('analytics.geo.tabLang') },
              ]}
            />
          </div>
          <HorizontalBarComparison items={geoTab === 'geo' ? geoBreakdown : langBreakdown} />
        </SurfacePanel>
      </div>

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

