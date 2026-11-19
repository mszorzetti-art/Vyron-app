import React, { useState } from 'react';
import { Plus, RefreshCw } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { ChannelPlatform } from '../types/vyron';
import { formatCompactNumber } from '../utils/vyronRules';
import { HorizontalBarComparison } from '../components/Charts';
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
  const [platformFilter, setPlatformFilter] = useState<'all' | ChannelPlatform>('all');
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
        title="Gestão de Canais"
        subtitle="Distribuição multicanal, elegibilidade de recursos avançados YouTube (links clicáveis/vídeo relacionado) e passagem Shorts → Longo."
        actions={
          <button
            type="button"
            onClick={() => setCreateOpen(true)}
            className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
          >
            <Plus className="w-3.5 h-3.5" aria-hidden="true" />
            <span>Cadastrar Canal</span>
          </button>
        }
      />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricBlock
          label="Audiência Total Agregada"
          value={formatCompactNumber(totalFollowers)}
          helper={`${visibleChannels.length} canais no filtro`}
        />
        <MetricBlock
          label="Visualizações (30d)"
          value={formatCompactNumber(totalViews)}
          helper={`Engajamento médio: ${avgEngagement.toFixed(1)}%`}
          tone="cobalt"
        />
        <MetricBlock
          label="Recursos Avançados YT"
          value={`${unlockedYtCount}/${ytChannels.length}`}
          helper="Links clicáveis em descrição / cards"
        />
        <MetricBlock
          label="Passagem Shorts → Longo"
          value={`${avgShortsBridge.toFixed(1)}%`}
          helper="Taxa média de ponte nos canais YouTube"
          tone="emerald"
        />
      </div>

      <SegmentedControl
        ariaLabel="Filtrar canais por plataforma"
        value={platformFilter}
        onChange={(v) => setPlatformFilter(v as 'all' | ChannelPlatform)}
        options={[
          { value: 'all', label: 'Todas Plataformas' },
          ...PLATFORMS.map((p) => ({ value: p, label: p })),
        ]}
      />

      {visibleChannels.length === 0 ? (
        <EmptyState
          title="Nenhum canal neste filtro"
          description="Conecte um canal demonstrativo ou limpe o filtro de plataforma."
          actionLabel="Cadastrar Canal"
          onAction={() => setCreateOpen(true)}
        />
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          <SurfacePanel padding="none" className="lg:col-span-8 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-black/10 dark:border-white/10 bg-black/[0.02] dark:bg-white/[0.02] text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]">
                    <th className="py-3 pl-4 pr-3">Canal / Marca</th>
                    <th className="py-3 px-3">Plataforma & Links</th>
                    <th className="py-3 px-3 text-right">Publicações</th>
                    <th className="py-3 px-3 text-right">Crescimento</th>
                    <th className="py-3 px-3 text-right">Views 30d</th>
                    <th className="py-3 px-3 text-right">Bridge S→L</th>
                    <th className="py-3 px-3">Integração</th>
                    <th className="py-3 pl-3 pr-4 text-right">Sync</th>
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
                          <div>{ch.platform} · {ch.language}</div>
                          <div className="font-mono text-[10px]">
                            {ch.advancedFeaturesUnlocked ? 'Links avançados OK' : 'Sem links clicáveis'}
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
                          {ch.growthPct30d}%
                        </td>
                        <td className="py-3 px-3 text-right font-mono tabular-nums">
                          {formatCompactNumber(ch.views30d)}
                        </td>
                        <td className="py-3 px-3 text-right font-mono tabular-nums">
                          {ch.shortsToLongPct !== undefined ? `${ch.shortsToLongPct}%` : '-'}
                        </td>
                        <td className="py-3 px-3">
                          <StatusLabel status={ch.integrationStatus} />
                        </td>
                        <td className="py-3 pl-3 pr-4 text-right">
                          <button
                            type="button"
                            onClick={() => syncChannelDemo(ch.id)}
                            aria-label={`Sincronizar canal ${ch.name}`}
                            className="inline-flex items-center gap-1 text-xs text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
                          >
                            <RefreshCw className="w-3 h-3" aria-hidden="true" />
                            <span>Testar</span>
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </SurfacePanel>

          <SurfacePanel className="lg:col-span-4">
            <h2 className="font-display text-sm font-semibold mb-1">
              Comparação de Desempenho (Views 30d)
            </h2>
            <p className="text-xs text-[#525B68] dark:text-[#AEB7C2] mb-4">
              Contribuição relativa por canal cadastrado
            </p>
            <HorizontalBarComparison
              items={[...visibleChannels]
                .sort((a, b) => b.views30d - a.views30d)
                .map((ch) => ({
                  id: ch.id,
                  label: ch.name,
                  sublabel: ch.platform,
                  value: ch.views30d,
                  formattedValue: formatCompactNumber(ch.views30d),
                }))}
            />
          </SurfacePanel>
        </div>
      )}

      <ModalDialog
        open={createOpen}
        title="Cadastrar Canal (Modo Protótipo)"
        subtitle="Integrações externas reais não são executadas nesta fase."
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
            <label className="block font-medium mb-1">Nome do Canal *</label>
            <input
              required
              value={chName}
              onChange={(e) => setChName(e.target.value)}
              placeholder="Ex.: Kinetix Shorts"
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">Plataforma</label>
              <select
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
              <label className="block font-medium mb-1">Marca Associada</label>
              <select
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
              <label className="block font-medium mb-1">Handle / Domínio *</label>
              <input
                required
                value={chHandle}
                onChange={(e) => setChHandle(e.target.value)}
                placeholder="@canal ou dominio.com"
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">Idioma</label>
              <select
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
            <span>Recursos avançados liberados (links clicáveis / vídeo relacionado)</span>
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
              Registrar Canal
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
