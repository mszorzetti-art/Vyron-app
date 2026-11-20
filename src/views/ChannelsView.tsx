import React, { useState } from 'react';
import { Plus, RefreshCw } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { ChannelPlatform } from '../types/vyron';
import { useI18n } from '../i18n/useI18n';
import { labelChannelIntegrationStatus } from '../i18n/domainLabels';
import { ChannelChartMetric, buildChannelComparisonItems } from '../utils/chartSeries';
import { InteractiveComparisonChart } from '../components/Charts';
import {
  EmptyState,
  MetricBlock,
  ModalDialog,
  PageHeader,
  SegmentedControl,
  StatusLabel,
  SurfacePanel,
} from '../components/ui';

const PLATFORMS: ChannelPlatform[] = ['YouTube', 'Instagram', 'TikTok', 'Pinterest', 'Website'];

export const ChannelsView: React.FC = () => {
  const { state, globalBrandFilter, createChannel, syncChannelDemo } = useVyron();
  const { lang, t, fmtCompact, fmtPercent, fmtDateTime } = useI18n();
  const [platformFilter, setPlatformFilter] = useState<'all' | ChannelPlatform>('all');
  const [chartMetric, setChartMetric] = useState<ChannelChartMetric>('views30d');
  const [selectedChannelId, setSelectedChannelId] = useState<string | null>(null);
  const [createOpen, setCreateOpen] = useState(false);

  const [chName, setChName] = useState('');
  const [chHandle, setChHandle] = useState('');
  const [chBrandId, setChBrandId] = useState(state.brands[0]?.id ?? '');
  const [chPlatform, setChPlatform] = useState<ChannelPlatform>('YouTube');
  const [chLang, setChLang] = useState('PT-BR');
  const [chAdvUnlocked, setChAdvUnlocked] = useState(false);

  const visibleChannels = state.channels.filter((ch) => {
    if (globalBrandFilter !== 'all' && ch.brandId !== globalBrandFilter) return false;
    if (platformFilter !== 'all' && ch.platform !== platformFilter) return false;
    return true;
  });

  const totalFollowers = visibleChannels.reduce((s, c) => s + c.followers, 0);
  const totalViews = visibleChannels.reduce((s, c) => s + c.views30d, 0);
  const ytChannels = visibleChannels.filter((c) => c.platform === 'YouTube');
  const unlockedYtCount = ytChannels.filter((c) => c.advancedFeaturesUnlocked).length;
  const avgShortsBridge =
    ytChannels.length > 0
      ? ytChannels.reduce((s, c) => s + (c.shortsToLongPct ?? 0), 0) / ytChannels.length
      : 0;
  const avgEngagement =
    visibleChannels.length > 0
      ? visibleChannels.reduce((s, c) => s + c.engagementRatePct, 0) / visibleChannels.length
      : 0;

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('channels.title')}
        subtitle={t('channels.subtitle')}
        actions={
          <button
            type="button"
            onClick={() => setCreateOpen(true)}
            className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
          >
            <Plus className="w-3.5 h-3.5" aria-hidden="true" />
            <span>{t('channels.add')}</span>
          </button>
        }
      />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricBlock
          label={t('channels.kpi.audience')}
          value={fmtCompact(totalFollowers)}
          helper={t('channels.kpi.audienceHelper', { count: visibleChannels.length })}
        />
        <MetricBlock
          label={t('channels.kpi.views')}
          value={fmtCompact(totalViews)}
          helper={t('channels.kpi.viewsHelper', { pct: fmtPercent(avgEngagement, 1) })}
          tone="cobalt"
        />
        <MetricBlock
          label={t('channels.kpi.ytAdvanced')}
          value={`${unlockedYtCount}/${ytChannels.length}`}
          helper={t('channels.kpi.ytAdvancedHelper')}
        />
        <MetricBlock
          label={t('channels.kpi.shortsBridge')}
          value={fmtPercent(avgShortsBridge, 1)}
          helper={t('channels.kpi.shortsBridgeHelper')}
          tone="emerald"
        />
      </div>

      <SegmentedControl
        ariaLabel={t('channels.filterAria')}
        value={platformFilter}
        onChange={(v) => setPlatformFilter(v as 'all' | ChannelPlatform)}
        options={[
          { value: 'all', label: t('channels.allPlatforms') },
          ...PLATFORMS.map((p) => ({ value: p, label: p })),
        ]}
      />

      {visibleChannels.length === 0 ? (
        <EmptyState
          title={t('channels.emptyTitle')}
          description={t('channels.emptyDesc')}
          actionLabel={t('channels.add')}
          onAction={() => setCreateOpen(true)}
        />
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <SurfacePanel padding="none" className="lg:col-span-8 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-black/10 dark:border-white/10 bg-black/[0.02] dark:bg-white/[0.02] text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]">
                    <th className="py-3 pl-4 pr-3">{t('channels.table.channelBrand')}</th>
                    <th className="py-3 px-3">{t('channels.table.platformLinks')}</th>
                    <th className="py-3 px-3 text-right">{t('channels.table.publications')}</th>
                    <th className="py-3 px-3 text-right">{t('channels.table.growth')}</th>
                    <th className="py-3 px-3 text-right">{t('channels.table.views')}</th>
                    <th className="py-3 px-3 text-right">{t('channels.table.bridge')}</th>
                    <th className="py-3 px-3">{t('channels.table.integration')}</th>
                    <th className="py-3 pl-3 pr-4 text-right">{t('channels.table.sync')}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                  {visibleChannels.map((ch) => {
                    const brand = state.brands.find((b) => b.id === ch.brandId);
                    return (
                      <tr key={ch.id} className="hover:bg-black/[0.02] dark:hover:bg-white/[0.02]">
                        <td className="py-3 pl-4 pr-3">
                          <div className="font-medium text-[#101216] dark:text-[#F1F2F3]">
                            {ch.name}
                          </div>
                          <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                            {brand?.name} · {ch.handle}
                          </div>
                        </td>
                        <td className="py-3 px-3 text-[#525B68] dark:text-[#AEB7C2]">
                          <div>
                            {ch.platform} · {ch.language}
                          </div>
                          <div className="font-mono text-[10px]">
                            {ch.advancedFeaturesUnlocked
                              ? t('channels.linksOk')
                              : t('channels.linksOff')}
                          </div>
                        </td>
                        <td className="py-3 px-3 text-right font-mono tabular-nums">
                          {ch.publications30d}
                        </td>
                        <td
                          className={`py-3 px-3 text-right font-mono tabular-nums ${
                            ch.growthPct30d >= 0
                              ? 'text-emerald-700 dark:text-emerald-400'
                              : 'text-rose-600 dark:text-rose-400'
                          }`}
                        >
                          {ch.growthPct30d >= 0 ? '+' : ''}
                          {fmtPercent(ch.growthPct30d, 1)}
                        </td>
                        <td className="py-3 px-3 text-right font-mono tabular-nums">
                          {fmtCompact(ch.views30d)}
                        </td>
                        <td className="py-3 px-3 text-right font-mono tabular-nums">
                          {ch.shortsToLongPct !== undefined
                            ? fmtPercent(ch.shortsToLongPct, 1)
                            : '-'}
                        </td>
                        <td className="py-3 px-3">
                          <StatusLabel
                            status={labelChannelIntegrationStatus(ch.integrationStatus, lang)}
                            statusKey={ch.integrationStatus}
                          />
                        </td>
                        <td className="py-3 pl-3 pr-4 text-right">
                          <button
                            type="button"
                            onClick={() => syncChannelDemo(ch.id)}
                            aria-label={t('channels.syncAria', { name: ch.name })}
                            className="inline-flex items-center gap-1 text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
                          >
                            <RefreshCw className="w-3 h-3" aria-hidden="true" />
                            <span>{t('channels.testSync')}</span>
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </SurfacePanel>

          <SurfacePanel className="lg:col-span-4 space-y-4">
            <div>
              <h2 className="font-display text-sm font-semibold mb-1">
                {t('channels.chartTitle')}
              </h2>
              <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                {t('channels.chartSubtitle')}
              </p>
            </div>

            <select
              aria-label={t('channels.chartMetricAria')}
              value={chartMetric}
              onChange={(e) => setChartMetric(e.target.value as ChannelChartMetric)}
              className="w-full h-8 px-2.5 text-xs rounded-md border border-black/10 dark:border-white/10 bg-[#F1F2F3]/70 dark:bg-[#101216] text-[#101216] dark:text-[#F1F2F3]"
            >
              <option value="views30d">{t('channels.chartMetric.views')}</option>
              <option value="reach30d">{t('channels.chartMetric.reach')}</option>
              <option value="followers">{t('channels.chartMetric.followers')}</option>
              <option value="engagementRatePct">{t('channels.chartMetric.engagement')}</option>
              <option value="growthPct30d">{t('channels.chartMetric.growth')}</option>
            </select>

            <InteractiveComparisonChart
              selectedId={selectedChannelId}
              onSelect={(item) => setSelectedChannelId(item?.id ?? null)}
              items={buildChannelComparisonItems(visibleChannels, state.brands, {
                metric: chartMetric,
              }).map((row) => {
                const formattedValue =
                  chartMetric === 'engagementRatePct'
                    ? fmtPercent(row.rawValue, 1)
                    : chartMetric === 'growthPct30d'
                    ? `${row.rawValue >= 0 ? '+' : ''}${fmtPercent(row.rawValue, 1)}`
                    : fmtCompact(row.rawValue);
                return {
                  id: row.channel.id,
                  label: row.channel.name,
                  sublabel: `${row.brandName} · ${row.channel.platform}`,
                  value: row.rawValue,
                  formattedValue,
                  color: row.accentColor,
                };
              })}
            />

            {(() => {
              const selectedCh = visibleChannels.find((c) => c.id === selectedChannelId);
              if (!selectedCh) return null;
              return (
                <div className="p-3 rounded-md bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 text-xs space-y-1">
                  <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                    {selectedCh.name} ({selectedCh.handle})
                  </div>
                  <div className="text-[11px] font-mono tabular-nums text-[#525B68] dark:text-[#AEB7C2]">
                    {t('channels.chartSelectedDetail', {
                      platform: selectedCh.platform,
                      publications: selectedCh.publications30d,
                      sync: fmtDateTime(selectedCh.lastSyncAt),
                    })}
                  </div>
                </div>
              );
            })()}
          </SurfacePanel>
        </div>
      )}

      <ModalDialog
        open={createOpen}
        title={t('channels.modal.title')}
        subtitle={t('channels.modal.subtitle')}
        onClose={() => setCreateOpen(false)}
      >
        <form
          className="space-y-4 text-xs"
          onSubmit={(e) => {
            e.preventDefault();
            if (!chName.trim() || !chHandle.trim()) return;
            createChannel({
              brandId: chBrandId,
              name: chName.trim(),
              handle: chHandle.trim(),
              platform: chPlatform,
              language: chLang,
              advancedFeaturesUnlocked: chAdvUnlocked,
              integrationStatus: 'Configurado (Demo)',
              followers: 1200,
              growthPct30d: 4.5,
              views30d: 8400,
              reach30d: 11200,
              engagementRatePct: 4.2,
              shortsToLongPct: chPlatform === 'YouTube' ? 9.0 : undefined,
              publications30d: 2,
            });
            setCreateOpen(false);
            setChName('');
            setChHandle('');
          }}
        >
          <div>
            <label htmlFor="ch-name-input" className="block font-medium mb-1">
              {t('channels.modal.nameReq')}
            </label>
            <input
              id="ch-name-input"
              required
              value={chName}
              onChange={(e) => setChName(e.target.value)}
              placeholder={t('channels.modal.namePlaceholder')}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label htmlFor="ch-plat-select" className="block font-medium mb-1">
                {t('channels.modal.platform')}
              </label>
              <select
                id="ch-plat-select"
                value={chPlatform}
                onChange={(e) => setChPlatform(e.target.value as ChannelPlatform)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                {PLATFORMS.map((p) => (
                  <option key={p} value={p}>
                    {p}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="ch-brand-select" className="block font-medium mb-1">
                {t('channels.modal.brand')}
              </label>
              <select
                id="ch-brand-select"
                value={chBrandId}
                onChange={(e) => setChBrandId(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                {state.brands.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label htmlFor="ch-handle-input" className="block font-medium mb-1">
                {t('channels.modal.handleReq')}
              </label>
              <input
                id="ch-handle-input"
                required
                value={chHandle}
                onChange={(e) => setChHandle(e.target.value)}
                placeholder={t('channels.modal.handlePlaceholder')}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div>
              <label htmlFor="ch-lang-select" className="block font-medium mb-1">
                {t('channels.modal.language')}
              </label>
              <select
                id="ch-lang-select"
                value={chLang}
                onChange={(e) => setChLang(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="PT-BR">PT-BR</option>
                <option value="EN-US">EN-US</option>
                <option value="FR-FR">FR-FR</option>
                <option value="ES-ES">ES-ES</option>
              </select>
            </div>
          </div>
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={chAdvUnlocked}
              onChange={(e) => setChAdvUnlocked(e.target.checked)}
              className="accent-[#315FEA]"
            />
            <span>{t('channels.modal.advCheckbox')}</span>
          </label>
          <div className="flex justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => setCreateOpen(false)}
              className="px-3.5 py-2 rounded border border-black/15 dark:border-white/15"
            >
              {t('common.cancel')}
            </button>
            <button
              type="submit"
              className="px-4 py-2 rounded bg-[#315FEA] text-white font-medium hover:bg-[#274FC9]"
            >
              {t('channels.modal.submit')}
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};

