import React, { useState } from 'react';
import { Plus } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { CommissionStage, CurrencyCode, FinanceEntryType } from '../types/vyron';
import {
  FX_TO_BRL,
  calculateFinanceSummary,
  convertCurrency,
} from '../utils/vyronRules';
import { useI18n } from '../i18n/useI18n';
import { labelCommissionStage, labelFinanceType } from '../i18n/domainLabels';
import { localizeFinanceEntry } from '../i18n/seedTranslations';
import {
  MetricBlock,
  ModalDialog,
  PageHeader,
  SegmentedControl,
  StatusLabel,
  SurfacePanel,
} from '../components/ui';

export const FinanceView: React.FC = () => {
  const {
    state,
    globalBrandFilter,
    globalPeriodFilter,
    excludeTestData,
    setExcludeTestData,
    setBaseCurrency,
    addFinanceEntry,
  } = useVyron();
  const { lang, t, fmtCurrency, fmtDate } = useI18n();

  const [stageFilter, setStageFilter] = useState<'all' | CommissionStage | 'Expenses' | 'Projections'>('all');
  const [createOpen, setCreateOpen] = useState(false);

  const [entryBrandId, setEntryBrandId] = useState(state.brands[0]?.id ?? '');
  const [entryPlatform, setEntryPlatform] = useState('Amazon Associates BR');
  const [entryDesc, setEntryDesc] = useState('');
  const [entryType, setEntryType] = useState<FinanceEntryType>('Commission');
  const [entryStage, setEntryStage] = useState<CommissionStage>('Pending');
  const [entryAmount, setEntryAmount] = useState('1200');
  const [entryCurrency, setEntryCurrency] = useState<CurrencyCode>('BRL');
  const [entryDate, setEntryDate] = useState('2026-11-18');
  const [entryProjection, setEntryProjection] = useState(false);
  const [entryIsTest, setEntryIsTest] = useState(false);

  const currency = state.settings.baseCurrency;
  const summary = calculateFinanceSummary(state.financeEntries, currency, {
    brandId: globalBrandFilter,
    period: globalPeriodFilter,
    excludeTest: excludeTestData,
  });

  const visibleEntries = state.financeEntries.filter((e) => {
    if (excludeTestData && e.isTest) return false;
    if (globalBrandFilter !== 'all' && e.brandId !== globalBrandFilter) return false;
    if (stageFilter === 'Projections') return Boolean(e.isProjection);
    if (e.isProjection && stageFilter !== 'all') return false;
    if (stageFilter === 'Expenses') return e.type === 'Expense' || e.type === 'Reinvestment';
    if (stageFilter === 'Pending' || stageFilter === 'Confirmed' || stageFilter === 'Received') {
      return !e.isProjection && (e.type === 'Commission' || e.type === 'DirectRevenue') && e.stage === stageFilter;
    }
    return true;
  });

  const platforms = Array.from(
    new Set(
      state.financeEntries
        .filter((e) => !e.isProjection && (!excludeTestData || !e.isTest))
        .map((e) => localizeFinanceEntry(e, lang).platform)
    )
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('finance.title')}
        subtitle={t('finance.subtitle')}
        actions={
          <>
            <label className="inline-flex items-center gap-2 px-3 py-2 text-xs rounded-md border border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20]">
              <input
                type="checkbox"
                checked={!excludeTestData}
                onChange={(e) => setExcludeTestData(!e.target.checked)}
                className="accent-[#315FEA]"
              />
              <span>{t('finance.includeTest')}</span>
            </label>
            <SegmentedControl
              ariaLabel={t('finance.currencySwitchAria')}
              value={currency}
              onChange={(c) => setBaseCurrency(c as CurrencyCode)}
              options={[
                { value: 'BRL', label: 'BRL (R$)' },
                { value: 'USD', label: 'USD ($)' },
                { value: 'EUR', label: 'EUR (€)' },
              ]}
            />
            <button
              type="button"
              onClick={() => setCreateOpen(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
            >
              <Plus className="w-3.5 h-3.5" aria-hidden="true" />
              <span>{t('finance.newEntry')}</span>
            </button>
          </>
        }
      />

      {/* Mandatory 3-Stage Separation + Realized Reinvestment Budget */}
      <section aria-label={t('finance.kpiSectionAria')} className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricBlock
          label={t('finance.kpi.pending')}
          value={fmtCurrency(summary.pendingCommissions, currency)}
          helper={t('finance.kpi.pendingHelper')}
          tone="amber"
        />
        <MetricBlock
          label={t('finance.kpi.confirmed')}
          value={fmtCurrency(summary.confirmedCommercialResult, currency)}
          helper={t('finance.kpi.confirmedHelper', {
            amount: fmtCurrency(summary.confirmedAwaitingPayout, currency),
          })}
          tone="cobalt"
        />
        <MetricBlock
          label={t('finance.kpi.budget')}
          value={fmtCurrency(summary.availableReinvestmentBudget, currency)}
          helper={t('finance.kpi.budgetHelper', {
            amount: fmtCurrency(summary.receivedCashIn, currency),
          })}
          tone="emerald"
        />
        <MetricBlock
          label={t('finance.kpi.projections')}
          value={fmtCurrency(summary.projectedFutureRevenue, currency)}
          helper={t('finance.kpi.projectionsHelper')}
          tone="neutral"
        />
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        <SurfacePanel className="lg:col-span-7">
          <h2 className="font-display text-sm font-semibold mb-3">
            {t('finance.byPlatformTitle')}
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">{t('finance.col.platform')}</th>
                  <th className="py-2 pr-4 text-right">{t('finance.col.pending')}</th>
                  <th className="py-2 pr-4 text-right">{t('finance.col.confirmed')}</th>
                  <th className="py-2 text-right">{t('finance.col.received')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {platforms.map((plat) => {
                  const rows = state.financeEntries.filter(
                    (e) =>
                      !e.isProjection &&
                      (!excludeTestData || !e.isTest) &&
                      localizeFinanceEntry(e, lang).platform === plat &&
                      (globalBrandFilter === 'all' || e.brandId === globalBrandFilter)
                  );
                  const sumStage = (st: CommissionStage) =>
                    rows
                      .filter(
                        (r) =>
                          (r.type === 'Commission' || r.type === 'DirectRevenue') &&
                          r.stage === st
                      )
                      .reduce((acc, r) => acc + convertCurrency(r.amount, r.currency, currency), 0);

                  const pend = sumStage('Pending');
                  const conf = sumStage('Confirmed');
                  const rec = sumStage('Received');
                  if (pend + conf + rec === 0) return null;

                  return (
                    <tr key={plat}>
                      <td className="py-2.5 pr-4 font-medium">{plat}</td>
                      <td className="py-2.5 pr-4 text-right font-mono tabular-nums text-amber-700 dark:text-amber-400">
                        {fmtCurrency(pend, currency)}
                      </td>
                      <td className="py-2.5 pr-4 text-right font-mono tabular-nums text-[#315FEA] dark:text-[#7FA0FF]">
                        {fmtCurrency(conf, currency)}
                      </td>
                      <td className="py-2.5 text-right font-mono tabular-nums text-emerald-700 dark:text-emerald-400 font-medium">
                        {fmtCurrency(rec, currency)}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </SurfacePanel>

        <SurfacePanel className="lg:col-span-5 space-y-4">
          <h2 className="font-display text-sm font-semibold">
            {t('finance.outflowsTitle')}
          </h2>
          <div className="grid grid-cols-2 gap-3 text-xs">
            <div className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <div className="text-[#525B68] dark:text-[#AEB7C2]">
                {t('finance.expensesRealized')}
              </div>
              <div className="mt-1 font-mono tabular-nums text-base font-semibold">
                {fmtCurrency(summary.expensesCashOut, currency)}
              </div>
            </div>
            <div className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <div className="text-[#525B68] dark:text-[#AEB7C2]">
                {t('finance.reinvestments')}
              </div>
              <div className="mt-1 font-mono tabular-nums text-base font-semibold">
                {fmtCurrency(summary.reinvestmentsCashOut, currency)}
              </div>
            </div>
          </div>

          <div className="pt-2 border-t border-black/10 dark:border-white/10 text-xs space-y-1.5">
            <div className="font-medium">{t('finance.fxTitle')}</div>
            <div className="flex justify-between font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
              <span>{t('finance.fxUsd')}</span>
              <span>{fmtCurrency(FX_TO_BRL.USD, 'BRL')}</span>
            </div>
            <div className="flex justify-between font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
              <span>{t('finance.fxEur')}</span>
              <span>{fmtCurrency(FX_TO_BRL.EUR, 'BRL')}</span>
            </div>
          </div>
        </SurfacePanel>
      </div>

      {/* Ledger Table */}
      <div className="space-y-3">
        <SegmentedControl
          ariaLabel={t('finance.filterAria')}
          value={stageFilter}
          onChange={(v) => setStageFilter(v as typeof stageFilter)}
          options={[
            { value: 'all', label: t('finance.filter.all') },
            { value: 'Pending', label: t('finance.filter.pending') },
            { value: 'Confirmed', label: t('finance.filter.confirmed') },
            { value: 'Received', label: t('finance.filter.received') },
            { value: 'Expenses', label: t('finance.filter.expenses') },
            { value: 'Projections', label: t('finance.filter.projections') },
          ]}
        />

        <SurfacePanel padding="none" className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 bg-black/[0.02] dark:bg-white/[0.02] text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-3 pl-4 pr-3">{t('finance.table.date')}</th>
                  <th className="py-3 px-3">{t('finance.table.desc')}</th>
                  <th className="py-3 px-3">{t('finance.table.brandPlatform')}</th>
                  <th className="py-3 px-3">{t('finance.table.stage')}</th>
                  <th className="py-3 px-3 text-right">{t('finance.table.originalFx')}</th>
                  <th className="py-3 pl-3 pr-4 text-right">
                    {t('finance.table.converted', { currency })}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {visibleEntries.map((rawEntry) => {
                  const e = localizeFinanceEntry(rawEntry, lang);
                  const brand = state.brands.find((b) => b.id === e.brandId);
                  const converted = convertCurrency(e.amount, e.currency, currency);
                  const isOutflow = e.type === 'Expense' || e.type === 'Reinvestment';
                  return (
                    <tr key={e.id} className="hover:bg-black/[0.02] dark:hover:bg-white/[0.02]">
                      <td className="py-3 pl-4 pr-3 font-mono tabular-nums text-[11px] text-[#525B68] dark:text-[#AEB7C2] whitespace-nowrap">
                        {fmtDate(e.date)}
                      </td>
                      <td className="py-3 px-3 font-medium">
                        {e.description}
                        {e.isProjection && (
                          <span className="ml-2 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                            {t('finance.tag.projection')}
                          </span>
                        )}
                        {e.isTest && (
                          <span className="ml-2 font-mono text-[11px] text-amber-600 dark:text-amber-400">
                            {t('finance.tag.test')}
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-3 text-[#525B68] dark:text-[#AEB7C2]">
                        {brand?.name} · {e.platform}
                      </td>
                      <td className="py-3 px-3">
                        <StatusLabel
                          status={
                            e.isProjection
                              ? t('finance.stageProjection')
                              : labelCommissionStage(e.stage, lang)
                          }
                          statusKey={e.isProjection ? 'draft' : e.stage}
                        />
                      </td>
                      <td className="py-3 px-3 text-right font-mono tabular-nums whitespace-nowrap">
                        <div>
                          {isOutflow ? '-' : ''}
                          {fmtCurrency(e.amount, e.currency)}
                        </div>
                        {e.fxSource && (
                          <div className="text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                            {e.fxSource}
                          </div>
                        )}
                      </td>
                      <td
                        className={`py-3 pl-3 pr-4 text-right font-mono tabular-nums font-semibold whitespace-nowrap ${
                          isOutflow
                            ? 'text-rose-600 dark:text-rose-400'
                            : e.stage === 'Received' && !e.isProjection
                            ? 'text-emerald-700 dark:text-emerald-400'
                            : ''
                        }`}
                      >
                        {isOutflow ? '-' : ''}
                        {fmtCurrency(converted, currency)}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </SurfacePanel>
      </div>

      <ModalDialog
        open={createOpen}
        title={t('finance.modal.title')}
        subtitle={t('finance.modal.subtitle')}
        onClose={() => setCreateOpen(false)}
      >
        <form
          className="space-y-4 text-xs"
          onSubmit={(e) => {
            e.preventDefault();
            if (!entryDesc.trim()) return;
            addFinanceEntry({
              brandId: entryBrandId,
              platform: entryPlatform.trim() || (lang === 'EN-US' ? 'Demo Platform' : 'Plataforma Demo'),
              description: entryDesc.trim(),
              type: entryType,
              stage: entryType === 'Expense' || entryType === 'Reinvestment' ? 'Received' : entryStage,
              amount: Math.max(0, Number(entryAmount) || 0),
              currency: entryCurrency,
              fxRateToBRL: FX_TO_BRL[entryCurrency],
              fxSource:
                entryCurrency === 'BRL'
                  ? lang === 'EN-US'
                    ? 'Native BRL'
                    : 'Nativo BRL'
                  : lang === 'EN-US'
                  ? 'Demo Reference'
                  : 'Referência Demo',
              date: entryDate,
              isProjection: entryProjection,
              isTest: entryIsTest,
            });
            setCreateOpen(false);
            setEntryDesc('');
          }}
        >
          <div>
            <label htmlFor="fin-desc-input" className="block font-medium mb-1">
              {t('finance.modal.descReq')}
            </label>
            <input
              id="fin-desc-input"
              required
              value={entryDesc}
              onChange={(e) => setEntryDesc(e.target.value)}
              placeholder={t('finance.modal.descPlaceholder')}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label htmlFor="fin-brand-select" className="block font-medium mb-1">
                {t('finance.modal.brand')}
              </label>
              <select
                id="fin-brand-select"
                value={entryBrandId}
                onChange={(e) => setEntryBrandId(e.target.value)}
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
              <label htmlFor="fin-platform-input" className="block font-medium mb-1">
                {t('finance.modal.platformOrigin')}
              </label>
              <input
                id="fin-platform-input"
                value={entryPlatform}
                onChange={(e) => setEntryPlatform(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label htmlFor="fin-type-select" className="block font-medium mb-1">
                {t('finance.modal.type')}
              </label>
              <select
                id="fin-type-select"
                value={entryType}
                onChange={(e) => setEntryType(e.target.value as FinanceEntryType)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="Commission">{labelFinanceType('Commission', lang)}</option>
                <option value="DirectRevenue">{labelFinanceType('DirectRevenue', lang)}</option>
                <option value="Expense">{labelFinanceType('Expense', lang)}</option>
                <option value="Reinvestment">{labelFinanceType('Reinvestment', lang)}</option>
              </select>
            </div>
            <div>
              <label htmlFor="fin-stage-select" className="block font-medium mb-1">
                {t('finance.modal.stage')}
              </label>
              <select
                id="fin-stage-select"
                value={entryStage}
                disabled={entryType === 'Expense' || entryType === 'Reinvestment'}
                onChange={(e) => setEntryStage(e.target.value as CommissionStage)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20] disabled:opacity-50"
              >
                <option value="Pending">{t('finance.modal.stagePendingOpt')}</option>
                <option value="Confirmed">{t('finance.modal.stageConfirmedOpt')}</option>
                <option value="Received">{t('finance.modal.stageReceivedOpt')}</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label htmlFor="fin-amount-input" className="block font-medium mb-1">
                {t('finance.modal.amount')}
              </label>
              <input
                id="fin-amount-input"
                type="number"
                step="0.01"
                value={entryAmount}
                onChange={(e) => setEntryAmount(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
            <div>
              <label htmlFor="fin-curr-select" className="block font-medium mb-1">
                {t('finance.modal.currency')}
              </label>
              <select
                id="fin-curr-select"
                value={entryCurrency}
                onChange={(e) => setEntryCurrency(e.target.value as CurrencyCode)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="BRL">BRL</option>
                <option value="USD">USD</option>
                <option value="EUR">EUR</option>
              </select>
            </div>
            <div>
              <label htmlFor="fin-date-input" className="block font-medium mb-1">
                {t('finance.modal.date')}
              </label>
              <input
                id="fin-date-input"
                type="date"
                value={entryDate}
                onChange={(e) => setEntryDate(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
          </div>
          <div className="space-y-2">
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={entryProjection}
                onChange={(e) => setEntryProjection(e.target.checked)}
                className="accent-[#315FEA]"
              />
              <span>{t('finance.modal.isProjection')}</span>
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={entryIsTest}
                onChange={(e) => setEntryIsTest(e.target.checked)}
                className="accent-[#315FEA]"
              />
              <span>{t('finance.modal.isTest')}</span>
            </label>
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
              {t('finance.modal.submit')}
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};

