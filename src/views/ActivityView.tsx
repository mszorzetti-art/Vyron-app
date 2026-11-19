import React, { useState } from 'react';
import { Search } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { ActivityCategory } from '../types/vyron';
import { filterActivities } from '../utils/vyronRules';
import {
  EmptyState,
  PageHeader,
  SegmentedControl,
  SurfacePanel,
} from '../components/ui';

const CATEGORIES: Array<ActivityCategory | 'Todas'> = [
  'Todas',
  'Decisão',
  'Autorização Hash',
  'Stop All',
  'Job Run',
  'Produto',
  'Conteúdo',
  'Finanças',
  'Automação',
  'Sistema',
];

export const ActivityView: React.FC = () => {
  const { state, globalBrandFilter, globalPeriodFilter } = useVyron();
  const [category, setCategory] = useState<ActivityCategory | 'Todas'>('Todas');
  const [query, setQuery] = useState('');

  const items = filterActivities(state.activities, {
    brandId: globalBrandFilter,
    period: globalPeriodFilter,
    category,
    query,
  });

  return (
    <div className="space-y-6">
      <PageHeader
        title="Activity & audit_log"
        subtitle="Registro cronológico append-only de decisões, autorizações por hash SHA-256, eventos de Stop All, execuções em lote e justificativas."
      />

      <div className="flex flex-wrap items-center justify-between gap-4">
        <SegmentedControl
          ariaLabel="Filtrar atividades por categoria"
          value={category}
          onChange={(v) => setCategory(v as ActivityCategory | 'Todas')}
          options={CATEGORIES.map((c) => ({ value: c, label: c }))}
        />

        <div className="relative w-full sm:w-64">
          <Search
            className="w-3.5 h-3.5 text-[#AEB7C2] absolute left-3 top-1/2 -translate-y-1/2"
            aria-hidden="true"
          />
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Filtrar ação, hash ou justificativa..."
            aria-label="Filtrar atividades"
            className="w-full h-9 pl-8 pr-3 text-xs rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
          />
        </div>
      </div>

      {items.length === 0 ? (
        <EmptyState
          title="Nenhum evento encontrado"
          description="Não há registros no audit_log para os filtros de marca, período ou categoria selecionados."
        />
      ) : (
        <SurfacePanel padding="none" className="overflow-hidden">
          <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
            {items.map((ev) => {
              const brand = state.brands.find((b) => b.id === ev.brandId);
              const severityText = {
                info: 'text-[#525B68] dark:text-[#AEB7C2]',
                success: 'text-emerald-700 dark:text-emerald-400',
                warning: 'text-amber-700 dark:text-amber-400',
                error: 'text-rose-700 dark:text-rose-400',
              }[ev.severity];

              return (
                <li key={ev.id} className="p-4 sm:px-6 space-y-1.5 text-xs">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className={`font-medium ${severityText}`}>{ev.category}</span>
                      <span aria-hidden="true" className="text-[#AEB7C2]">
                        ·
                      </span>
                      <span className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                        {ev.action}
                      </span>
                      {brand && (
                        <>
                          <span aria-hidden="true" className="text-[#AEB7C2]">
                            ·
                          </span>
                          <span className="text-[#525B68] dark:text-[#AEB7C2]">{brand.name}</span>
                        </>
                      )}
                    </div>
                    <span className="font-mono tabular-nums text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {ev.timestamp.slice(0, 16).replace('T', ' ')} · {ev.actor}
                    </span>
                  </div>
                  <p className="text-[#525B68] dark:text-[#AEB7C2]">{ev.detail}</p>
                  {ev.justification && (
                    <p className="text-[11px] text-[#101216] dark:text-[#F1F2F3] bg-[#F1F2F3] dark:bg-[#101216] px-3 py-1.5 rounded border border-black/10 dark:border-white/10">
                      Justificativa: {ev.justification}
                    </p>
                  )}
                </li>
              );
            })}
          </ul>
        </SurfacePanel>
      )}
    </div>
  );
};
