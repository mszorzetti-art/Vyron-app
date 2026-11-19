import React, { useState } from 'react';
import { Plus } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { CommissionStage, CurrencyCode, FinanceEntryType } from '../types/vyron';
import {
  FX_TO_BRL,
  calculateFinanceSummary,
  convertCurrency,
  formatCurrency,
} from '../utils/vyronRules';
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
        .map((e) => e.platform)
    )
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title="Financeiro & Conciliação"
        subtitle="Regra 12.1.1: apenas caixa recebido líquido autoriza reinvestimentos; Pending, Confirmed e is_test permanecem estritamente isolados."
        actions={
          <>
            <label className="inline-flex items-center gap-2 px-3 py-2 text-xs rounded-md border border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20]">
              <input
                type="checkbox"
                checked={!excludeTestData}
                onChange={(e) => setExcludeTestData(!e.target.checked)}
                className="accent-[#315FEA]"
              />
              <span>Incluir is_test</span>
            </label>
            <SegmentedControl
              ariaLabel="Moeda de exibição financeira"
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
              <span>Novo Lançamento</span>
            </button>
          </>
        }
      />

      {/* Mandatory 3-Stage Separation + Realized Reinvestment Budget */}
      <section aria-label="Separação de estágios financeiros" className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricBlock
          label="Pending · Aguardando Validação"
          value={formatCurrency(summary.pendingCommissions, currency)}
          helper="NUNCA contabilizado como caixa ou comercial"
          tone="amber"
        />
        <MetricBlock
          label="Confirmed · Resultado Comercial (12.1.1)"
          value={formatCurrency(summary.confirmedCommercialResult, currency)}
          helper={`${formatCurrency(summary.confirmedAwaitingPayout, currency)} aprovado aguardando saque`}
          tone="cobalt"
        />
        <MetricBlock
          label="Orçamento Realizado p/ Reinvestimento"
          value={formatCurrency(summary.availableReinvestmentBudget, currency)}
          helper={`Caixa recebido ${formatCurrency(summary.receivedCashIn, currency)} menos saídas`}
          tone="emerald"
        />
        <MetricBlock
          label="Projeções Isoladas (Não-Realizado)"
          value={formatCurrency(summary.projectedFutureRevenue, currency)}
          helper="Estimativas futuras separadas do caixa"
          tone="neutral"
        />
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        <SurfacePanel className="lg:col-span-7">
          <h2 className="font-display text-sm font-semibold mb-3">
            Resultado por Plataforma (Estágios Separados)
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">Plataforma</th>
                  <th className="py-2 pr-4 text-right">Pending</th>
                  <th className="py-2 pr-4 text-right">Confirmed</th>
                  <th className="py-2 text-right">Received (Caixa)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {platforms.map((plat) => {
                  const rows = state.financeEntries.filter(
                    (e) =>
                      !e.isProjection &&
                      (!excludeTestData || !e.isTest) &&
                      e.platform === plat &&
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
                        {formatCurrency(pend, currency)}
                      </td>
                      <td className="py-2.5 pr-4 text-right font-mono tabular-nums text-[#315FEA] dark:text-[#7FA0FF]">
                        {formatCurrency(conf, currency)}
                      </td>
                      <td className="py-2.5 text-right font-mono tabular-nums text-emerald-700 dark:text-emerald-400 font-medium">
                        {formatCurrency(rec, currency)}
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
            Saídas & Parâmetros Cambiais (FX com Fonte)
          </h2>
          <div className="grid grid-cols-2 gap-3 text-xs">
            <div className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <div className="text-[#525B68] dark:text-[#AEB7C2]">Despesas Realizadas</div>
              <div className="mt-1 font-mono tabular-nums text-base font-semibold">
                {formatCurrency(summary.expensesCashOut, currency)}
              </div>
            </div>
            <div className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <div className="text-[#525B68] dark:text-[#AEB7C2]">Reinvestimentos</div>
              <div className="mt-1 font-mono tabular-nums text-base font-semibold">
                {formatCurrency(summary.reinvestmentsCashOut, currency)}
              </div>
            </div>
          </div>

          <div className="pt-2 border-t border-black/10 dark:border-white/10 text-xs space-y-1.5">
            <div className="font-medium">Taxas de Conversão Aplicadas (Relatório Consolidado)</div>
            <div className="flex justify-between font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
              <span>1 USD → BRL (PTAX Ref.)</span>
              <span>R$ {FX_TO_BRL.USD.toFixed(2)}</span>
            </div>
            <div className="flex justify-between font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
              <span>1 EUR → BRL (BCE Ref.)</span>
              <span>R$ {FX_TO_BRL.EUR.toFixed(2)}</span>
            </div>
          </div>
        </SurfacePanel>
      </div>

      {/* Ledger Table */}
      <div className="space-y-3">
        <SegmentedControl
          ariaLabel="Filtrar histórico financeiro"
          value={stageFilter}
          onChange={(v) => setStageFilter(v as typeof stageFilter)}
          options={[
            { value: 'all', label: 'Todos Lançamentos' },
            { value: 'Pending', label: 'Pending' },
            { value: 'Confirmed', label: 'Confirmed' },
            { value: 'Received', label: 'Received (Caixa)' },
            { value: 'Expenses', label: 'Despesas & Reinvest.' },
            { value: 'Projections', label: 'Projeções' },
          ]}
        />

        <SurfacePanel padding="none" className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 bg-black/[0.02] dark:bg-white/[0.02] text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-3 pl-4 pr-3">Data</th>
                  <th className="py-3 px-3">Descrição</th>
                  <th className="py-3 px-3">Marca / Plataforma</th>
                  <th className="py-3 px-3">Estágio</th>
                  <th className="py-3 px-3 text-right">Valor Original & FX</th>
                  <th className="py-3 pl-3 pr-4 text-right">Convertido ({currency})</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {visibleEntries.map((e) => {
                  const brand = state.brands.find((b) => b.id === e.brandId);
                  const converted = convertCurrency(e.amount, e.currency, currency);
                  const isOutflow = e.type === 'Expense' || e.type === 'Reinvestment';
                  return (
                    <tr key={e.id} className="hover:bg-black/[0.02] dark:hover:bg-white/[0.02]">
                      <td className="py-3 pl-4 pr-3 font-mono tabular-nums text-[11px] text-[#525B68] dark:text-[#AEB7C2] whitespace-nowrap">
                        {e.date}
                      </td>
                      <td className="py-3 px-3 font-medium">
                        {e.description}
                        {e.isProjection && (
                          <span className="ml-2 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                            (Projeção)
                          </span>
                        )}
                        {e.isTest && (
                          <span className="ml-2 font-mono text-[11px] text-amber-600 dark:text-amber-400">
                            is_test
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-3 text-[#525B68] dark:text-[#AEB7C2]">
                        {brand?.name} · {e.platform}
                      </td>
                      <td className="py-3 px-3">
                        <StatusLabel status={e.isProjection ? 'Projeção' : e.stage} />
                      </td>
                      <td className="py-3 px-3 text-right font-mono tabular-nums whitespace-nowrap">
                        <div>
                          {isOutflow ? '-' : ''}
                          {formatCurrency(e.amount, e.currency)}
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
                        {formatCurrency(converted, currency)}
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
        title="Registrar Movimento Financeiro (Demo)"
        subtitle="Nenhuma operação financeira real é executada no protótipo."
        onClose={() => setCreateOpen(false)}
      >
        <form
          className="space-y-4 text-xs"
          onSubmit={(e) => {
            e.preventDefault();
            if (!entryDesc.trim()) return;
            addFinanceEntry({
              brandId: entryBrandId,
              platform: entryPlatform.trim() || 'Plataforma Demo',
              description: entryDesc.trim(),
              type: entryType,
              stage: entryType === 'Expense' || entryType === 'Reinvestment' ? 'Received' : entryStage,
              amount: Math.max(0, Number(entryAmount) || 0),
              currency: entryCurrency,
              fxRateToBRL: FX_TO_BRL[entryCurrency],
              fxSource: entryCurrency === 'BRL' ? 'Nativo BRL' : 'Referência Demo',
              date: entryDate,
              isProjection: entryProjection,
              isTest: entryIsTest,
            });
            setCreateOpen(false);
            setEntryDesc('');
          }}
        >
          <div>
            <label className="block font-medium mb-1">Descrição *</label>
            <input
              required
              value={entryDesc}
              onChange={(e) => setEntryDesc(e.target.value)}
              placeholder="Ex.: Comissões lote Novembro Amazon BR"
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">Marca</label>
              <select
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
              <label className="block font-medium mb-1">Plataforma / Origem</label>
              <input
                value={entryPlatform}
                onChange={(e) => setEntryPlatform(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">Tipo</label>
              <select
                value={entryType}
                onChange={(e) => setEntryType(e.target.value as FinanceEntryType)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="Commission">Commission</option>
                <option value="DirectRevenue">DirectRevenue</option>
                <option value="Expense">Expense</option>
                <option value="Reinvestment">Reinvestment</option>
              </select>
            </div>
            <div>
              <label className="block font-medium mb-1">Estágio</label>
              <select
                value={entryStage}
                disabled={entryType === 'Expense' || entryType === 'Reinvestment'}
                onChange={(e) => setEntryStage(e.target.value as CommissionStage)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20] disabled:opacity-50"
              >
                <option value="Pending">Pending (Não-caixa)</option>
                <option value="Confirmed">Confirmed (Aprovado)</option>
                <option value="Received">Received (Em caixa)</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block font-medium mb-1">Valor</label>
              <input
                type="number"
                step="0.01"
                value={entryAmount}
                onChange={(e) => setEntryAmount(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">Moeda</label>
              <select
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
              <label className="block font-medium mb-1">Data</label>
              <input
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
              <span>Marcar como Projeção Futura (isolada de resultados realizados)</span>
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={entryIsTest}
                onChange={(e) => setEntryIsTest(e.target.checked)}
                className="accent-[#315FEA]"
              />
              <span>Marcar como registro de teste (is_test=true)</span>
            </label>
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => setCreateOpen(false)}
              className="px-3.5 py-2 rounded border border-black/15 dark:border-white/15"
            >
              Cancelar
            </button>
            <button
              type="submit"
              className="px-4 py-2 rounded bg-[#315FEA] text-white font-medium hover:bg-[#274FC9]"
            >
              Salvar Lançamento
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
