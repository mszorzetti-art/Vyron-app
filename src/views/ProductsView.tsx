import React, { useState } from 'react';
import { ArrowLeft, ExternalLink, Plus, Search } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import {
  ComplianceState,
  CurrencyCode,
  ProductQualityGrade,
  ProductStatus,
} from '../types/vyron';
import { useI18n } from '../i18n/useI18n';
import {
  labelCompetitionLevel,
  labelComplianceMarket,
  labelComplianceState,
  labelContentFormat,
  labelDataConfidence,
  labelProductGradeBadge,
  labelProductModel,
  labelProductStatus,
} from '../i18n/domainLabels';
import { localizeProduct } from '../i18n/seedTranslations';
import {
  groupProductsByCurrency,
  scoreProductV61,
} from '../utils/vyronRules';
import {
  EmptyState,
  MetricBlock,
  ModalDialog,
  PageHeader,
  SegmentedControl,
  StatusLabel,
  SurfacePanel,
} from '../components/ui';

export const ProductsView: React.FC = () => {
  const {
    state,
    selectedProductId,
    globalBrandFilter,
    excludeTestData,
    setExcludeTestData,
    navigate,
    createProduct,
    changeProductStatus,
    updateProductGovernance,
    generateContentFromProduct,
  } = useVyron();
  const { lang, t, fmtCurrency, fmtDate, fmtNumber } = useI18n();

  const [statusFilter, setStatusFilter] = useState<'all' | ProductStatus>('all');
  const [viewMode, setViewMode] = useState<'by_currency' | 'catalog'>('by_currency');
  const [searchQuery, setSearchQuery] = useState('');
  const [compareIds, setCompareIds] = useState<string[]>([]);
  const [createOpen, setCreateOpen] = useState(false);

  const [decisionTargetStatus, setDecisionTargetStatus] = useState<ProductStatus | null>(null);
  const [justification, setJustification] = useState('');
  const [decisionError, setDecisionError] = useState('');

  const [contentChannelId, setContentChannelId] = useState(state.channels[0]?.id ?? '');
  const [contentFormat, setContentFormat] = useState<'Long-form' | 'Shorts'>('Long-form');

  const [prodName, setProdName] = useState('');
  const [prodBrandId, setProdBrandId] = useState(state.brands[0]?.id ?? '');
  const [prodCategory, setProdCategory] = useState('');
  const [prodPlatform, setProdPlatform] = useState('Amazon Associates BR');
  const [prodModel, setProdModel] = useState<'CPA' | 'RevShare' | 'Híbrido' | 'Direto'>('RevShare');
  const [prodPrice, setProdPrice] = useState('490');
  const [prodCurrency, setProdCurrency] = useState<CurrencyCode>('BRL');
  const [prodCommPct, setProdCommPct] = useState('10');
  const [prodEpc, setProdEpc] = useState('1.60');
  const [prodCookie, setProdCookie] = useState('14');
  const [prodIsTest, setProdIsTest] = useState(false);

  // SUBPAGE: Product Detail & Analysis
  if (selectedProductId) {
    const rawProduct = state.products.find((p) => p.id === selectedProductId);
    if (!rawProduct) {
      return (
        <EmptyState
          title={t('products.detail.notFoundTitle')}
          description={t('products.detail.notFoundDesc')}
          actionLabel={t('products.detail.back')}
          onAction={() => navigate('products', { productId: null })}
        />
      );
    }

    const product = localizeProduct(rawProduct, lang);
    const brand = state.brands.find((b) => b.id === product.brandId);
    const brandChannels = state.channels.filter(
      (c) => c.brandId === product.brandId || product.linkedBrandIds.includes(c.brandId)
    );
    const linkedContents = state.contents.filter((c) => c.productId === product.id);
    const scoreEval = scoreProductV61(product, lang);

    const handleConfirmDecision = (e: React.FormEvent) => {
      e.preventDefault();
      if (!decisionTargetStatus) return;
      if (!justification.trim()) {
        setDecisionError(t('products.modal.justificationError'));
        return;
      }
      changeProductStatus(product.id, decisionTargetStatus, justification.trim());
      setDecisionTargetStatus(null);
      setJustification('');
      setDecisionError('');
    };

    const toggleLinkedBrand = (bId: string) => {
      const exists = product.linkedBrandIds.includes(bId);
      const next = exists
        ? product.linkedBrandIds.filter((x) => x !== bId)
        : [...product.linkedBrandIds, bId];
      if (next.length === 0) return;
      updateProductGovernance(product.id, { linkedBrandIds: next });
    };

    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between gap-4">
          <button
            type="button"
            onClick={() => navigate('products', { productId: null })}
            className="inline-flex items-center gap-1.5 text-xs font-medium text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]"
          >
            <ArrowLeft className="w-3.5 h-3.5" aria-hidden="true" />
            <span>{t('products.detail.back')}</span>
          </button>
          <div className="flex items-center gap-3">
            {product.isTest && (
              <span className="font-mono text-[11px] text-amber-600 dark:text-amber-400">
                {t('products.table.testTag')}
              </span>
            )}
            <StatusLabel
              status={labelProductStatus(product.status, lang)}
              statusKey={product.status}
            />
          </div>
        </div>

        <PageHeader
          title={product.name}
          subtitle={t('products.detail.subtitle', {
            platform: product.platform,
            externalId: product.externalId,
            currency: product.currency,
            market: labelComplianceMarket(product.complianceMarket, lang),
          })}
          actions={
            <>
              {product.status !== 'Approved' && (
                <button
                  type="button"
                  onClick={() => {
                    setDecisionTargetStatus('Approved');
                    setDecisionError('');
                  }}
                  className="px-4 py-2 text-xs font-medium rounded-md bg-emerald-600 text-white hover:bg-emerald-700 whitespace-nowrap"
                >
                  {t('products.detail.approve')}
                </button>
              )}
              {product.status !== 'Rejected' && (
                <button
                  type="button"
                  onClick={() => {
                    setDecisionTargetStatus('Rejected');
                    setDecisionError('');
                  }}
                  className="px-3.5 py-2 text-xs font-medium rounded-md border border-rose-500/40 text-rose-700 dark:text-rose-400 hover:bg-rose-500/10 whitespace-nowrap"
                >
                  {t('products.detail.reject')}
                </button>
              )}
              {product.status !== 'Archived' && (
                <button
                  type="button"
                  onClick={() => {
                    setDecisionTargetStatus('Archived');
                    setDecisionError('');
                  }}
                  className="px-3.5 py-2 text-xs font-medium rounded-md border border-black/15 dark:border-white/15 hover:bg-black/5 dark:hover:bg-white/5 whitespace-nowrap"
                >
                  {t('products.detail.archive')}
                </button>
              )}
            </>
          }
        />

        {/* Commercial Indicators (preserving missing unknowns) */}
        <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
          <MetricBlock
            label={t('products.detail.kpi.score')}
            value={
              product.opportunityScore !== null ? `${product.opportunityScore}/100` : t('common.unknown')
            }
            helper={scoreEval.explanation}
            tone="cobalt"
          />
          <MetricBlock
            label={t('products.detail.kpi.price')}
            value={product.price !== null ? fmtCurrency(product.price, product.currency) : t('products.unknownNull')}
            helper={t('products.detail.kpi.comm', {
              val: product.commissionRatePct !== null ? `${fmtNumber(product.commissionRatePct, 1)}%` : t('common.unknown'),
            })}
          />
          <MetricBlock
            label={t('products.detail.kpi.epc')}
            value={
              product.epcValue !== null
                ? fmtCurrency(product.epcValue, product.currency)
                : t('products.unknownNull')
            }
            helper={
              product.cpaValue !== null
                ? t('products.detail.kpi.cpa', { val: fmtCurrency(product.cpaValue, product.currency) })
                : t('products.detail.kpi.confidence', { val: labelDataConfidence(product.dataConfidence, lang) })
            }
          />
          <MetricBlock
            label={t('products.detail.kpi.cookie')}
            value={
              product.cookieWindowDays !== null
                ? t('products.detail.kpi.days', { days: product.cookieWindowDays })
                : t('products.unknownNull')
            }
            helper={t('products.detail.kpi.competition', {
              val: labelCompetitionLevel(product.competitionLevel, lang),
            })}
          />
          <MetricBlock
            label={t('products.detail.kpi.qualityCompliance')}
            value={`${labelProductGradeBadge(product.qualityGrade, lang)} · ${labelComplianceState(product.complianceState, lang)}`}
            helper={t('products.detail.kpi.linkedContents', { count: linkedContents.length })}
          />
        </div>

        {/* Separated Governance: Quality Grade, Compliance State, Shared Brands */}
        <SurfacePanel className="grid grid-cols-1 md:grid-cols-3 gap-5 text-xs">
          <div>
            <label className="block font-semibold mb-1.5">
              {t('products.detail.gov.qualityTitle')}
            </label>
            <p className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mb-2">
              {t('products.detail.gov.qualityDesc')}
            </p>
            <select
              aria-label={t('products.detail.gov.qualityAria')}
              value={product.qualityGrade ?? ''}
              onChange={(e) =>
                updateProductGovernance(product.id, {
                  qualityGrade: (e.target.value || null) as ProductQualityGrade | null,
                })
              }
              className="w-full h-9 px-2.5 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
            >
              <option value="A">{t('products.detail.gov.gradeA')}</option>
              <option value="B">{t('products.detail.gov.gradeB')}</option>
              <option value="C">{t('products.detail.gov.gradeC')}</option>
            </select>
          </div>

          <div>
            <label className="block font-semibold mb-1.5">
              {t('products.detail.gov.complianceTitle', {
                market: labelComplianceMarket(product.complianceMarket, lang),
              })}
            </label>
            <p className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mb-2">
              {t('products.detail.gov.complianceDesc')}
            </p>
            <select
              aria-label={t('products.detail.gov.complianceAria')}
              value={product.complianceState}
              onChange={(e) =>
                updateProductGovernance(product.id, {
                  complianceState: e.target.value as ComplianceState,
                })
              }
              className="w-full h-9 px-2.5 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
            >
              <option value="APPROVED">{labelComplianceState('APPROVED', lang)}</option>
              <option value="PENDING">{labelComplianceState('PENDING', lang)}</option>
              <option value="BLOCKED">{labelComplianceState('BLOCKED', lang)}</option>
              <option value="NOT_APPLICABLE">{labelComplianceState('NOT_APPLICABLE', lang)}</option>
            </select>
          </div>

          <div>
            <div className="font-semibold mb-1.5">
              {t('products.detail.gov.brandsTitle')}
            </div>
            <p className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mb-2">
              {t('products.detail.gov.brandsDesc')}
            </p>
            <div className="flex flex-wrap gap-2">
              {state.brands.map((b) => {
                const active = product.linkedBrandIds.includes(b.id);
                return (
                  <button
                    key={b.id}
                    type="button"
                    onClick={() => toggleLinkedBrand(b.id)}
                    className={`px-2.5 py-1 rounded border text-[11px] ${
                      active
                        ? 'border-[#315FEA] bg-[#315FEA]/12 text-[#315FEA] dark:text-[#7FA0FF] font-medium'
                        : 'border-black/15 dark:border-white/15 text-[#525B68] dark:text-[#AEB7C2]'
                    }`}
                  >
                    {b.name}
                  </button>
                );
              })}
            </div>
          </div>
        </SurfacePanel>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <SurfacePanel className="lg:col-span-7 space-y-4">
            <h2 className="font-display text-sm font-semibold">
              {t('products.detail.evidenceTitle')}
            </h2>
            {product.evidence.length === 0 ? (
              <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                {t('products.detail.evidenceEmpty')}
              </p>
            ) : (
              <ul className="divide-y divide-black/10 dark:divide-white/10">
                {product.evidence.map((ev) => (
                  <li key={ev.id} className="py-3 first:pt-0 last:pb-0 space-y-1">
                    <div className="flex items-center justify-between gap-2 text-xs">
                      <span className="font-medium text-[#101216] dark:text-[#F1F2F3] inline-flex items-center gap-1.5">
                        {ev.sourceName}
                        <ExternalLink className="w-3 h-3 text-[#AEB7C2]" aria-hidden="true" />
                      </span>
                      <span className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {t('products.detail.verifiedAt', { date: fmtDate(ev.verifiedAt) })}
                      </span>
                    </div>
                    <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] leading-relaxed">
                      {ev.summary}
                    </p>
                  </li>
                ))}
              </ul>
            )}

            <div className="pt-4 border-t border-black/10 dark:border-white/10">
              <h3 className="font-display text-xs font-semibold mb-2">
                {t('products.detail.createContentTitle', { brand: brand?.name ?? '-' })}
              </h3>
              <div className="flex flex-wrap items-center gap-2.5">
                <select
                  aria-label={t('products.detail.selectChannelAria')}
                  value={
                    brandChannels.some((c) => c.id === contentChannelId)
                      ? contentChannelId
                      : brandChannels[0]?.id ?? ''
                  }
                  onChange={(e) => setContentChannelId(e.target.value)}
                  className="h-8 px-2.5 text-xs rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
                >
                  {(brandChannels.length > 0 ? brandChannels : state.channels).map((ch) => (
                    <option key={ch.id} value={ch.id}>
                      {ch.name} ({ch.platform})
                    </option>
                  ))}
                </select>
                <select
                  aria-label={t('products.detail.selectFormatAria')}
                  value={contentFormat}
                  onChange={(e) => setContentFormat(e.target.value as 'Long-form' | 'Shorts')}
                  className="h-8 px-2.5 text-xs rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
                >
                  <option value="Long-form">{labelContentFormat('Long-form', lang)}</option>
                  <option value="Shorts">{labelContentFormat('Shorts', lang)}</option>
                </select>
                <button
                  type="button"
                  onClick={() => {
                    const targetCh =
                      brandChannels.find((c) => c.id === contentChannelId)?.id ??
                      brandChannels[0]?.id ??
                      state.channels[0]?.id;
                    const created = generateContentFromProduct(
                      product.id,
                      targetCh,
                      contentFormat
                    );
                    navigate('content', {
                      contentId: created.id,
                      contentSubView: 'studio',
                    });
                  }}
                  className="h-8 px-3.5 text-xs font-medium rounded bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
                >
                  {t('products.detail.createContentBtn')}
                </button>
              </div>
            </div>
          </SurfacePanel>

          <SurfacePanel className="lg:col-span-5">
            <h2 className="font-display text-sm font-semibold mb-3">
              {t('products.detail.decisionsTitle')}
            </h2>
            {product.decisions.length === 0 ? (
              <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                {t('products.detail.decisionsEmpty')}
              </p>
            ) : (
              <ul className="space-y-3">
                {product.decisions.map((d) => (
                  <li
                    key={d.id}
                    className="p-3 rounded-md bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 text-xs space-y-1"
                  >
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-medium">
                        {labelProductStatus(d.previousStatus, lang)} →{' '}
                        {labelProductStatus(d.newStatus, lang)}
                      </span>
                      <span className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {fmtDate(d.timestamp)}
                      </span>
                    </div>
                    <p className="text-[#525B68] dark:text-[#AEB7C2]">{d.justification}</p>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {t('products.detail.byActor', { actor: d.actor })}
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </SurfacePanel>
        </div>

        <ModalDialog
          open={Boolean(decisionTargetStatus)}
          title={t('products.modal.decisionTitle', {
            status: decisionTargetStatus ? labelProductStatus(decisionTargetStatus, lang) : '',
          })}
          subtitle={t('products.modal.decisionSubtitle')}
          onClose={() => setDecisionTargetStatus(null)}
        >
          <form onSubmit={handleConfirmDecision} className="space-y-4 text-xs">
            <div>
              <label className="block font-medium mb-1">
                {t('products.modal.justificationLabel')}
              </label>
              <textarea
                required
                rows={3}
                value={justification}
                onChange={(e) => {
                  setJustification(e.target.value);
                  setDecisionError('');
                }}
                placeholder={t('products.modal.justificationPlaceholder')}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
              {decisionError && (
                <p className="mt-1 text-rose-600 dark:text-rose-400">{decisionError}</p>
              )}
            </div>
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setDecisionTargetStatus(null)}
                className="px-3.5 py-2 rounded border border-black/15 dark:border-white/15"
              >
                {t('common.cancel')}
              </button>
              <button
                type="submit"
                className="px-4 py-2 rounded bg-[#315FEA] text-white font-medium hover:bg-[#274FC9]"
              >
                {t('products.modal.confirmDecision')}
              </button>
            </div>
          </form>
        </ModalDialog>
      </div>
    );
  }

  // LIST VIEW
  const localizedProducts = state.products.map((p) => localizeProduct(p, lang));

  const visibleProducts = localizedProducts.filter((p) => {
    if (excludeTestData && p.isTest) return false;
    if (
      globalBrandFilter !== 'all' &&
      p.brandId !== globalBrandFilter &&
      !p.linkedBrandIds.includes(globalBrandFilter)
    ) {
      return false;
    }
    if (statusFilter !== 'all' && p.status !== statusFilter) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      if (
        !p.name.toLowerCase().includes(q) &&
        !p.platform.toLowerCase().includes(q) &&
        !p.category.toLowerCase().includes(q) &&
        !p.externalId.toLowerCase().includes(q)
      ) {
        return false;
      }
    }
    return true;
  });

  const comparedProducts = localizedProducts.filter((p) => compareIds.includes(p.id));
  const currencyGroups = groupProductsByCurrency(visibleProducts);

  const toggleCompare = (id: string) => {
    setCompareIds((prev) =>
      prev.includes(id)
        ? prev.filter((x) => x !== id)
        : prev.length >= 3
        ? [...prev.slice(1), id]
        : [...prev, id]
    );
  };

  const renderProductTable = (items: typeof visibleProducts) => (
    <SurfacePanel padding="none" className="overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse text-xs">
          <thead>
            <tr className="border-b border-black/10 dark:border-white/10 bg-black/[0.02] dark:bg-white/[0.02] text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]">
              <th className="py-3 pl-4 pr-2 w-8">{t('products.table.compareShort')}</th>
              <th className="py-3 px-3">{t('products.table.productCatalog')}</th>
              <th className="py-3 px-3">{t('products.table.brands')}</th>
              <th className="py-3 px-3">{t('products.table.qualityCompliance')}</th>
              <th className="py-3 px-3 text-right">
                {t('products.table.price', { currency: items[0]?.currency ?? 'BRL' })}
              </th>
              <th className="py-3 px-3 text-right">{t('products.table.commEpc')}</th>
              <th className="py-3 px-3 text-right">{t('products.table.cookie')}</th>
              <th className="py-3 px-3 text-right">{t('products.table.score')}</th>
              <th className="py-3 px-3">{t('products.table.state')}</th>
              <th className="py-3 pl-3 pr-4 text-right">{t('products.table.action')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
            {items.map((p) => {
              const linkedNames = p.linkedBrandIds
                .map((id) => state.brands.find((b) => b.id === id)?.name)
                .filter(Boolean)
                .join(' · ');
              const isCompared = compareIds.includes(p.id);
              return (
                <tr key={p.id} className="hover:bg-black/[0.02] dark:hover:bg-white/[0.02]">
                  <td className="py-3 pl-4 pr-2">
                    <input
                      type="checkbox"
                      checked={isCompared}
                      onChange={() => toggleCompare(p.id)}
                      aria-label={t('products.table.compareAria', { name: p.name })}
                      className="rounded border-black/25 dark:border-white/25 accent-[#315FEA]"
                    />
                  </td>
                  <td className="py-3 px-3">
                    <button
                      type="button"
                      onClick={() => navigate('products', { productId: p.id })}
                      className="text-left font-medium text-[#101216] dark:text-[#F1F2F3] hover:text-[#315FEA]"
                    >
                      {p.name}
                    </button>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] font-mono">
                      {p.platform} · {p.externalId}
                      {p.isTest ? ` · ${t('products.table.testTag')}` : ''}
                    </div>
                  </td>
                  <td className="py-3 px-3 text-[#525B68] dark:text-[#AEB7C2] max-w-[160px] truncate">
                    {linkedNames || '-'}
                  </td>
                  <td className="py-3 px-3">
                    <div className="font-mono text-[11px]">
                      {labelProductGradeBadge(p.qualityGrade, lang)} ·{' '}
                      {labelComplianceMarket(p.complianceMarket, lang)}
                    </div>
                    <StatusLabel
                      status={labelComplianceState(p.complianceState, lang)}
                      statusKey={p.complianceState}
                    />
                  </td>
                  <td className="py-3 px-3 text-right font-mono tabular-nums whitespace-nowrap">
                    {p.price !== null ? fmtCurrency(p.price, p.currency) : t('products.notInformed')}
                  </td>
                  <td className="py-3 px-3 text-right font-mono tabular-nums whitespace-nowrap">
                    <div>
                      {p.commissionRatePct !== null
                        ? `${fmtNumber(p.commissionRatePct, 1)}%`
                        : t('products.notInformed')}
                    </div>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      EPC {p.epcValue !== null ? fmtCurrency(p.epcValue, p.currency) : t('common.unknown')}
                    </div>
                  </td>
                  <td className="py-3 px-3 text-right font-mono tabular-nums whitespace-nowrap">
                    {p.cookieWindowDays !== null
                      ? t('common.daysShort', { days: p.cookieWindowDays })
                      : t('products.notInformed')}
                  </td>
                  <td className="py-3 px-3 text-right font-mono tabular-nums font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                    {p.opportunityScore !== null ? p.opportunityScore : t('products.notInformed')}
                  </td>
                  <td className="py-3 px-3">
                    <StatusLabel
                      status={labelProductStatus(p.status, lang)}
                      statusKey={p.status}
                    />
                  </td>
                  <td className="py-3 pl-3 pr-4 text-right whitespace-nowrap">
                    <button
                      type="button"
                      onClick={() => navigate('products', { productId: p.id })}
                      className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
                    >
                      {t('products.table.analyze')}
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </SurfacePanel>
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('products.title')}
        subtitle={t('products.subtitle')}
        actions={
          <div className="flex flex-wrap items-center gap-2.5">
            <label className="inline-flex items-center gap-2 px-3 py-2 text-xs rounded-md border border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20]">
              <input
                type="checkbox"
                checked={!excludeTestData}
                onChange={(e) => setExcludeTestData(!e.target.checked)}
                className="accent-[#315FEA]"
              />
              <span>{t('products.showTestData')}</span>
            </label>
            <button
              type="button"
              onClick={() => setCreateOpen(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
            >
              <Plus className="w-3.5 h-3.5" aria-hidden="true" />
              <span>{t('products.addProduct')}</span>
            </button>
          </div>
        }
      />

      {/* Filter & Search Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex flex-wrap items-center gap-3">
          <SegmentedControl
            ariaLabel={t('products.viewModeAria')}
            value={viewMode}
            onChange={(v) => setViewMode(v as 'by_currency' | 'catalog')}
            options={[
              { value: 'by_currency', label: t('products.viewByCurrency') },
              { value: 'catalog', label: t('products.viewCatalog') },
            ]}
          />
          <SegmentedControl
            ariaLabel={t('products.statusFilterAria')}
            value={statusFilter}
            onChange={(v) => setStatusFilter(v as 'all' | ProductStatus)}
            options={[
              { value: 'all', label: t('common.all') },
              { value: 'Candidate', label: labelProductStatus('Candidate', lang) },
              { value: 'Approved', label: labelProductStatus('Approved', lang) },
              { value: 'Rejected', label: labelProductStatus('Rejected', lang) },
              { value: 'Archived', label: labelProductStatus('Archived', lang) },
            ]}
          />
        </div>

        <div className="relative w-full sm:w-64">
          <Search className="w-3.5 h-3.5 text-[#AEB7C2] absolute left-3 top-1/2 -translate-y-1/2" aria-hidden="true" />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={t('products.searchPlaceholder')}
            aria-label={t('products.searchAria')}
            className="w-full h-9 pl-8 pr-3 text-xs rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
          />
        </div>
      </div>

      {/* Product Side-by-Side Comparison Panel */}
      {comparedProducts.length >= 2 && (
        <SurfacePanel>
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-display text-sm font-semibold">
              {t('products.comparePanelTitle', { count: comparedProducts.length })}
            </h2>
            <button
              type="button"
              onClick={() => setCompareIds([])}
              className="text-xs text-[#525B68] dark:text-[#AEB7C2] hover:underline"
            >
              {t('products.compareClear')}
            </button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">{t('products.compareCriterion')}</th>
                  {comparedProducts.map((cp) => (
                    <th key={cp.id} className="py-2 pr-4 font-semibold text-[#101216] dark:text-[#F1F2F3]">
                      {cp.name} ({cp.currency})
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                <tr>
                  <td className="py-2 pr-4 text-[#525B68] dark:text-[#AEB7C2]">
                    {t('products.compareScore')}
                  </td>
                  {comparedProducts.map((cp) => (
                    <td key={cp.id} className="py-2 pr-4 font-mono tabular-nums font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                      {cp.opportunityScore !== null ? `${cp.opportunityScore}/100` : t('products.unknownNull')}
                    </td>
                  ))}
                </tr>
                <tr>
                  <td className="py-2 pr-4 text-[#525B68] dark:text-[#AEB7C2]">
                    {t('products.comparePriceComm')}
                  </td>
                  {comparedProducts.map((cp) => (
                    <td key={cp.id} className="py-2 pr-4 font-mono tabular-nums">
                      {cp.price !== null ? fmtCurrency(cp.price, cp.currency) : t('products.notInformed')} (
                      {cp.commissionRatePct !== null
                        ? `${fmtNumber(cp.commissionRatePct, 1)}%`
                        : t('products.notInformed')}
                      )
                    </td>
                  ))}
                </tr>
                <tr>
                  <td className="py-2 pr-4 text-[#525B68] dark:text-[#AEB7C2]">
                    {t('products.compareEpcCookieGrade')}
                  </td>
                  {comparedProducts.map((cp) => (
                    <td key={cp.id} className="py-2 pr-4 font-mono tabular-nums">
                      {cp.epcValue !== null ? fmtCurrency(cp.epcValue, cp.currency) : t('products.notInformed')} ·{' '}
                      {cp.cookieWindowDays !== null
                        ? t('common.daysShort', { days: cp.cookieWindowDays })
                        : t('products.notInformed')}{' '}
                      · {labelProductGradeBadge(cp.qualityGrade, lang)}
                    </td>
                  ))}
                </tr>
              </tbody>
            </table>
          </div>
        </SurfacePanel>
      )}

      {/* Products Data Grid */}
      {visibleProducts.length === 0 ? (
        <EmptyState
          title={t('products.emptyTitle')}
          description={t('products.emptyDesc')}
          actionLabel={t('products.addProduct')}
          onAction={() => setCreateOpen(true)}
        />
      ) : viewMode === 'by_currency' ? (
        <div className="space-y-5">
          {currencyGroups.map((group) => (
            <div key={group.currency} className="space-y-2">
              <div className="flex items-center justify-between text-xs px-1">
                <h2 className="font-display font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  {t('products.currencyGroupTitle', {
                    currency: group.currency,
                    count: group.items.length,
                  })}
                </h2>
                <span className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('products.currencyGroupHint')}
                </span>
              </div>
              {renderProductTable(group.items)}
            </div>
          ))}
        </div>
      ) : (
        renderProductTable(visibleProducts)
      )}

      {/* Create Product Modal */}
      <ModalDialog
        open={createOpen}
        title={t('products.modal.createTitle')}
        subtitle={t('products.modal.createSubtitle')}
        onClose={() => setCreateOpen(false)}
      >
        <form
          className="space-y-4 text-xs"
          onSubmit={(e) => {
            e.preventDefault();
            if (!prodName.trim()) return;
            const created = createProduct({
              brandId: prodBrandId,
              linkedBrandIds: [prodBrandId],
              isTest: prodIsTest,
              name: prodName.trim(),
              category: prodCategory.trim() || 'Hardware & Tech',
              platform: prodPlatform.trim(),
              remunerationModel: prodModel,
              price: prodPrice.trim() ? Number(prodPrice) : null,
              currency: prodCurrency,
              commissionRatePct: prodCommPct.trim() ? Number(prodCommPct) : null,
              cpaValue: prodModel === 'CPA' ? 80 : null,
              epcValue: prodEpc.trim() ? Number(prodEpc) : null,
              cookieWindowDays: prodCookie.trim() ? Number(prodCookie) : null,
              opportunityScore: undefined as unknown as number | null,
              demandTrendPct: 15,
              competitionLevel: 'Média',
              status: 'Candidate',
            });
            setCreateOpen(false);
            setProdName('');
            navigate('products', { productId: created.id });
          }}
        >
          <div>
            <label className="block font-medium mb-1">{t('products.modal.nameReq')}</label>
            <input
              required
              value={prodName}
              onChange={(e) => setProdName(e.target.value)}
              placeholder={t('products.modal.namePlaceholder')}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">{t('products.modal.mainBrand')}</label>
              <select
                value={prodBrandId}
                onChange={(e) => setProdBrandId(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                {state.brands.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block font-medium mb-1">{t('products.modal.category')}</label>
              <input
                value={prodCategory}
                onChange={(e) => setProdCategory(e.target.value)}
                placeholder={t('products.modal.categoryPlaceholder')}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">{t('products.modal.platform')}</label>
              <input
                value={prodPlatform}
                onChange={(e) => setProdPlatform(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">{t('products.modal.remunerationModel')}</label>
              <select
                value={prodModel}
                onChange={(e) =>
                  setProdModel(e.target.value as 'CPA' | 'RevShare' | 'Híbrido' | 'Direto')
                }
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="RevShare">{labelProductModel('RevShare', lang)}</option>
                <option value="CPA">{labelProductModel('CPA', lang)}</option>
                <option value="Híbrido">{labelProductModel('Híbrido', lang)}</option>
                <option value="Direto">{labelProductModel('Direto', lang)}</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-2.5">
            <div>
              <label className="block font-medium mb-1">{t('products.modal.price')}</label>
              <input
                type="number"
                step="0.01"
                value={prodPrice}
                onChange={(e) => setProdPrice(e.target.value)}
                className="w-full px-2.5 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">{t('products.modal.currency')}</label>
              <select
                value={prodCurrency}
                onChange={(e) => setProdCurrency(e.target.value as CurrencyCode)}
                className="w-full px-2 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="BRL">BRL</option>
                <option value="USD">USD</option>
                <option value="EUR">EUR</option>
              </select>
            </div>
            <div>
              <label className="block font-medium mb-1">{t('products.modal.commPct')}</label>
              <input
                type="number"
                step="0.1"
                value={prodCommPct}
                onChange={(e) => setProdCommPct(e.target.value)}
                className="w-full px-2.5 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">{t('products.modal.epcLabel')}</label>
              <input
                type="number"
                step="0.01"
                value={prodEpc}
                onChange={(e) => setProdEpc(e.target.value)}
                placeholder={t('products.modal.epcPlaceholder')}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">{t('products.modal.cookieLabel')}</label>
              <input
                type="number"
                value={prodCookie}
                onChange={(e) => setProdCookie(e.target.value)}
                placeholder={t('products.modal.epcPlaceholder')}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
          </div>
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={prodIsTest}
              onChange={(e) => setProdIsTest(e.target.checked)}
              className="accent-[#315FEA]"
            />
            <span>{t('products.modal.isTestCheckbox')}</span>
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
              {t('products.modal.saveBtn')}
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
