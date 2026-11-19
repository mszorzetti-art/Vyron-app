import React, { useState } from 'react';
import { Search } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { ActivityCategory } from '../types/vyron';
import { filterActivities } from '../utils/vyronRules';
import { useI18n } from '../i18n/useI18n';
import { labelActivityCategory } from '../i18n/domainLabels';
import { localizeActivity } from '../i18n/seedTranslations';
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
  const { lang, t, fmtDateTime } = useI18n();
  const [category, setCategory] = useState<ActivityCategory | 'Todas'>('Todas');
  const [query, setQuery] = useState('');

  const scopedItems = filterActivities(state.activities, {
    brandId: globalBrandFilter,
    period: globalPeriodFilter,
    category,
    query: '',
  });

  const normalizedQuery = query.trim().toLowerCase();
  const items = scopedItems.filter((rawEv) => {
    if (!normalizedQuery) return true;
    const loc = localizeActivity(rawEv, lang);
    const catLabel = labelActivityCategory(rawEv.category, lang);
    const hay = [
      rawEv.action,
      rawEv.detail,
      rawEv.justification ?? '',
      rawEv.actor,
      loc.action,
      loc.detail,
      loc.justification ?? '',
      catLabel,
    ]
      .join(' ')
      .toLowerCase();
    return hay.includes(normalizedQuery);
  });

  const formatActor = (actor: string): string => {
    if (actor === 'Proprietário' || actor === 'Owner') {
      return t('common.owner');
    }
    if (actor === 'batch-executor') {
      return lang === 'EN-US' ? 'Batch executor' : 'Executor em lotes';
    }
    return actor;
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('activity.title')}
        subtitle={t('activity.subtitle')}
      />

      <div className="flex flex-wrap items-center justify-between gap-4">
        <SegmentedControl
          ariaLabel={t('activity.filterAria')}
          value={category}
          onChange={(v) => setCategory(v as ActivityCategory | 'Todas')}
          options={CATEGORIES.map((c) => ({
            value: c,
            label: c === 'Todas' ? t('common.allFemale') : labelActivityCategory(c, lang),
          }))}
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
            placeholder={t('activity.searchPlaceholder')}
            aria-label={t('activity.searchAria')}
            className="w-full h-9 pl-8 pr-3 text-xs rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
          />
        </div>
      </div>

      {items.length === 0 ? (
        <EmptyState
          title={t('activity.emptyTitle')}
          description={t('activity.emptyDesc')}
        />
      ) : (
        <SurfacePanel padding="none" className="overflow-hidden">
          <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
            {items.map((rawEv) => {
              const ev = localizeActivity(rawEv, lang);
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
                      <span className={`font-medium ${severityText}`}>
                        {labelActivityCategory(ev.category, lang)}
                      </span>
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
                      {fmtDateTime(ev.timestamp)} · {formatActor(ev.actor)}
                    </span>
                  </div>
                  <p className="text-[#525B68] dark:text-[#AEB7C2]">{ev.detail}</p>
                  {ev.justification && (
                    <p className="text-[11px] text-[#101216] dark:text-[#F1F2F3] bg-[#F1F2F3] dark:bg-[#101216] px-3 py-1.5 rounded border border-black/10 dark:border-white/10">
                      {t('activity.justificationPrefix', { text: ev.justification })}
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

