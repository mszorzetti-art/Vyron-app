import React, { useState } from 'react';
import { Download } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import {
  calculateFinanceSummary,
  computeBrandRollups,
  computeOperationalEfficiency,
  convertCurrency,
  formatCompactNumber,
  formatCurrency,
} from '../utils/vyronRules';
import { DualLineChart, HorizontalBarComparison } from '../components/Charts';
import { MetricBlock, PageHeader, SegmentedControl, SurfacePanel } from '../components/ui';

export const AnalyticsView: React.FC = () => {
  const { state, globalBrandFilter, globalPeriodFilter, excludeTestData } = useVyron();
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
    { label: 'Sem 1', primary: Math.round(totalTraffic * 0.19), secondary: Math.round(totalConversions * 0.18) * 100 },
    { label: 'Sem 2', primary: Math.round(totalTraffic * 0.23), secondary: Math.round(totalConversions * 0.22) * 100 },
    { label: 'Sem 3', primary: Math.round(totalTraffic * 0.27), secondary: Math.round(totalConversions * 0.28) * 100 },
    { label: 'Sem 4', primary: Math.round(totalTraffic * 0.31), secondary: Math.round(totalConversions * 0.32) * 100 },
  ];

  const geoBreakdown = [
    { id: 'br', label: 'Brasil', sublabel: 'Apex & Veloce (CDC/CONAR)', value: 44, formattedValue: '44%' },
    { id: 'us', label: 'Estados Unidos', sublabel: 'Nordic & Kinetix', value: 33, formattedValue: '33%' },
    { id: 'eu', label: 'França / União Europeia', sublabel: 'Piloto UE (Loi 2023-451)', value: 16, formattedValue: '16%' },
    { id: 'other', label: 'Outros Mercados', sublabel: 'Tráfego orgânico global', value: 7, formattedValue: '7%' },
  ];

  const langBreakdown = [
    { id: 'en', label: 'EN-US (Inglês)', sublabel: 'Nordic Desk + Kinetix', value: 54, formattedValue: '54%' },
    { id: 'pt', label: 'PT-BR (Português)', sublabel: 'Apex Hardware + Veloce', value: 46, formattedValue: '46%' },
  ];

  const handleExportReport = () => {
    const csvRows = [
      ['Marca', 'Estagio', 'Views 30d', 'Produtos Aprovados', `Comercial Confirmado (${currency})`].join(','),
      ...brandRollups.map((r) =>
        [
          `"${r.brand.name}"`,
          `"${r.brand.validationStage}"`,
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
    setExportNotice(`Relatório CSV gerado (${globalPeriodFilter}).`);
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Analytics & Inteligência"
        subtitle="Atribuição por peça explicitamente rotulada [Em investigação] até validação V1–V5, além de eficiência operacional (Dimensão 2)."
        actions={
          <button
            type="button"
            onClick={handleExportReport}
            className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
          >
            <Download className="w-3.5 h-3.5" aria-hidden="true" />
            <span>Exportar Relatório CSV</span>
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
          label="Tráfego Total (Canais 30d)"
          value={formatCompactNumber(totalTraffic)}
          helper={`Janela ${globalPeriodFilter}`}
          tone="cobalt"
        />
        <MetricBlock
          label="Conversões (Estimativa V1–V5)"
          value={`${totalConversions}`}
          helper={`${formatCompactNumber(totalClicks)} cliques · Conv. est. ${conversionRate.toFixed(2)}%`}
        />
        <MetricBlock
          label="Dim. 2 · Retorno / Hora Humana"
          value={
            efficiency.realizedCashPerHour !== null
              ? `${formatCurrency(efficiency.realizedCashPerHour, currency)}/h`
              : 'N/D'
          }
          helper={`${efficiency.totalHumanHours.toFixed(1)}h humanas no escopo`}
          tone="emerald"
        />
        <MetricBlock
          label="Receita Confirmada / 1k Views"
          value={formatCurrency(
            totalTraffic > 0 ? (finance.confirmedCommercialResult / totalTraffic) * 1000 : 0,
            currency
          )}
          helper="RPM comercial consolidado (12.1.1)"
        />
      </div>

      {/* Trends + Geographic / Language */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        <SurfacePanel className="lg:col-span-7">
          <h2 className="font-display text-sm font-semibold mb-1">
            Tendência de Tráfego e Conversões Estimadas
          </h2>
          <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] mb-4">
            Evolução semanal consolidada entre canais e links rastreados por src
          </p>
          <DualLineChart
            data={trafficSeries}
            primaryLabel="Tráfego (Views)"
            secondaryLabel="Índice Conversões (x100)"
            formatValue={(v) => formatCompactNumber(v)}
          />
        </SurfacePanel>

        <SurfacePanel className="lg:col-span-5 space-y-4">
          <div className="flex items-center justify-between gap-2">
            <h2 className="font-display text-sm font-semibold">
              Análise Geográfica & Idioma
            </h2>
            <SegmentedControl
              ariaLabel="Alternar geografia ou idioma"
              value={geoTab}
              onChange={(v) => setGeoTab(v as 'geo' | 'lang')}
              options={[
                { value: 'geo', label: 'Região' },
                { value: 'lang', label: 'Idioma' },
              ]}
            />
          </div>
          <HorizontalBarComparison items={geoTab === 'geo' ? geoBreakdown : langBreakdown} />
        </SurfacePanel>
      </div>

      {/* Content & Product Attribution Table (Rule 12.4: Always labeled Estimate [Em investigação]) */}
      <SurfacePanel>
        <div className="flex flex-wrap items-center justify-between gap-2 mb-3">
          <div>
            <h2 className="font-display text-sm font-semibold">
              Atribuição por Peça (Regra 12.4 — Tracking src / UTM)
            </h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
              Valores por peça são tratados estritamente como estimativa até conclusão do protocolo V1–V5 (Bloco 9).
            </p>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                <th className="py-2 pr-4">Conteúdo Publicado</th>
                <th className="py-2 pr-4">Tag src</th>
                <th className="py-2 pr-4">Atribuição</th>
                <th className="py-2 pr-4 text-right">Views / Ret. 30s</th>
                <th className="py-2 pr-4 text-right">Cliques</th>
                <th className="py-2 pr-4 text-right">Conv. Est.</th>
                <th className="py-2 text-right">Receita Est. ({currency})</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
              {filteredContents.map((c) => {
                const rev = c.metrics
                  ? convertCurrency(c.metrics.revenueGenerated, c.metrics.currency, currency)
                  : 0;
                return (
                  <tr key={c.id}>
                    <td className="py-2.5 pr-4 font-medium">{c.title}</td>
                    <td className="py-2.5 pr-4 font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {c.metrics?.trackingSrc ?? '-'}
                    </td>
                    <td className="py-2.5 pr-4 font-mono text-[11px] text-amber-700 dark:text-amber-400">
                      {c.metrics?.attributionStatus ?? 'Estimativa [Em investigação]'}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {formatCompactNumber(c.metrics?.views ?? 0)} ({c.metrics?.retention30sPct ?? 0}%)
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {formatCompactNumber(c.metrics?.clicks ?? 0)}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {c.metrics?.conversions ?? 0}
                    </td>
                    <td className="py-2.5 text-right font-mono tabular-nums font-medium text-emerald-700 dark:text-emerald-400">
                      {formatCurrency(rev, currency)}
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
            Anomalias Detectadas no Período
          </h2>
          <ul className="space-y-2.5 text-xs">
            <li className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <div className="font-medium text-emerald-700 dark:text-emerald-400">
                +18,3% Alcance acima da baseline · Pinterest (Nordic Desk Studio)
              </div>
              <p className="mt-1 text-[#525B68] dark:text-[#AEB7C2]">
                Pins arquitetônicos do ScreenBar Halo elevaram CTR de saída em 2,3x nas últimas 3 semanas.
              </p>
            </li>
            <li className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
              <div className="font-medium text-amber-700 dark:text-amber-400">
                Queda de cadência · TikTok (@nordic.desk)
              </div>
              <p className="mt-1 text-[#525B68] dark:text-[#AEB7C2]">
                Sincronização interrompida por token demo expirado; dados dos últimos 2 dias pendentes.
              </p>
            </li>
          </ul>
        </SurfacePanel>

        <SurfacePanel className="space-y-3">
          <h2 className="font-display text-sm font-semibold">
            Preparação Estrutural para Machine Learning Futuro (Fase F)
          </h2>
          <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] leading-relaxed">
            Camada planejada (não executada no MVP): histórico de decisões humanas, categorias de rejeição (Tom, Precisão/Fonte, Conformidade), hashes SHA-256 e resultados financeiros líquidos compõem o dataset rotulado.
          </p>
          <div className="grid grid-cols-3 gap-3 pt-2 border-t border-black/10 dark:border-white/10 text-xs">
            <div>
              <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Amostras Rotuladas</div>
              <div className="font-mono tabular-nums font-semibold mt-0.5">
                {state.products.reduce((s, p) => s + p.decisions.length, 0) + state.activities.length} eventos
              </div>
            </div>
            <div>
              <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Chaves Cruzadas</div>
              <div className="font-mono tabular-nums font-semibold mt-0.5">Brand · Prod · Hash</div>
            </div>
            <div>
              <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Estado do Pipeline</div>
              <div className="font-mono font-semibold mt-0.5 text-[#AEB7C2]">Planejado (Bloco 10+)</div>
            </div>
          </div>
        </SurfacePanel>
      </div>
    </div>
  );
};
