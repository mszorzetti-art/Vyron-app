import React, { useState } from 'react';
import { ArrowLeft, Plus } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { Brand, BrandArchetype, BrandStatus, ValidationStage } from '../types/vyron';
import { computeBrandRollups } from '../utils/vyronRules';
import { useI18n } from '../i18n/useI18n';
import {
  labelBrandArchetype,
  labelBrandStatus,
  labelChannelIntegrationStatus,
  labelComplianceMarket,
  labelContentFormat,
  labelContentStatus,
  labelContentVisibility,
  labelProductStatus,
  labelValidationStage,
} from '../i18n/domainLabels';
import {
  localizeActivity,
  localizeBrand,
  localizeContentDisplay,
  localizeProduct,
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

const ARCHETYPES: BrandArchetype[] = [
  'Descoberta & Autoridade',
  'Pesquisa & Intenção',
  'Híbrida',
];

const STAGES: ValidationStage[] = [
  '1. Exploração',
  '2. Interesse',
  '3. Validação de Conversão',
  '4. Resultado Financeiro',
  '5. Sustentabilidade',
];

export const BrandsView: React.FC = () => {
  const {
    state,
    selectedBrandId,
    excludeTestData,
    navigate,
    createBrand,
    updateBrand,
    changeBrandStatus,
  } = useVyron();
  const { lang, t, fmtCurrency, fmtCompact, fmtDate } = useI18n();

  const [statusFilter, setStatusFilter] = useState<'all' | BrandStatus>('all');
  const [compareMode, setCompareMode] = useState(false);
  const [createOpen, setCreateOpen] = useState(false);
  const [editBrand, setEditBrand] = useState<Brand | null>(null);

  const [name, setName] = useState('');
  const [niche, setNiche] = useState('');
  const [segment, setSegment] = useState('');
  const [market, setMarket] = useState('Brasil');
  const [language, setLanguage] = useState('PT-BR');
  const [timezone, setTimezone] = useState('America/Sao_Paulo');
  const [publishWindow, setPublishWindow] = useState('18:00-21:00');
  const [archetype, setArchetype] = useState<BrandArchetype>('Híbrida');
  const [pillarsText, setPillarsText] = useState('');
  const [accentColor, setAccentColor] = useState('#315FEA');
  const [tagline, setTagline] = useState('');
  const [description, setDescription] = useState('');

  const currency = state.settings.baseCurrency;
  const rollups = computeBrandRollups(
    state.brands,
    state.channels,
    state.products,
    state.contents,
    state.financeEntries,
    currency,
    { excludeTest: excludeTestData }
  );

  const openCreateModal = () => {
    if (!pillarsText) {
      setPillarsText(t('brands.modal.defaultPillars'));
    }
    setCreateOpen(true);
  };

  // SUBPAGE: Brand Detail
  if (selectedBrandId) {
    const rollup = rollups.find((r) => r.brand.id === selectedBrandId);
    if (!rollup) {
      return (
        <EmptyState
          title={t('brands.detail.notFoundTitle')}
          description={t('brands.detail.notFoundDesc')}
          actionLabel={t('brands.detail.backToList')}
          onAction={() => navigate('brands', { brandId: null })}
        />
      );
    }

    const rawBrand = rollup.brand;
    const brand = localizeBrand(rawBrand, lang);
    const brandChannels = state.channels.filter((c) => c.brandId === brand.id);
    const brandProducts = state.products.filter(
      (p) =>
        (!excludeTestData || !p.isTest) &&
        (p.brandId === brand.id || p.linkedBrandIds.includes(brand.id))
    );
    const brandContents = state.contents.filter((c) => c.brandId === brand.id);
    const brandActivities = state.activities.filter((a) => a.brandId === brand.id);

    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between gap-4">
          <button
            type="button"
            onClick={() => navigate('brands', { brandId: null })}
            className="inline-flex items-center gap-1.5 text-xs font-medium text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]"
          >
            <ArrowLeft className="w-3.5 h-3.5" aria-hidden="true" />
            <span>{t('brands.detail.backToList')}</span>
          </button>
          <StatusLabel status={labelBrandStatus(brand.status, lang)} statusKey={brand.status} />
        </div>

        <PageHeader
          title={brand.name}
          subtitle={t('brands.detail.subtitle', {
            niche: brand.niche,
            market: labelComplianceMarket(brand.market, lang),
            lang: brand.language,
            tz: brand.timezone,
            archetype: labelBrandArchetype(brand.archetype, lang),
          })}
          actions={
            <>
              <button
                type="button"
                onClick={() => setEditBrand(rawBrand)}
                className="px-3.5 py-2 text-xs font-medium rounded-md border border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20] hover:border-[#315FEA]/50 whitespace-nowrap"
              >
                {t('brands.detail.editBtn')}
              </button>
              {brand.status !== 'Archived' ? (
                <button
                  type="button"
                  onClick={() =>
                    changeBrandStatus(brand.id, 'Archived', t('brands.detail.archiveReason'))
                  }
                  className="px-3.5 py-2 text-xs font-medium rounded-md border border-rose-500/35 text-rose-700 dark:text-rose-400 hover:bg-rose-500/10 whitespace-nowrap"
                >
                  {t('brands.detail.archiveBtn')}
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() =>
                    changeBrandStatus(brand.id, 'Active', t('brands.detail.reactivateReason'))
                  }
                  className="px-3.5 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
                >
                  {t('brands.detail.reactivateBtn')}
                </button>
              )}
            </>
          }
        />

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricBlock
            label={t('brands.detail.kpi.confirmed')}
            value={fmtCurrency(rollup.confirmedCommercial, currency)}
            helper={t('brands.detail.kpi.receivedHelper', {
              amount: fmtCurrency(rollup.receivedCash, currency),
            })}
            tone="cobalt"
          />
          <MetricBlock
            label={t('brands.detail.kpi.pending')}
            value={fmtCurrency(rollup.pendingCommissions, currency)}
            helper={t('brands.detail.kpi.pendingHelper')}
            tone="amber"
          />
          <MetricBlock
            label={t('brands.detail.kpi.reach')}
            value={fmtCompact(rollup.totalViews30d)}
            helper={t('brands.detail.kpi.channelsHelper', { count: rollup.channelsCount })}
          />
          <MetricBlock
            label={t('brands.detail.kpi.stage')}
            value={labelValidationStage(brand.validationStage, lang)}
            helper={t('brands.detail.kpi.stageHelper', {
              products: rollup.approvedProductsCount,
              published: rollup.publishedContentsCount,
              total: rollup.contentsCount,
            })}
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <SurfacePanel className="lg:col-span-5 space-y-4">
            <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
              {t('brands.detail.identityTitle')}
            </h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] leading-relaxed">
              {brand.description}
            </p>
            <div className="pt-2 border-t border-black/10 dark:border-white/10 space-y-2.5 text-xs">
              <div className="flex items-center justify-between gap-2">
                <span className="text-[#525B68] dark:text-[#AEB7C2]">
                  {t('brands.detail.tzWindow')}
                </span>
                <span className="font-mono text-[11px]">
                  {brand.timezone} · {brand.publishWindow}
                </span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-[#525B68] dark:text-[#AEB7C2]">
                  {t('brands.detail.archetype')}
                </span>
                <span className="font-medium">{labelBrandArchetype(brand.archetype, lang)}</span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-[#525B68] dark:text-[#AEB7C2]">
                  {t('brands.detail.typography')}
                </span>
                <span className="font-mono text-[11px]">{brand.typographyNote}</span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-[#525B68] dark:text-[#AEB7C2]">
                  {t('brands.detail.palette')}
                </span>
                <div className="flex items-center gap-3 font-mono text-[11px]">
                  <span className="inline-flex items-center gap-1.5">
                    <span
                      className="w-3.5 h-3.5 rounded-sm border border-black/15"
                      style={{ backgroundColor: brand.accentColor }}
                    />
                    {brand.accentColor}
                  </span>
                  <span className="inline-flex items-center gap-1.5">
                    <span
                      className="w-3.5 h-3.5 rounded-sm border border-black/15"
                      style={{ backgroundColor: brand.secondaryColor }}
                    />
                    {brand.secondaryColor}
                  </span>
                </div>
              </div>
              <div className="pt-2 border-t border-black/10 dark:border-white/10">
                <div className="text-[#525B68] dark:text-[#AEB7C2] mb-1.5">
                  {t('brands.detail.pillarsTitle', { count: brand.pillars.length })}
                </div>
                <ul className="space-y-1 text-[#101216] dark:text-[#F1F2F3]">
                  {brand.pillars.map((pil, idx) => (
                    <li key={pil} className="font-mono text-[11px]">
                      0{idx + 1}. {pil}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </SurfacePanel>

          <SurfacePanel className="lg:col-span-7">
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
                {t('brands.detail.channelsTitle', { count: brandChannels.length })}
              </h2>
              <button
                type="button"
                onClick={() => navigate('channels')}
                className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                {t('brands.detail.manageChannels')}
              </button>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    <th className="py-2 pr-3">{t('brands.detail.colChannel')}</th>
                    <th className="py-2 pr-3">{t('brands.detail.colPlatform')}</th>
                    <th className="py-2 pr-3 text-right">{t('brands.detail.colFollowers')}</th>
                    <th className="py-2 pr-3 text-right">{t('brands.card.views')}</th>
                    <th className="py-2 text-right">{t('common.status')}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                  {brandChannels.map((ch) => (
                    <tr key={ch.id}>
                      <td className="py-2.5 pr-3 font-medium">{ch.name}</td>
                      <td className="py-2.5 pr-3 text-[#525B68] dark:text-[#AEB7C2]">
                        {ch.platform} · {ch.handle}
                      </td>
                      <td className="py-2.5 pr-3 text-right font-mono tabular-nums">
                        {fmtCompact(ch.followers)}
                      </td>
                      <td className="py-2.5 pr-3 text-right font-mono tabular-nums">
                        {fmtCompact(ch.views30d)}
                      </td>
                      <td className="py-2.5 text-right">
                        <StatusLabel
                          status={labelChannelIntegrationStatus(ch.integrationStatus, lang)}
                          statusKey={ch.integrationStatus}
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </SurfacePanel>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <SurfacePanel>
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-display text-sm font-semibold">
                {t('brands.detail.productsTitle', { count: brandProducts.length })}
              </h2>
              <button
                type="button"
                onClick={() => navigate('products')}
                className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                {t('brands.detail.openCatalog')}
              </button>
            </div>
            <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06] text-xs">
              {brandProducts.map((rawP) => {
                const p = localizeProduct(rawP, lang);
                return (
                  <li key={p.id} className="py-2.5 flex items-center justify-between gap-3">
                    <button
                      type="button"
                      onClick={() => navigate('products', { productId: p.id })}
                      className="text-left min-w-0 hover:text-[#315FEA]"
                    >
                      <div className="font-medium truncate">{p.name}</div>
                      <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {p.platform} · {p.currency} · {t('products.table.score')}{' '}
                        {p.opportunityScore !== null
                          ? `${p.opportunityScore}/100`
                          : t('products.notInformed')}
                      </div>
                    </button>
                    <StatusLabel status={labelProductStatus(p.status, lang)} statusKey={p.status} />
                  </li>
                );
              })}
            </ul>
          </SurfacePanel>

          <SurfacePanel>
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-display text-sm font-semibold">
                {t('brands.detail.contentsTitle', { count: brandContents.length })}
              </h2>
              <button
                type="button"
                onClick={() => navigate('content')}
                className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                {t('nav.content')}
              </button>
            </div>
            <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06] text-xs">
              {brandContents.map((c) => {
                const display = localizeContentDisplay(c, lang);
                return (
                  <li key={c.id} className="py-2.5 flex items-center justify-between gap-3">
                    <button
                      type="button"
                      onClick={() => navigate('content', { contentId: c.id })}
                      className="text-left min-w-0 hover:text-[#315FEA]"
                    >
                      <div className="font-medium truncate">{display.title}</div>
                      <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {labelContentFormat(c.format, lang)} ·{' '}
                        {labelContentVisibility(c.visibility, lang)} · {fmtDate(c.scheduledDate)}
                      </div>
                    </button>
                    <StatusLabel status={labelContentStatus(c.status, lang)} statusKey={c.status} />
                  </li>
                );
              })}
            </ul>
          </SurfacePanel>
        </div>

        <SurfacePanel>
          <h2 className="font-display text-sm font-semibold mb-3">
            {t('brands.detail.historyTitle')}
          </h2>
          {brandActivities.length === 0 ? (
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
              {t('brands.detail.historyEmpty')}
            </p>
          ) : (
            <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06] text-xs">
              {brandActivities.map((rawAct) => {
                const act = localizeActivity(rawAct, lang);
                return (
                  <li key={act.id} className="py-2.5 flex flex-wrap items-center justify-between gap-2">
                    <div>
                      <span className="font-medium">{act.action}</span>
                      <span className="text-[#525B68] dark:text-[#AEB7C2] ml-2">
                        {act.detail}
                      </span>
                    </div>
                    <span className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {fmtDate(act.timestamp)}
                    </span>
                  </li>
                );
              })}
            </ul>
          )}
        </SurfacePanel>

        <ModalDialog
          open={Boolean(editBrand)}
          title={t('brands.modal.editTitle')}
          onClose={() => setEditBrand(null)}
        >
          {editBrand && (
            <form
              className="space-y-4 text-xs"
              onSubmit={(e) => {
                e.preventDefault();
                updateBrand(editBrand.id, {
                  name: editBrand.name,
                  niche: editBrand.niche,
                  market: editBrand.market,
                  language: editBrand.language,
                  timezone: editBrand.timezone,
                  publishWindow: editBrand.publishWindow,
                  archetype: editBrand.archetype,
                  validationStage: editBrand.validationStage,
                  tagline: editBrand.tagline,
                  accentColor: editBrand.accentColor,
                });
                setEditBrand(null);
              }}
            >
              <div>
                <label className="block font-medium mb-1">{t('brands.modal.name')}</label>
                <input
                  required
                  value={editBrand.name}
                  onChange={(e) => setEditBrand({ ...editBrand, name: e.target.value })}
                  className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-medium mb-1">{t('brands.modal.tz')}</label>
                  <input
                    required
                    value={editBrand.timezone}
                    onChange={(e) => setEditBrand({ ...editBrand, timezone: e.target.value })}
                    className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                  />
                </div>
                <div>
                  <label className="block font-medium mb-1">{t('brands.modal.window')}</label>
                  <input
                    required
                    value={editBrand.publishWindow}
                    onChange={(e) => setEditBrand({ ...editBrand, publishWindow: e.target.value })}
                    className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-medium mb-1">{t('brands.detail.archetype')}</label>
                  <select
                    value={editBrand.archetype}
                    onChange={(e) =>
                      setEditBrand({ ...editBrand, archetype: e.target.value as BrandArchetype })
                    }
                    className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
                  >
                    {ARCHETYPES.map((a) => (
                      <option key={a} value={a}>
                        {labelBrandArchetype(a, lang)}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block font-medium mb-1">{t('brands.modal.stage')}</label>
                  <select
                    value={editBrand.validationStage}
                    onChange={(e) =>
                      setEditBrand({
                        ...editBrand,
                        validationStage: e.target.value as ValidationStage,
                      })
                    }
                    className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
                  >
                    {STAGES.map((st) => (
                      <option key={st} value={st}>
                        {labelValidationStage(st, lang)}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-medium mb-1">{t('brands.modal.market')}</label>
                  <input
                    required
                    value={editBrand.market}
                    onChange={(e) => setEditBrand({ ...editBrand, market: e.target.value })}
                    className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
                  />
                </div>
                <div>
                  <label className="block font-medium mb-1">{t('brands.modal.primaryColor')}</label>
                  <input
                    required
                    value={editBrand.accentColor}
                    onChange={(e) => setEditBrand({ ...editBrand, accentColor: e.target.value })}
                    className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                  />
                </div>
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setEditBrand(null)}
                  className="px-3.5 py-2 rounded border border-black/15 dark:border-white/15"
                >
                  {t('common.cancel')}
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded bg-[#315FEA] text-white font-medium hover:bg-[#274FC9]"
                >
                  {t('common.saveChanges')}
                </button>
              </div>
            </form>
          )}
        </ModalDialog>
      </div>
    );
  }

  // LIST VIEW
  const filteredRollups = rollups.filter(
    (r) => statusFilter === 'all' || r.brand.status === statusFilter
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('brands.title')}
        subtitle={t('brands.subtitle')}
        actions={
          <>
            <button
              type="button"
              onClick={() => setCompareMode((v) => !v)}
              className={`px-3.5 py-2 text-xs font-medium rounded-md border whitespace-nowrap ${
                compareMode
                  ? 'border-[#315FEA] bg-[#315FEA]/10 text-[#315FEA] dark:text-[#7FA0FF]'
                  : 'border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20]'
              }`}
            >
              {compareMode ? t('brands.compareHide') : t('brands.compareShow')}
            </button>
            <button
              type="button"
              onClick={openCreateModal}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
            >
              <Plus className="w-3.5 h-3.5" aria-hidden="true" />
              <span>{t('brands.newBrand')}</span>
            </button>
          </>
        }
      />

      <div className="flex flex-wrap items-center justify-between gap-4">
        <SegmentedControl
          ariaLabel={t('brands.filterAria')}
          value={statusFilter}
          onChange={(v) => setStatusFilter(v as 'all' | BrandStatus)}
          options={[
            { value: 'all', label: t('brands.filter.all', { count: rollups.length }) },
            { value: 'Active', label: t('brands.filter.active') },
            { value: 'Paused', label: t('brands.filter.paused') },
            { value: 'Archived', label: t('brands.filter.archived') },
          ]}
        />
      </div>

      {compareMode && (
        <SurfacePanel>
          <h2 className="font-display text-sm font-semibold mb-3">{t('brands.compareTitle')}</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">{t('brands.col.brand')}</th>
                  <th className="py-2 pr-4">{t('brands.col.marketTz')}</th>
                  <th className="py-2 pr-4">{t('brands.col.stage')}</th>
                  <th className="py-2 pr-4 text-right">{t('brands.col.approvedProd')}</th>
                  <th className="py-2 pr-4 text-right">{t('brands.col.views30d')}</th>
                  <th className="py-2 pr-4 text-right">{t('brands.col.confirmedComm')}</th>
                  <th className="py-2 text-right">{t('brands.col.receivedCash')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {filteredRollups.map((r) => (
                  <tr key={r.brand.id} className="hover:bg-black/[0.02] dark:hover:bg-white/[0.02]">
                    <td className="py-2.5 pr-4 font-medium">{r.brand.name}</td>
                    <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2] font-mono text-[11px]">
                      {labelComplianceMarket(r.brand.market, lang)} · {r.brand.timezone}
                    </td>
                    <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2]">
                      {labelValidationStage(r.brand.validationStage, lang)}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {r.approvedProductsCount}/{r.productsCount}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {fmtCompact(r.totalViews30d)}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums font-medium">
                      {fmtCurrency(r.confirmedCommercial, currency)}
                    </td>
                    <td className="py-2.5 text-right font-mono tabular-nums text-emerald-700 dark:text-emerald-400">
                      {fmtCurrency(r.receivedCash, currency)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </SurfacePanel>
      )}

      {filteredRollups.length === 0 ? (
        <EmptyState title={t('brands.emptyTitle')} description={t('brands.emptyDesc')} />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredRollups.map((r) => {
            const brand = localizeBrand(r.brand, lang);
            return (
              <SurfacePanel
                key={brand.id}
                className="flex flex-col justify-between hover:border-[#315FEA]/50"
              >
                <div>
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2.5">
                        <span
                          className="w-3 h-3 rounded-sm shrink-0"
                          style={{ backgroundColor: brand.accentColor }}
                          aria-hidden="true"
                        />
                        <h2 className="font-display text-base font-semibold truncate">
                          {brand.name}
                        </h2>
                      </div>
                      <p className="mt-1 text-xs text-[#525B68] dark:text-[#AEB7C2]">
                        {brand.niche} · {brand.timezone} ({brand.publishWindow})
                      </p>
                    </div>
                    <StatusLabel
                      status={labelBrandStatus(brand.status, lang)}
                      statusKey={brand.status}
                    />
                  </div>

                  <p className="mt-3 text-xs text-[#525B68] dark:text-[#AEB7C2] line-clamp-2">
                    {brand.description}
                  </p>

                  <div className="mt-4 pt-4 border-t border-black/10 dark:border-white/10 grid grid-cols-3 gap-3 text-xs">
                    <div>
                      <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {t('brands.card.confirmed')}
                      </div>
                      <div className="mt-0.5 font-mono tabular-nums font-semibold">
                        {fmtCurrency(r.confirmedCommercial, currency)}
                      </div>
                    </div>
                    <div>
                      <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {t('brands.card.validation')}
                      </div>
                      <div className="mt-0.5 font-mono tabular-nums text-[11px]">
                        {labelValidationStage(brand.validationStage, lang)}
                      </div>
                    </div>
                    <div>
                      <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {t('brands.card.views')}
                      </div>
                      <div className="mt-0.5 font-mono tabular-nums">
                        {fmtCompact(r.totalViews30d)}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="mt-4 pt-3 border-t border-black/10 dark:border-white/10 flex items-center justify-between">
                  <span className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    {labelBrandArchetype(brand.archetype, lang)} ·{' '}
                    {t('brands.card.pillars', { count: brand.pillars.length })}
                  </span>
                  <button
                    type="button"
                    onClick={() => navigate('brands', { brandId: brand.id })}
                    className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
                  >
                    {t('brands.card.openDetails')}
                  </button>
                </div>
              </SurfacePanel>
            );
          })}
        </div>
      )}

      <ModalDialog
        open={createOpen}
        title={t('brands.modal.createTitle')}
        subtitle={t('brands.modal.createSubtitle')}
        onClose={() => setCreateOpen(false)}
      >
        <form
          className="space-y-4 text-xs"
          onSubmit={(e) => {
            e.preventDefault();
            if (!name.trim() || !niche.trim()) return;
            const created = createBrand({
              name: name.trim(),
              slug: name.trim().toLowerCase().replace(/\s+/g, '-'),
              niche: niche.trim(),
              segment: segment.trim() || 'Editorial & Afiliados',
              market,
              language,
              timezone,
              publishWindow,
              archetype,
              validationStage: '1. Exploração',
              pillars: (pillarsText || t('brands.modal.defaultPillars'))
                .split(',')
                .map((s) => s.trim())
                .filter(Boolean),
              status: 'Active',
              accentColor,
              secondaryColor: '#292E36',
              typographyNote: 'Plus Jakarta Sans + JetBrains Mono',
              tagline: tagline.trim() || 'Nova operação estruturada.',
              description: description.trim() || 'Marca cadastrada no ambiente Vyron.',
            });
            setCreateOpen(false);
            setName('');
            setNiche('');
            setSegment('');
            setTagline('');
            setDescription('');
            navigate('brands', { brandId: created.id });
          }}
        >
          <div>
            <label className="block font-medium mb-1">{t('brands.modal.nameReq')}</label>
            <input
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder={t('brands.modal.namePlaceholder')}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">{t('brands.modal.nicheReq')}</label>
              <input
                required
                value={niche}
                onChange={(e) => setNiche(e.target.value)}
                placeholder={t('brands.modal.nichePlaceholder')}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">{t('brands.detail.archetype')}</label>
              <select
                value={archetype}
                onChange={(e) => setArchetype(e.target.value as BrandArchetype)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                {ARCHETYPES.map((a) => (
                  <option key={a} value={a}>
                    {labelBrandArchetype(a, lang)}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block font-medium mb-1">{t('brands.modal.market')}</label>
              <input
                value={market}
                onChange={(e) => setMarket(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">{t('brands.modal.tz')}</label>
              <input
                value={timezone}
                onChange={(e) => setTimezone(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">{t('brands.modal.window')}</label>
              <input
                value={publishWindow}
                onChange={(e) => setPublishWindow(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">{t('brands.modal.language')}</label>
              <select
                value={language}
                onChange={(e) => setLanguage(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="PT-BR">PT-BR</option>
                <option value="EN-US">EN-US</option>
                <option value="FR-FR">FR-FR</option>
                <option value="ES-ES">ES-ES</option>
              </select>
            </div>
            <div>
              <label className="block font-medium mb-1">{t('brands.modal.accentColor')}</label>
              <input
                value={accentColor}
                onChange={(e) => setAccentColor(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
          </div>
          <div>
            <label className="block font-medium mb-1">{t('brands.modal.pillarsLabel')}</label>
            <input
              value={pillarsText}
              onChange={(e) => setPillarsText(e.target.value)}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div>
            <label className="block font-medium mb-1">{t('brands.modal.descLabel')}</label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder={t('brands.modal.descPlaceholder')}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
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
              {t('brands.modal.createBtn')}
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
