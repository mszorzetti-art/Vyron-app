import React, { useState } from 'react';
import { ArrowLeft, ExternalLink, Plus, Search } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import {
  ComplianceState,
  CurrencyCode,
  ProductQualityGrade,
  ProductStatus,
} from '../types/vyron';
import {
  formatCurrency,
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
    const product = state.products.find((p) => p.id === selectedProductId);
    if (!product) {
      return (
        <EmptyState
          title="Produto não encontrado"
          description="O item selecionado não está disponível no catálogo."
          actionLabel="Voltar para Produtos"
          onAction={() => navigate('products', { productId: null })}
        />
      );
    }

    const brand = state.brands.find((b) => b.id === product.brandId);
    const brandChannels = state.channels.filter(
      (c) => c.brandId === product.brandId || product.linkedBrandIds.includes(c.brandId)
    );
    const linkedContents = state.contents.filter((c) => c.productId === product.id);
    const scoreEval = scoreProductV61(product);

    const handleConfirmDecision = (e: React.FormEvent) => {
      e.preventDefault();
      if (!decisionTargetStatus) return;
      if (!justification.trim()) {
        setDecisionError('Informe uma justificativa objetiva para registrar no histórico.');
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
            <span>Voltar para Lista de Produtos</span>
          </button>
          <div className="flex items-center gap-3">
            {product.isTest && (
              <span className="font-mono text-[11px] text-amber-600 dark:text-amber-400">
                is_test=true
              </span>
            )}
            <StatusLabel status={product.status} />
          </div>
        </div>

        <PageHeader
          title={product.name}
          subtitle={`Catálogo Compartilhado (${product.platform} · ${product.externalId}) · Moeda nativa ${product.currency} · Mercado ${product.complianceMarket}`}
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
                  Aprovar Produto
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
                  Rejeitar
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
                  Arquivar
                </button>
              )}
            </>
          }
        />

        {/* Commercial Indicators (preserving null unknowns) */}
        <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
          <MetricBlock
            label="Score-6.1 (v0-hipotese)"
            value={
              product.opportunityScore !== null ? `${product.opportunityScore}/100` : 'Desconhecido'
            }
            helper={scoreEval.explanation}
            tone="cobalt"
          />
          <MetricBlock
            label="Preço de Referência"
            value={product.price !== null ? formatCurrency(product.price, product.currency) : 'Desconhecido (null)'}
            helper={`Comissão: ${product.commissionRatePct !== null ? `${product.commissionRatePct}%` : 'Desconhecida'}`}
          />
          <MetricBlock
            label="EPC Estimado"
            value={
              product.epcValue !== null
                ? formatCurrency(product.epcValue, product.currency)
                : 'Desconhecido (null)'
            }
            helper={
              product.cpaValue !== null
                ? `CPA fixo: ${formatCurrency(product.cpaValue, product.currency)}`
                : `Confiança: ${product.dataConfidence}`
            }
          />
          <MetricBlock
            label="Janela de Cookies"
            value={
              product.cookieWindowDays !== null
                ? `${product.cookieWindowDays} dias`
                : 'Desconhecido (null)'
            }
            helper={`Competição: ${product.competitionLevel}`}
          />
          <MetricBlock
            label="Qualidade & Compliance"
            value={`Nota ${product.qualityGrade ?? 'N/D'} · ${product.complianceState}`}
            helper={`${linkedContents.length} conteúdo(s) vinculado(s)`}
          />
        </div>

        {/* Separated Governance: Quality Grade, Compliance State, Shared Brands */}
        <SurfacePanel className="grid grid-cols-1 md:grid-cols-3 gap-5 text-xs">
          <div>
            <label className="block font-semibold mb-1.5">
              Qualidade Conceitual (A / B / C)
            </label>
            <p className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mb-2">
              Separado do estado comercial e de compliance.
            </p>
            <select
              aria-label="Qualidade do produto"
              value={product.qualityGrade ?? ''}
              onChange={(e) =>
                updateProductGovernance(product.id, {
                  qualityGrade: (e.target.value || null) as ProductQualityGrade | null,
                })
              }
              className="w-full h-9 px-2.5 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
            >
              <option value="A">Nota A — Recomendado sem ressalvas</option>
              <option value="B">Nota B — Bom com limitações claras</option>
              <option value="C">Nota C — Baixa durabilidade/retorno</option>
            </select>
          </div>

          <div>
            <label className="block font-semibold mb-1.5">
              Compliance Intelligence ({product.complianceMarket})
            </label>
            <p className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mb-2">
              Estado regulatório independente da pontuação.
            </p>
            <select
              aria-label="Compliance do produto"
              value={product.complianceState}
              onChange={(e) =>
                updateProductGovernance(product.id, {
                  complianceState: e.target.value as ComplianceState,
                })
              }
              className="w-full h-9 px-2.5 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20] font-mono"
            >
              <option value="APPROVED">APPROVED</option>
              <option value="PENDING">PENDING</option>
              <option value="BLOCKED">BLOCKED</option>
              <option value="NOT_APPLICABLE">NOT_APPLICABLE</option>
            </select>
          </div>

          <div>
            <div className="font-semibold mb-1.5">
              Vínculo em Marcas (Catálogo Compartilhado)
            </div>
            <p className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] mb-2">
              Deduplicado por ({product.platform}, {product.externalId}); sem brand_id único no schema.
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
              Fontes, Evidências & Inteligência Comercial
            </h2>
            {product.evidence.length === 0 ? (
              <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                Nenhuma evidência externa anexada ainda.
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
                        Verificado {ev.verifiedAt}
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
                Originar Pauta no Content Studio ({brand?.name})
              </h3>
              <div className="flex flex-wrap items-center gap-2.5">
                <select
                  aria-label="Selecionar canal para pauta"
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
                  aria-label="Formato do conteúdo"
                  value={contentFormat}
                  onChange={(e) => setContentFormat(e.target.value as 'Long-form' | 'Shorts')}
                  className="h-8 px-2.5 text-xs rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
                >
                  <option value="Long-form">Long-form</option>
                  <option value="Shorts">Shorts</option>
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
                  Gerar Pauta no Studio
                </button>
              </div>
            </div>
          </SurfacePanel>

          <SurfacePanel className="lg:col-span-5">
            <h2 className="font-display text-sm font-semibold mb-3">
              Histórico e Justificativas de Decisão
            </h2>
            {product.decisions.length === 0 ? (
              <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                Nenhuma decisão registrada ainda. Produto em fila de análise inicial.
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
                        {d.previousStatus} → {d.newStatus}
                      </span>
                      <span className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {d.timestamp.slice(0, 10)}
                      </span>
                    </div>
                    <p className="text-[#525B68] dark:text-[#AEB7C2]">{d.justification}</p>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      Por {d.actor}
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </SurfacePanel>
        </div>

        <ModalDialog
          open={Boolean(decisionTargetStatus)}
          title={`Alterar status para ${decisionTargetStatus}`}
          subtitle="Toda decisão comercial exige justificativa registrada para auditoria."
          onClose={() => setDecisionTargetStatus(null)}
        >
          <form onSubmit={handleConfirmDecision} className="space-y-4 text-xs">
            <div>
              <label className="block font-medium mb-1">Justificativa da Decisão *</label>
              <textarea
                required
                rows={3}
                value={justification}
                onChange={(e) => {
                  setJustification(e.target.value);
                  setDecisionError('');
                }}
                placeholder="Ex.: EPC validado acima do piso operacional e janela de cookie favorável..."
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
                Cancelar
              </button>
              <button
                type="submit"
                className="px-4 py-2 rounded bg-[#315FEA] text-white font-medium hover:bg-[#274FC9]"
              >
                Confirmar Decisão
              </button>
            </div>
          </form>
        </ModalDialog>
      </div>
    );
  }

  // LIST VIEW
  const visibleProducts = state.products.filter((p) => {
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

  const comparedProducts = state.products.filter((p) => compareIds.includes(p.id));
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
              <th className="py-3 pl-4 pr-2 w-8">Comp.</th>
              <th className="py-3 px-3">Produto / Catálogo</th>
              <th className="py-3 px-3">Marcas</th>
              <th className="py-3 px-3">Qualidade & Compliance</th>
              <th className="py-3 px-3 text-right">Preço ({items[0]?.currency})</th>
              <th className="py-3 px-3 text-right">Comissão / EPC</th>
              <th className="py-3 px-3 text-right">Cookie</th>
              <th className="py-3 px-3 text-right">score-6.1</th>
              <th className="py-3 px-3">Estado</th>
              <th className="py-3 pl-3 pr-4 text-right">Ação</th>
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
                      aria-label={`Comparar ${p.name}`}
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
                      {p.isTest ? ' · is_test' : ''}
                    </div>
                  </td>
                  <td className="py-3 px-3 text-[#525B68] dark:text-[#AEB7C2] max-w-[160px] truncate">
                    {linkedNames || '-'}
                  </td>
                  <td className="py-3 px-3">
                    <div className="font-mono text-[11px]">
                      Nota {p.qualityGrade ?? 'N/D'} · {p.complianceMarket}
                    </div>
                    <StatusLabel status={p.complianceState} />
                  </td>
                  <td className="py-3 px-3 text-right font-mono tabular-nums whitespace-nowrap">
                    {p.price !== null ? formatCurrency(p.price, p.currency) : 'null'}
                  </td>
                  <td className="py-3 px-3 text-right font-mono tabular-nums whitespace-nowrap">
                    <div>{p.commissionRatePct !== null ? `${p.commissionRatePct}%` : 'null'}</div>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      EPC {p.epcValue !== null ? formatCurrency(p.epcValue, p.currency) : 'Desconhecido'}
                    </div>
                  </td>
                  <td className="py-3 px-3 text-right font-mono tabular-nums whitespace-nowrap">
                    {p.cookieWindowDays !== null ? `${p.cookieWindowDays}d` : 'null'}
                  </td>
                  <td className="py-3 px-3 text-right font-mono tabular-nums font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                    {p.opportunityScore !== null ? p.opportunityScore : 'null'}
                  </td>
                  <td className="py-3 px-3">
                    <StatusLabel status={p.status} />
                  </td>
                  <td className="py-3 pl-3 pr-4 text-right whitespace-nowrap">
                    <button
                      type="button"
                      onClick={() => navigate('products', { productId: p.id })}
                      className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
                    >
                      Analisar
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
        title="Products & Intelligence"
        subtitle="Catálogo compartilhado (platform, external_id), score-6.1 (v0-hipotese) por moeda nativa e preservação explícita de campos null."
        actions={
          <div className="flex flex-wrap items-center gap-2.5">
            <label className="inline-flex items-center gap-2 px-3 py-2 text-xs rounded-md border border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20]">
              <input
                type="checkbox"
                checked={!excludeTestData}
                onChange={(e) => setExcludeTestData(!e.target.checked)}
                className="accent-[#315FEA]"
              />
              <span>Exibir registros is_test</span>
            </label>
            <button
              type="button"
              onClick={() => setCreateOpen(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
            >
              <Plus className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Cadastrar Produto</span>
            </button>
          </div>
        }
      />

      {/* Filter & Search Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex flex-wrap items-center gap-3">
          <SegmentedControl
            ariaLabel="Modo de exibição do ranking"
            value={viewMode}
            onChange={(v) => setViewMode(v as 'by_currency' | 'catalog')}
            options={[
              { value: 'by_currency', label: 'Ranking por Moeda (score-6.1)' },
              { value: 'catalog', label: 'Lista Única' },
            ]}
          />
          <SegmentedControl
            ariaLabel="Filtrar produtos por estado"
            value={statusFilter}
            onChange={(v) => setStatusFilter(v as 'all' | ProductStatus)}
            options={[
              { value: 'all', label: 'Todos' },
              { value: 'Candidate', label: 'Candidate' },
              { value: 'Approved', label: 'Approved' },
              { value: 'Rejected', label: 'Rejected' },
              { value: 'Archived', label: 'Archived' },
            ]}
          />
        </div>

        <div className="relative w-full sm:w-64">
          <Search className="w-3.5 h-3.5 text-[#AEB7C2] absolute left-3 top-1/2 -translate-y-1/2" aria-hidden="true" />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Buscar nome, plataforma ou external_id..."
            aria-label="Buscar produto ou plataforma"
            className="w-full h-9 pl-8 pr-3 text-xs rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
          />
        </div>
      </div>

      {/* Product Side-by-Side Comparison Panel */}
      {comparedProducts.length >= 2 && (
        <SurfacePanel>
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-display text-sm font-semibold">
              Comparação Lado a Lado ({comparedProducts.length} produtos)
            </h2>
            <button
              type="button"
              onClick={() => setCompareIds([])}
              className="text-xs text-[#525B68] dark:text-[#AEB7C2] hover:underline"
            >
              Limpar comparação
            </button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">Critério</th>
                  {comparedProducts.map((cp) => (
                    <th key={cp.id} className="py-2 pr-4 font-semibold text-[#101216] dark:text-[#F1F2F3]">
                      {cp.name} ({cp.currency})
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                <tr>
                  <td className="py-2 pr-4 text-[#525B68] dark:text-[#AEB7C2]">score-6.1</td>
                  {comparedProducts.map((cp) => (
                    <td key={cp.id} className="py-2 pr-4 font-mono tabular-nums font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                      {cp.opportunityScore !== null ? `${cp.opportunityScore}/100` : 'Desconhecido (null)'}
                    </td>
                  ))}
                </tr>
                <tr>
                  <td className="py-2 pr-4 text-[#525B68] dark:text-[#AEB7C2]">Preço / Comissão</td>
                  {comparedProducts.map((cp) => (
                    <td key={cp.id} className="py-2 pr-4 font-mono tabular-nums">
                      {cp.price !== null ? formatCurrency(cp.price, cp.currency) : 'null'} (
                      {cp.commissionRatePct !== null ? `${cp.commissionRatePct}%` : 'null'})
                    </td>
                  ))}
                </tr>
                <tr>
                  <td className="py-2 pr-4 text-[#525B68] dark:text-[#AEB7C2]">EPC / Cookie / Nota</td>
                  {comparedProducts.map((cp) => (
                    <td key={cp.id} className="py-2 pr-4 font-mono tabular-nums">
                      {cp.epcValue !== null ? formatCurrency(cp.epcValue, cp.currency) : 'null'} ·{' '}
                      {cp.cookieWindowDays !== null ? `${cp.cookieWindowDays}d` : 'null'} · Nota {cp.qualityGrade ?? 'N/D'}
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
          title="Nenhum produto encontrado"
          description="Ajuste os filtros ou cadastre um novo produto para análise."
          actionLabel="Cadastrar Produto"
          onAction={() => setCreateOpen(true)}
        />
      ) : viewMode === 'by_currency' ? (
        <div className="space-y-5">
          {currencyGroups.map((group) => (
            <div key={group.currency} className="space-y-2">
              <div className="flex items-center justify-between text-xs px-1">
                <h2 className="font-display font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  Ranking Nativo · Moeda {group.currency} ({group.items.length})
                </h2>
                <span className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  Sem conversão cambial no ranking score-6.1
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
        title="Cadastrar Produto no Catálogo Compartilhado"
        subtitle="O score-6.1 (v0-hipotese) preserva campos vazios como null (nunca 0)."
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
            <label className="block font-medium mb-1">Nome do Produto *</label>
            <input
              required
              value={prodName}
              onChange={(e) => setProdName(e.target.value)}
              placeholder="Ex.: Logitech MX Master 4"
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">Marca Principal</label>
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
              <label className="block font-medium mb-1">Categoria</label>
              <input
                value={prodCategory}
                onChange={(e) => setProdCategory(e.target.value)}
                placeholder="Ex.: Periféricos"
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">Plataforma</label>
              <input
                value={prodPlatform}
                onChange={(e) => setProdPlatform(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">Modelo de Remuneração</label>
              <select
                value={prodModel}
                onChange={(e) =>
                  setProdModel(e.target.value as 'CPA' | 'RevShare' | 'Híbrido' | 'Direto')
                }
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="RevShare">RevShare</option>
                <option value="CPA">CPA</option>
                <option value="Híbrido">Híbrido</option>
                <option value="Direto">Direto</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-2.5">
            <div>
              <label className="block font-medium mb-1">Preço</label>
              <input
                type="number"
                step="0.01"
                value={prodPrice}
                onChange={(e) => setProdPrice(e.target.value)}
                className="w-full px-2.5 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">Moeda</label>
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
              <label className="block font-medium mb-1">Comissão %</label>
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
              <label className="block font-medium mb-1">EPC Estimado (vazio = null)</label>
              <input
                type="number"
                step="0.01"
                value={prodEpc}
                onChange={(e) => setProdEpc(e.target.value)}
                placeholder="Deixe vazio se desconhecido"
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">Cookie Window dias (vazio = null)</label>
              <input
                type="number"
                value={prodCookie}
                onChange={(e) => setProdCookie(e.target.value)}
                placeholder="Deixe vazio se desconhecido"
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
            <span>Marcar como registro de teste (is_test=true)</span>
          </label>
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
              Calcular score-6.1 & Salvar
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
