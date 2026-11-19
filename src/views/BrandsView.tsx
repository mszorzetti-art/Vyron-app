import React, { useState } from 'react';
import { ArrowLeft, Plus } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { Brand, BrandArchetype, BrandStatus, ValidationStage } from '../types/vyron';
import {
  computeBrandRollups,
  formatCompactNumber,
  formatCurrency,
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
  const [pillarsText, setPillarsText] = useState(
    'Ergonomia Prática, Comparativos Técnicos, Guias de Compra Transparentes'
  );
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

  // SUBPAGE: Brand Detail
  if (selectedBrandId) {
    const rollup = rollups.find((r) => r.brand.id === selectedBrandId);
    if (!rollup) {
      return (
        <EmptyState
          title="Marca não encontrada"
          description="Selecione uma marca válida no catálogo."
          actionLabel="Voltar para Marcas"
          onAction={() => navigate('brands', { brandId: null })}
        />
      );
    }

    const { brand } = rollup;
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
            <span>Voltar para Lista de Marcas</span>
          </button>
          <StatusLabel status={brand.status} />
        </div>

        <PageHeader
          title={brand.name}
          subtitle={`${brand.niche} · ${brand.market} (${brand.language}) · Fuso ${brand.timezone} · ${brand.archetype}`}
          actions={
            <>
              <button
                type="button"
                onClick={() => setEditBrand(brand)}
                className="px-3.5 py-2 text-xs font-medium rounded-md border border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20] hover:border-[#315FEA]/50 whitespace-nowrap"
              >
                Editar Marca & Estratégia
              </button>
              {brand.status !== 'Archived' ? (
                <button
                  type="button"
                  onClick={() =>
                    changeBrandStatus(
                      brand.id,
                      'Archived',
                      'Arquivada pelo proprietário via detalhe da marca.'
                    )
                  }
                  className="px-3.5 py-2 text-xs font-medium rounded-md border border-rose-500/35 text-rose-700 dark:text-rose-400 hover:bg-rose-500/10 whitespace-nowrap"
                >
                  Arquivar Marca
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() =>
                    changeBrandStatus(brand.id, 'Active', 'Reativada pelo proprietário.')
                  }
                  className="px-3.5 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
                >
                  Reativar Marca
                </button>
              )}
            </>
          }
        />

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricBlock
            label="Resultado Comercial Confirmado"
            value={formatCurrency(rollup.confirmedCommercial, currency)}
            helper={`Recebido em caixa: ${formatCurrency(rollup.receivedCash, currency)}`}
            tone="cobalt"
          />
          <MetricBlock
            label="Comissões Pendentes"
            value={formatCurrency(rollup.pendingCommissions, currency)}
            helper="Aguardando validação"
            tone="amber"
          />
          <MetricBlock
            label="Alcance em Canais (30d)"
            value={formatCompactNumber(rollup.totalViews30d)}
            helper={`${rollup.channelsCount} canais associados`}
          />
          <MetricBlock
            label="Estágio de Validação"
            value={brand.validationStage}
            helper={`${rollup.approvedProductsCount} prod. · ${rollup.publishedContentsCount}/${rollup.contentsCount} peças`}
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <SurfacePanel className="lg:col-span-5 space-y-4">
            <h2 className="font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
              Identidade, Operação & Pilares Editoriais
            </h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] leading-relaxed">
              {brand.description}
            </p>
            <div className="pt-2 border-t border-black/10 dark:border-white/10 space-y-2.5 text-xs">
              <div className="flex items-center justify-between gap-2">
                <span className="text-[#525B68] dark:text-[#AEB7C2]">Fuso IANA / Janela</span>
                <span className="font-mono text-[11px]">
                  {brand.timezone} · {brand.publishWindow}
                </span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-[#525B68] dark:text-[#AEB7C2]">Arquétipo</span>
                <span className="font-medium">{brand.archetype}</span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-[#525B68] dark:text-[#AEB7C2]">Tipografia</span>
                <span className="font-mono text-[11px]">{brand.typographyNote}</span>
              </div>
              <div className="flex items-center justify-between gap-2">
                <span className="text-[#525B68] dark:text-[#AEB7C2]">Paleta da Marca</span>
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
                  Pilares de Conteúdo ({brand.pillars.length})
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
                Canais Associados ({brandChannels.length})
              </h2>
              <button
                type="button"
                onClick={() => navigate('channels')}
                className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                Gerir Canais
              </button>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    <th className="py-2 pr-3">Canal</th>
                    <th className="py-2 pr-3">Plataforma</th>
                    <th className="py-2 pr-3 text-right">Seguidores</th>
                    <th className="py-2 pr-3 text-right">Views 30d</th>
                    <th className="py-2 text-right">Status</th>
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
                        {formatCompactNumber(ch.followers)}
                      </td>
                      <td className="py-2.5 pr-3 text-right font-mono tabular-nums">
                        {formatCompactNumber(ch.views30d)}
                      </td>
                      <td className="py-2.5 text-right">
                        <StatusLabel status={ch.integrationStatus} />
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
                Produtos do Catálogo Compartilhado ({brandProducts.length})
              </h2>
              <button
                type="button"
                onClick={() => navigate('products')}
                className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                Abrir Catálogo
              </button>
            </div>
            <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06] text-xs">
              {brandProducts.map((p) => (
                <li key={p.id} className="py-2.5 flex items-center justify-between gap-3">
                  <button
                    type="button"
                    onClick={() => navigate('products', { productId: p.id })}
                    className="text-left min-w-0 hover:text-[#315FEA]"
                  >
                    <div className="font-medium truncate">{p.name}</div>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {p.platform} · {p.currency} · Score{' '}
                      {p.opportunityScore !== null ? `${p.opportunityScore}/100` : 'null'}
                    </div>
                  </button>
                  <StatusLabel status={p.status} />
                </li>
              ))}
            </ul>
          </SurfacePanel>

          <SurfacePanel>
            <div className="flex items-center justify-between mb-3">
              <h2 className="font-display text-sm font-semibold">
                Conteúdos Associados ({brandContents.length})
              </h2>
              <button
                type="button"
                onClick={() => navigate('content')}
                className="text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
              >
                Content Studio
              </button>
            </div>
            <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06] text-xs">
              {brandContents.map((c) => (
                <li key={c.id} className="py-2.5 flex items-center justify-between gap-3">
                  <button
                    type="button"
                    onClick={() => navigate('content', { contentId: c.id })}
                    className="text-left min-w-0 hover:text-[#315FEA]"
                  >
                    <div className="font-medium truncate">{c.title}</div>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {c.format} · {c.visibility} · {c.scheduledDate}
                    </div>
                  </button>
                  <StatusLabel status={c.status} />
                </li>
              ))}
            </ul>
          </SurfacePanel>
        </div>

        <SurfacePanel>
          <h2 className="font-display text-sm font-semibold mb-3">
            Histórico Operacional da Marca
          </h2>
          {brandActivities.length === 0 ? (
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
              Sem eventos registrados recentemente para esta marca.
            </p>
          ) : (
            <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06] text-xs">
              {brandActivities.map((act) => (
                <li key={act.id} className="py-2.5 flex flex-wrap items-center justify-between gap-2">
                  <div>
                    <span className="font-medium">{act.action}</span>
                    <span className="text-[#525B68] dark:text-[#AEB7C2] ml-2">
                      {act.detail}
                    </span>
                  </div>
                  <span className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                    {act.timestamp.slice(0, 10)}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </SurfacePanel>

        <ModalDialog
          open={Boolean(editBrand)}
          title="Editar Marca & Parâmetros Operacionais"
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
                <label className="block font-medium mb-1">Nome da Marca</label>
                <input
                  required
                  value={editBrand.name}
                  onChange={(e) => setEditBrand({ ...editBrand, name: e.target.value })}
                  className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-medium mb-1">Fuso Horário IANA</label>
                  <input
                    required
                    value={editBrand.timezone}
                    onChange={(e) => setEditBrand({ ...editBrand, timezone: e.target.value })}
                    className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                  />
                </div>
                <div>
                  <label className="block font-medium mb-1">Janela Local de Publicação</label>
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
                  <label className="block font-medium mb-1">Arquétipo</label>
                  <select
                    value={editBrand.archetype}
                    onChange={(e) =>
                      setEditBrand({ ...editBrand, archetype: e.target.value as BrandArchetype })
                    }
                    className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
                  >
                    {ARCHETYPES.map((a) => (
                      <option key={a} value={a}>
                        {a}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block font-medium mb-1">Estágio de Validação (1–5)</label>
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
                        {st}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-medium mb-1">Mercado</label>
                  <input
                    required
                    value={editBrand.market}
                    onChange={(e) => setEditBrand({ ...editBrand, market: e.target.value })}
                    className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
                  />
                </div>
                <div>
                  <label className="block font-medium mb-1">Cor Primária (Hex)</label>
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
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded bg-[#315FEA] text-white font-medium hover:bg-[#274FC9]"
                >
                  Salvar Alterações
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
        title="Gestão de Marcas"
        subtitle="Portfólio de marcas próprias com fuso IANA, janela local de publicação, arquétipo, pilares editoriais e estágio 1–5."
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
              {compareMode ? 'Ocultar Comparativo' : 'Comparar Marcas'}
            </button>
            <button
              type="button"
              onClick={() => setCreateOpen(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
            >
              <Plus className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Nova Marca</span>
            </button>
          </>
        }
      />

      <div className="flex flex-wrap items-center justify-between gap-4">
        <SegmentedControl
          ariaLabel="Filtrar marcas por status"
          value={statusFilter}
          onChange={(v) => setStatusFilter(v as 'all' | BrandStatus)}
          options={[
            { value: 'all', label: `Todas (${rollups.length})` },
            { value: 'Active', label: 'Ativas' },
            { value: 'Paused', label: 'Pausadas' },
            { value: 'Archived', label: 'Arquivadas' },
          ]}
        />
      </div>

      {compareMode && (
        <SurfacePanel>
          <h2 className="font-display text-sm font-semibold mb-3">
            Comparativo Direto entre Marcas
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-black/10 dark:border-white/10 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  <th className="py-2 pr-4">Marca</th>
                  <th className="py-2 pr-4">Mercado / Fuso IANA</th>
                  <th className="py-2 pr-4">Estágio</th>
                  <th className="py-2 pr-4 text-right">Produtos Aprov.</th>
                  <th className="py-2 pr-4 text-right">Views 30d</th>
                  <th className="py-2 pr-4 text-right">Comercial Conf.</th>
                  <th className="py-2 text-right">Recebido Caixa</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {filteredRollups.map((r) => (
                  <tr key={r.brand.id} className="hover:bg-black/[0.02] dark:hover:bg-white/[0.02]">
                    <td className="py-2.5 pr-4 font-medium">{r.brand.name}</td>
                    <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2] font-mono text-[11px]">
                      {r.brand.market} · {r.brand.timezone}
                    </td>
                    <td className="py-2.5 pr-4 text-[#525B68] dark:text-[#AEB7C2]">
                      {r.brand.validationStage}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {r.approvedProductsCount}/{r.productsCount}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums">
                      {formatCompactNumber(r.totalViews30d)}
                    </td>
                    <td className="py-2.5 pr-4 text-right font-mono tabular-nums font-medium">
                      {formatCurrency(r.confirmedCommercial, currency)}
                    </td>
                    <td className="py-2.5 text-right font-mono tabular-nums text-emerald-700 dark:text-emerald-400">
                      {formatCurrency(r.receivedCash, currency)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </SurfacePanel>
      )}

      {filteredRollups.length === 0 ? (
        <EmptyState
          title="Nenhuma marca neste filtro"
          description="Ajuste o filtro ou crie uma nova marca operacional."
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredRollups.map((r) => (
            <SurfacePanel
              key={r.brand.id}
              className="flex flex-col justify-between hover:border-[#315FEA]/50"
            >
              <div>
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2.5">
                      <span
                        className="w-3 h-3 rounded-sm shrink-0"
                        style={{ backgroundColor: r.brand.accentColor }}
                        aria-hidden="true"
                      />
                      <h2 className="font-display text-base font-semibold truncate">
                        {r.brand.name}
                      </h2>
                    </div>
                    <p className="mt-1 text-xs text-[#525B68] dark:text-[#AEB7C2]">
                      {r.brand.niche} · {r.brand.timezone} ({r.brand.publishWindow})
                    </p>
                  </div>
                  <StatusLabel status={r.brand.status} />
                </div>

                <p className="mt-3 text-xs text-[#525B68] dark:text-[#AEB7C2] line-clamp-2">
                  {r.brand.description}
                </p>

                <div className="mt-4 pt-4 border-t border-black/10 dark:border-white/10 grid grid-cols-3 gap-3 text-xs">
                  <div>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      Comercial Conf.
                    </div>
                    <div className="mt-0.5 font-mono tabular-nums font-semibold">
                      {formatCurrency(r.confirmedCommercial, currency)}
                    </div>
                  </div>
                  <div>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Validação</div>
                    <div className="mt-0.5 font-mono tabular-nums text-[11px]">
                      {r.brand.validationStage}
                    </div>
                  </div>
                  <div>
                    <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">Views 30d</div>
                    <div className="mt-0.5 font-mono tabular-nums">
                      {formatCompactNumber(r.totalViews30d)}
                    </div>
                  </div>
                </div>
              </div>

              <div className="mt-4 pt-3 border-t border-black/10 dark:border-white/10 flex items-center justify-between">
                <span className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                  {r.brand.archetype} · {r.brand.pillars.length} pilares
                </span>
                <button
                  type="button"
                  onClick={() => navigate('brands', { brandId: r.brand.id })}
                  className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
                >
                  Abrir Detalhes
                </button>
              </div>
            </SurfacePanel>
          ))}
        </div>
      )}

      <ModalDialog
        open={createOpen}
        title="Nova Marca"
        subtitle="Cadastre uma nova operação de marca com fuso IANA e pilares editoriais."
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
              pillars: pillarsText
                .split(',')
                .map((s) => s.trim())
                .filter(Boolean),
              status: 'Active',
              accentColor,
              secondaryColor: '#292E36',
              typographyNote: 'Plus Jakarta Sans + JetBrains Mono',
              tagline: tagline.trim() || 'Nova operação estruturada.',
              description: description.trim() || 'Marca cadastrada no control plane Vyron.',
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
            <label className="block font-medium mb-1">Nome da Marca *</label>
            <input
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Ex.: Vector Optics Lab"
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">Nicho *</label>
              <input
                required
                value={niche}
                onChange={(e) => setNiche(e.target.value)}
                placeholder="Ex.: Fotografia & Lentes"
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">Arquétipo</label>
              <select
                value={archetype}
                onChange={(e) => setArchetype(e.target.value as BrandArchetype)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                {ARCHETYPES.map((a) => (
                  <option key={a} value={a}>
                    {a}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block font-medium mb-1">Mercado</label>
              <input
                value={market}
                onChange={(e) => setMarket(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">Fuso IANA</label>
              <input
                value={timezone}
                onChange={(e) => setTimezone(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">Janela Local</label>
              <input
                value={publishWindow}
                onChange={(e) => setPublishWindow(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">Idioma</label>
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
              <label className="block font-medium mb-1">Cor Destaque</label>
              <input
                value={accentColor}
                onChange={(e) => setAccentColor(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
          </div>
          <div>
            <label className="block font-medium mb-1">Pilares Editoriais (separados por vírgula)</label>
            <input
              value={pillarsText}
              onChange={(e) => setPillarsText(e.target.value)}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div>
            <label className="block font-medium mb-1">Descrição Estratégica</label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Escopo editorial, público e tese comercial..."
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
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
              Criar Marca
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
