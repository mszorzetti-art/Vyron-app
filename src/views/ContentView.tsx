import React, { useState } from 'react';
import {
  Calendar as CalendarIcon,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  FileText,
  Lock,
  Plus,
  RefreshCw,
  ShieldAlert,
  XCircle,
} from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import {
  AnalysisMethod,
  ContentCategory,
  ContentFormat,
  ContentStatus,
  ContentVersion,
  ContentVisibility,
  SensitiveTopic,
} from '../types/vyron';
import { useI18n } from '../i18n/useI18n';
import {
  labelAnalysisMethod,
  labelAttributionStatus,
  labelContentCategory,
  labelContentFormat,
  labelContentStatus,
  labelContentVisibility,
  labelFeedbackCategory,
  labelSensitiveTopic,
  labelSystemControlState,
} from '../i18n/domainLabels';
import { localizeActor, localizeContentDisplay } from '../i18n/seedTranslations';
import { evaluateContentPreSendChecks } from '../utils/vyronRules';
import {
  EmptyState,
  ModalDialog,
  PageHeader,
  SegmentedControl,
  StatusLabel,
  SurfacePanel,
} from '../components/ui';

const CONTENT_STATUSES: ContentStatus[] = [
  'Brief',
  'Draft',
  'In Review',
  'Approved',
  'Published',
  'Rejected',
];

const FEEDBACK_CATEGORIES: Array<NonNullable<ContentVersion['feedbackCategory']>> = [
  'Tom',
  'Precisão/Fonte',
  'Estrutura',
  'Divulgação',
  'Conformidade',
];

export const ContentView: React.FC = () => {
  const {
    state,
    selectedContentId,
    contentSubView,
    globalBrandFilter,
    setContentSubView,
    navigate,
    createContent,
    updateContent,
    changeContentStatus,
    authorizeContentVersion,
    revokeContentAuthorization,
    revalidateContentEvidence,
    rejectContentWithFeedback,
  } = useVyron();
  const { lang, t, fmtCurrency, fmtCompact, fmtNumber, fmtDate, fmtDateTime } = useI18n();

  const [statusFilter, setStatusFilter] = useState<'all' | ContentStatus>('all');
  const [formatFilter, setFormatFilter] = useState<'all' | ContentFormat>('all');
  const [createOpen, setCreateOpen] = useState(false);

  // Calendar state
  const [calYear, setCalYear] = useState(2026);
  const [calMonth, setCalMonth] = useState(10);

  // New content form state
  const [newTitle, setNewTitle] = useState('');
  const [newBrandId, setNewBrandId] = useState(state.brands[0]?.id ?? '');
  const [newChannelId, setNewChannelId] = useState(state.channels[0]?.id ?? '');
  const [newProductId, setNewProductId] = useState('');
  const [newFormat, setNewFormat] = useState<ContentFormat>('Long-form');
  const [newCategory, setNewCategory] = useState<ContentCategory>('Comercial contextual');
  const [newVisibility, setNewVisibility] = useState<ContentVisibility>('private');
  const [newDate, setNewDate] = useState('2026-11-25');
  const [newBrief, setNewBrief] = useState('');

  // Review / Hash Authorization & Rejection modals
  const [statusNote, setStatusNote] = useState('');
  const [authModalOpen, setAuthModalOpen] = useState(false);
  const [authValidHours, setAuthValidHours] = useState(
    String(state.settings.defaultAuthValidityHours)
  );
  const [authActor, setAuthActor] = useState(state.settings.ownerName);
  const [authNote, setAuthNote] = useState('');
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [rejectCategory, setRejectCategory] =
    useState<NonNullable<ContentVersion['feedbackCategory']>>('Tom');
  const [rejectNote, setRejectNote] = useState('');

  const visibleContents = state.contents.filter((c) => {
    if (globalBrandFilter !== 'all' && c.brandId !== globalBrandFilter) return false;
    if (statusFilter !== 'all' && c.status !== statusFilter) return false;
    if (formatFilter !== 'all' && c.format !== formatFilter) return false;
    return true;
  });

  const activeContent =
    state.contents.find((c) => c.id === selectedContentId) ?? visibleContents[0] ?? null;

  const localizedActive = activeContent ? localizeContentDisplay(activeContent, lang) : null;

  const preSendEval = activeContent
    ? evaluateContentPreSendChecks(
        activeContent,
        state.systemControl,
        new Date().toISOString(),
        { evidenceFreshnessMaxHours: state.settings.evidenceFreshnessMaxHours, language: lang }
      )
    : null;

  // Calendar helpers
  const rawMonthName = new Intl.DateTimeFormat(lang === 'EN-US' ? 'en-US' : 'pt-BR', {
    month: 'long',
    timeZone: 'UTC',
  }).format(new Date(Date.UTC(calYear, calMonth, 1)));
  const monthLabel = rawMonthName.charAt(0).toUpperCase() + rawMonthName.slice(1);
  const weekdays = [
    t('content.calendar.sun'),
    t('content.calendar.mon'),
    t('content.calendar.tue'),
    t('content.calendar.wed'),
    t('content.calendar.thu'),
    t('content.calendar.fri'),
    t('content.calendar.sat'),
  ];
  const firstWeekday = new Date(Date.UTC(calYear, calMonth, 1)).getUTCDay();
  const daysInMonth = new Date(Date.UTC(calYear, calMonth + 1, 0)).getUTCDate();

  const calendarCells: Array<{ day: number | null; iso?: string }> = [];
  for (let i = 0; i < firstWeekday; i++) calendarCells.push({ day: null });
  for (let d = 1; d <= daysInMonth; d++) {
    const mm = String(calMonth + 1).padStart(2, '0');
    const dd = String(d).padStart(2, '0');
    calendarCells.push({ day: d, iso: `${calYear}-${mm}-${dd}` });
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={contentSubView === 'studio' ? t('content.titleStudio') : t('content.titleCalendar')}
        subtitle={t('content.subtitle')}
        actions={
          <>
            <SegmentedControl
              ariaLabel={t('content.switchAria')}
              value={contentSubView}
              onChange={(v) => setContentSubView(v as 'studio' | 'calendar')}
              options={[
                { value: 'studio', label: t('content.tabStudio') },
                { value: 'calendar', label: t('content.tabCalendar') },
              ]}
            />
            <button
              type="button"
              onClick={() => setCreateOpen(true)}
              className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
            >
              <Plus className="w-3.5 h-3.5" aria-hidden="true" />
              <span>{t('content.newContent')}</span>
            </button>
          </>
        }
      />

      {/* Filter Bar */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <SegmentedControl
          ariaLabel={t('content.statusFilterAria')}
          value={statusFilter}
          onChange={(v) => setStatusFilter(v as 'all' | ContentStatus)}
          options={[
            { value: 'all', label: t('common.all') },
            ...CONTENT_STATUSES.map((s) => ({ value: s, label: labelContentStatus(s, lang) })),
          ]}
        />
        <SegmentedControl
          ariaLabel={t('content.formatFilterAria')}
          value={formatFilter}
          onChange={(v) => setFormatFilter(v as 'all' | ContentFormat)}
          options={[
            { value: 'all', label: t('content.allFormats') },
            { value: 'Long-form', label: labelContentFormat('Long-form', lang) },
            { value: 'Shorts', label: labelContentFormat('Shorts', lang) },
            { value: 'Article', label: labelContentFormat('Article', lang) },
          ]}
        />
      </div>

      {/* SUBPAGE: EDITORIAL CALENDAR */}
      {contentSubView === 'calendar' ? (
        <SurfacePanel>
          <div className="flex items-center justify-between gap-4 mb-4">
            <div className="flex items-center gap-2">
              <CalendarIcon className="w-4 h-4 text-[#315FEA]" aria-hidden="true" />
              <h2 className="font-display text-base font-semibold">
                {monthLabel} {calYear}
              </h2>
            </div>
            <div className="flex items-center gap-1.5">
              <button
                type="button"
                aria-label={t('content.calendar.prevMonthAria')}
                onClick={() => {
                  if (calMonth === 0) {
                    setCalMonth(11);
                    setCalYear((y) => y - 1);
                  } else {
                    setCalMonth((m) => m - 1);
                  }
                }}
                className="p-1.5 rounded border border-black/10 dark:border-white/10 hover:border-[#315FEA]"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <button
                type="button"
                onClick={() => {
                  setCalYear(2026);
                  setCalMonth(10);
                }}
                className="px-2.5 py-1 text-xs rounded border border-black/10 dark:border-white/10 hover:border-[#315FEA]"
              >
                {t('content.calendar.refMonth')}
              </button>
              <button
                type="button"
                aria-label={t('content.calendar.nextMonthAria')}
                onClick={() => {
                  if (calMonth === 11) {
                    setCalMonth(0);
                    setCalYear((y) => y + 1);
                  } else {
                    setCalMonth((m) => m + 1);
                  }
                }}
                className="p-1.5 rounded border border-black/10 dark:border-white/10 hover:border-[#315FEA]"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>

          <div className="grid grid-cols-7 gap-px bg-black/10 dark:bg-white/10 border border-black/10 dark:border-white/10 rounded-md overflow-hidden">
            {weekdays.map((d) => (
              <div
                key={d}
                className="bg-[#F1F2F3] dark:bg-[#14171C] py-2 px-2 text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2] text-center"
              >
                {d}
              </div>
            ))}
            {calendarCells.map((cell, idx) => {
              if (!cell.day || !cell.iso) {
                return (
                  <div
                    key={`empty-${idx}`}
                    className="min-h-[100px] bg-white/50 dark:bg-[#14171C]/60"
                  />
                );
              }
              const dayItems = visibleContents.filter((c) => c.scheduledDate === cell.iso);
              return (
                <div
                  key={cell.iso}
                  className="min-h-[108px] bg-white dark:bg-[#171A20] p-2 flex flex-col justify-between gap-1.5"
                >
                  <div className="flex items-center justify-between">
                    <span className="font-mono tabular-nums text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      {cell.day}
                    </span>
                    <button
                      type="button"
                      aria-label={t('content.calendar.scheduleAria', { date: fmtDate(cell.iso) })}
                      onClick={() => {
                        setNewDate(cell.iso!);
                        setCreateOpen(true);
                      }}
                      className="text-[11px] text-[#AEB7C2] hover:text-[#315FEA] px-1"
                    >
                      +
                    </button>
                  </div>
                  <div className="space-y-1">
                    {dayItems.map((item) => {
                      const brand = state.brands.find((b) => b.id === item.brandId);
                      const loc = localizeContentDisplay(item, lang);
                      return (
                        <button
                          key={item.id}
                          type="button"
                          onClick={() =>
                            navigate('content', {
                              contentId: item.id,
                              contentSubView: 'studio',
                            })
                          }
                          className="w-full text-left p-1.5 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 hover:border-[#315FEA]"
                        >
                          <div className="flex items-center gap-1.5 text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                            <span
                              className="w-1.5 h-1.5 rounded-xs shrink-0"
                              style={{ backgroundColor: brand?.accentColor ?? '#315FEA' }}
                            />
                            <span className="truncate">{labelContentFormat(item.format, lang)}</span>
                            <span>·</span>
                            <span className="truncate">{labelContentVisibility(item.visibility, lang)}</span>
                          </div>
                          <div className="mt-0.5 text-[11px] font-medium truncate text-[#101216] dark:text-[#F1F2F3]">
                            {loc.title}
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        </SurfacePanel>
      ) : (
        /* SUBPAGE: CONTENT STUDIO + HASH APPROVAL PANEL */
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
          {/* Left Queue */}
          <SurfacePanel padding="none" className="lg:col-span-4 overflow-hidden">
            <div className="px-4 py-3 border-b border-black/10 dark:border-white/10 flex items-center justify-between text-xs font-medium">
              <span>{t('content.queueTitle', { count: visibleContents.length })}</span>
              <span className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                {t('content.queueHint')}
              </span>
            </div>
            {visibleContents.length === 0 ? (
              <div className="p-6 text-center text-xs text-[#525B68] dark:text-[#AEB7C2]">
                {t('content.queueEmpty')}
              </div>
            ) : (
              <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
                {visibleContents.map((c) => {
                  const brand = state.brands.find((b) => b.id === c.brandId);
                  const ch = state.channels.find((x) => x.id === c.channelId);
                  const loc = localizeContentDisplay(c, lang);
                  const isSelected = activeContent?.id === c.id;
                  const hashAuthOk =
                    c.authorization &&
                    !c.authorization.revoked &&
                    c.authorization.authorizedHash === c.currentManifestHash;
                  return (
                    <li key={c.id}>
                      <button
                        type="button"
                        onClick={() => navigate('content', { contentId: c.id })}
                        className={`w-full text-left p-4 ${
                          isSelected
                            ? 'bg-[#315FEA]/10 dark:bg-[#315FEA]/15'
                            : 'hover:bg-black/[0.02] dark:hover:bg-white/[0.02]'
                        }`}
                      >
                        <div className="flex items-center justify-between gap-2 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                          <span className="truncate">
                            {brand?.name} · {ch?.platform} · {labelContentVisibility(c.visibility, lang)}
                          </span>
                          <span className="font-mono shrink-0">{fmtDate(c.scheduledDate)}</span>
                        </div>
                        <div className="mt-1 text-xs font-semibold text-[#101216] dark:text-[#F1F2F3] line-clamp-2">
                          {loc.title}
                        </div>
                        <div className="mt-2 flex items-center justify-between gap-2">
                          <StatusLabel
                            status={labelContentStatus(c.status, lang)}
                            statusKey={c.status}
                          />
                          <span className="font-mono text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                            {hashAuthOk
                              ? t('content.hashOk')
                              : c.authorization
                              ? t('content.hashInvalid')
                              : t('content.noHash')}
                          </span>
                        </div>
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}
          </SurfacePanel>

          {/* Right Workspace Editor, Manifest Hash & 6 Mandatory Pre-Send Checks */}
          <div className="lg:col-span-8 space-y-5">
            {!activeContent || !localizedActive || !preSendEval ? (
              <EmptyState
                title={t('content.emptyTitle')}
                description={t('content.emptyDesc')}
                actionLabel={t('content.emptyCta')}
                onAction={() => setCreateOpen(true)}
              />
            ) : (
              <>
                {/* Main Manifest & Editorial Controls */}
                <SurfacePanel className="space-y-5">
                  <div className="flex flex-wrap items-start justify-between gap-4 pb-4 border-b border-black/10 dark:border-white/10">
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2 text-xs text-[#525B68] dark:text-[#AEB7C2]">
                        <FileText className="w-3.5 h-3.5" aria-hidden="true" />
                        <span>
                          {state.brands.find((b) => b.id === activeContent.brandId)?.name} ·{' '}
                          {state.channels.find((ch) => ch.id === activeContent.channelId)?.name} ·{' '}
                          {labelContentFormat(activeContent.format, lang)} ·{' '}
                          {labelContentCategory(activeContent.category, lang)}
                        </span>
                      </div>
                      <h2 className="mt-1 font-display text-lg font-semibold">
                        {localizedActive.title}
                      </h2>
                    </div>
                    <StatusLabel
                      status={labelContentStatus(activeContent.status, lang)}
                      statusKey={activeContent.status}
                    />
                  </div>

                  {/* Operational & Governance Parameters */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 text-xs">
                    <div>
                      <label className="block font-medium mb-1 text-[#525B68] dark:text-[#AEB7C2]">
                        {t('content.field.scheduledDate')}
                      </label>
                      <input
                        type="date"
                        value={activeContent.scheduledDate}
                        onChange={(e) =>
                          updateContent(
                            activeContent.id,
                            { scheduledDate: e.target.value },
                            t('content.field.rescheduledNote', { date: fmtDate(e.target.value) })
                          )
                        }
                        className="w-full h-9 px-2.5 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                      />
                    </div>
                    <div>
                      <label className="block font-medium mb-1 text-[#525B68] dark:text-[#AEB7C2]">
                        {t('content.field.visibility')}
                      </label>
                      <select
                        aria-label={t('content.field.visibility')}
                        value={activeContent.visibility}
                        onChange={(e) =>
                          updateContent(activeContent.id, {
                            visibility: e.target.value as ContentVisibility,
                          })
                        }
                        className="w-full h-9 px-2.5 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
                      >
                        <option value="private">
                          {labelContentVisibility('private', lang)} ({t('common.privateEnv')})
                        </option>
                        <option value="unlisted">{labelContentVisibility('unlisted', lang)}</option>
                        <option value="public">{labelContentVisibility('public', lang)}</option>
                      </select>
                    </div>
                    <div>
                      <label className="block font-medium mb-1 text-[#525B68] dark:text-[#AEB7C2]">
                        {t('content.field.analysisMethod')}
                      </label>
                      <select
                        aria-label={t('content.field.analysisMethod')}
                        value={activeContent.analysisMethod}
                        onChange={(e) =>
                          updateContent(activeContent.id, {
                            analysisMethod: e.target.value as AnalysisMethod,
                          })
                        }
                        className="w-full h-9 px-2.5 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
                      >
                        <option value="Teste próprio">{labelAnalysisMethod('Teste próprio', lang)}</option>
                        <option value="Análise documental">{labelAnalysisMethod('Análise documental', lang)}</option>
                        <option value="Comparativo de critérios">{labelAnalysisMethod('Comparativo de critérios', lang)}</option>
                      </select>
                    </div>
                    <div>
                      <label className="block font-medium mb-1 text-[#525B68] dark:text-[#AEB7C2]">
                        {t('content.field.sensitiveHours')}
                      </label>
                      <div className="flex gap-1.5">
                        <select
                          aria-label={t('content.field.sensitiveHours')}
                          value={activeContent.sensitiveTopic}
                          onChange={(e) =>
                            updateContent(activeContent.id, {
                              sensitiveTopic: e.target.value as SensitiveTopic,
                            })
                          }
                          className="flex-1 h-9 px-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
                        >
                          <option value="Nenhum">{labelSensitiveTopic('Nenhum', lang)}</option>
                          <option value="Saúde">{labelSensitiveTopic('Saúde', lang)}</option>
                          <option value="Finanças">{labelSensitiveTopic('Finanças', lang)}</option>
                          <option value="Apostas">{labelSensitiveTopic('Apostas', lang)}</option>
                          <option value="Infantil">{labelSensitiveTopic('Infantil', lang)}</option>
                          <option value="Segurança">{labelSensitiveTopic('Segurança', lang)}</option>
                        </select>
                        <input
                          type="number"
                          step="0.5"
                          min="0"
                          aria-label={t('content.field.humanHoursAria')}
                          value={activeContent.humanHoursLogged}
                          onChange={(e) =>
                            updateContent(activeContent.id, {
                              humanHoursLogged: Math.max(0, Number(e.target.value) || 0),
                            })
                          }
                          className="w-16 h-9 px-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono text-right"
                          title={t('content.field.humanHoursTitle')}
                        />
                      </div>
                    </div>
                  </div>

                  {/* Editorial Copy & Script (Manifest-hashed fields) */}
                  <div className="space-y-3.5 text-xs">
                    <div>
                      <label className="block font-medium mb-1">{t('content.field.description')}</label>
                      <textarea
                        rows={2}
                        value={activeContent.description}
                        onChange={(e) =>
                          updateContent(activeContent.id, { description: e.target.value })
                        }
                        className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
                      />
                    </div>
                    <div>
                      <label className="block font-medium mb-1">
                        {t('content.field.script')}
                      </label>
                      <textarea
                        rows={4}
                        value={activeContent.script}
                        onChange={(e) =>
                          updateContent(activeContent.id, { script: e.target.value })
                        }
                        className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono text-[12px] leading-relaxed"
                      />
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      <div>
                        <label className="block font-medium mb-1">{t('content.field.affiliateLink')}</label>
                        <input
                          value={activeContent.affiliateLinkUrl}
                          onChange={(e) =>
                            updateContent(activeContent.id, { affiliateLinkUrl: e.target.value })
                          }
                          className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono text-[11px]"
                        />
                      </div>
                      <div>
                        <label className="block font-medium mb-1">{t('content.field.disclosure')}</label>
                        <input
                          value={activeContent.affiliateDisclosure}
                          onChange={(e) =>
                            updateContent(activeContent.id, { affiliateDisclosure: e.target.value })
                          }
                          className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
                        />
                      </div>
                    </div>

                    {/* Checklists & Risk Toggles */}
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 pt-1">
                      <label className="flex items-center gap-2 p-2.5 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
                        <input
                          type="checkbox"
                          checked={activeContent.relevanceTestPassed}
                          onChange={(e) =>
                            updateContent(activeContent.id, {
                              relevanceTestPassed: e.target.checked,
                            })
                          }
                          className="accent-[#315FEA]"
                        />
                        <span>{t('content.field.relevanceCheck')}</span>
                      </label>
                      <label className="flex items-center gap-2 p-2.5 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
                        <input
                          type="checkbox"
                          checked={activeContent.editorialChecklistPassed}
                          onChange={(e) =>
                            updateContent(activeContent.id, {
                              editorialChecklistPassed: e.target.checked,
                            })
                          }
                          className="accent-[#315FEA]"
                        />
                        <span>{t('content.field.editorialCheck')}</span>
                      </label>
                      <label className="flex items-center gap-2 p-2.5 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10">
                        <input
                          type="checkbox"
                          checked={activeContent.unclassifiedRiskFlag}
                          onChange={(e) =>
                            updateContent(activeContent.id, {
                              unclassifiedRiskFlag: e.target.checked,
                            })
                          }
                          className="accent-[#315FEA]"
                        />
                        <span>{t('content.field.unclassifiedRisk')}</span>
                      </label>
                    </div>
                  </div>
                </SurfacePanel>

                {/* HASH APPROVAL PANEL & 6 MANDATORY PRE-SEND CHECKS */}
                <SurfacePanel className="space-y-4">
                  <div className="flex flex-wrap items-start justify-between gap-3 pb-3 border-b border-black/10 dark:border-white/10">
                    <div>
                      <div className="flex items-center gap-2">
                        <Lock className="w-4 h-4 text-[#315FEA]" aria-hidden="true" />
                        <h3 className="font-display text-sm font-semibold">
                          {t('content.hashPanel.title')}
                        </h3>
                      </div>
                      <p className="mt-1 text-xs text-[#525B68] dark:text-[#AEB7C2]">
                        {t('content.hashPanel.subtitle')}
                      </p>
                    </div>
                    <div className="text-right font-mono text-[11px]">
                      <div className="text-[#525B68] dark:text-[#AEB7C2]">
                        {t('content.hashPanel.currentManifest')}
                      </div>
                      <div className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                        {preSendEval.recalculatedHash.slice(0, 16)}...
                      </div>
                    </div>
                  </div>

                  {/* Authorization summary vs live hash */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs">
                    <div className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 space-y-1">
                      <div className="text-[#525B68] dark:text-[#AEB7C2] font-medium">
                        {t('content.hashPanel.linkedAuth')}
                      </div>
                      {activeContent.authorization ? (
                        <>
                          <div className="font-mono text-[11px]">
                            {t('content.hashPanel.hashPrefix', {
                              hash: activeContent.authorization.authorizedHash.slice(0, 16),
                            })}
                          </div>
                          <div className="font-mono text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                            {t('content.hashPanel.byActorExpires', {
                              actor: localizeActor(activeContent.authorization.actor, lang),
                              date: fmtDateTime(activeContent.authorization.expiresAt),
                            })}
                          </div>
                        </>
                      ) : (
                        <div className="text-amber-700 dark:text-amber-400 font-medium">
                          {t('content.hashPanel.noActiveAuth')}
                        </div>
                      )}
                    </div>

                    <div className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 space-y-1">
                      <div className="text-[#525B68] dark:text-[#AEB7C2] font-medium">
                        {t('content.hashPanel.gateResult')}
                      </div>
                      {preSendEval.canSend ? (
                        <div className="font-semibold text-emerald-700 dark:text-emerald-400">
                          {t('content.hashPanel.readyToSend', {
                            visibility: labelContentVisibility(activeContent.visibility, lang),
                          })}
                        </div>
                      ) : (
                        <div className="font-semibold text-rose-700 dark:text-rose-400">
                          {t('content.hashPanel.blocked', {
                            count: preSendEval.checks.filter((c) => !c.passed).length,
                          })}
                        </div>
                      )}
                      <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {t('content.hashPanel.controlsSummary', {
                          state: labelSystemControlState(state.systemControl.state, lang),
                          pub: state.systemControl.publishingEnabled
                            ? t('content.hashPanel.pubEnabled')
                            : t('content.hashPanel.pubDisabled'),
                        })}
                      </div>
                    </div>
                  </div>

                  {/* 6 Mandatory Checks */}
                  <ul className="space-y-2 text-xs">
                    {preSendEval.checks.map((chk) => (
                      <li
                        key={chk.id}
                        className="flex items-start gap-2.5 p-2.5 rounded border border-black/10 dark:border-white/10"
                      >
                        {chk.passed ? (
                          <CheckCircle2
                            className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5"
                            aria-hidden="true"
                          />
                        ) : (
                          <XCircle
                            className="w-4 h-4 text-rose-600 dark:text-rose-400 shrink-0 mt-0.5"
                            aria-hidden="true"
                          />
                        )}
                        <div className="min-w-0">
                          <div className="font-medium text-[#101216] dark:text-[#F1F2F3]">
                            {chk.label}
                          </div>
                          <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                            {chk.detail}
                          </div>
                        </div>
                      </li>
                    ))}
                  </ul>

                  {/* Actions: Revalidate, Authorize Hash, Revoke, Reject with Feedback */}
                  <div className="pt-2 flex flex-wrap items-center gap-2.5">
                    <button
                      type="button"
                      onClick={() => revalidateContentEvidence(activeContent.id)}
                      className="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-medium rounded border border-black/15 dark:border-white/15 hover:border-[#315FEA]"
                    >
                      <RefreshCw className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>{t('content.action.revalidate')}</span>
                    </button>

                    <button
                      type="button"
                      onClick={() => {
                        setAuthActor(state.settings.ownerName);
                        setAuthValidHours(String(state.settings.defaultAuthValidityHours));
                        setAuthNote('');
                        setAuthModalOpen(true);
                      }}
                      className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-medium rounded bg-[#315FEA] text-white hover:bg-[#274FC9]"
                    >
                      <Lock className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>{t('content.action.authorize')}</span>
                    </button>

                    {activeContent.authorization && !activeContent.authorization.revoked && (
                      <button
                        type="button"
                        onClick={() =>
                          revokeContentAuthorization(
                            activeContent.id,
                            t('content.action.revokeReason')
                          )
                        }
                        className="px-3 py-2 text-xs font-medium rounded border border-amber-500/40 text-amber-700 dark:text-amber-300 hover:bg-amber-500/10"
                      >
                        {t('content.action.revoke')}
                      </button>
                    )}

                    <button
                      type="button"
                      onClick={() => {
                        setRejectNote('');
                        setRejectModalOpen(true);
                      }}
                      className="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-medium rounded border border-rose-500/40 text-rose-700 dark:text-rose-400 hover:bg-rose-500/10"
                    >
                      <ShieldAlert className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>{t('content.action.reject')}</span>
                    </button>
                  </div>

                  {/* Manual Status Transitions */}
                  <div className="pt-3 border-t border-black/10 dark:border-white/10 space-y-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <input
                        value={statusNote}
                        onChange={(e) => setStatusNote(e.target.value)}
                        placeholder={t('content.versionNotePlaceholder')}
                        aria-label={t('content.versionNoteAria')}
                        className="flex-1 min-w-[200px] h-8 px-3 text-xs rounded border border-black/15 dark:border-white/15 bg-transparent"
                      />
                      <button
                        type="button"
                        onClick={() => {
                          updateContent(
                            activeContent.id,
                            {},
                            statusNote.trim() || t('content.versionNoteDefault')
                          );
                          setStatusNote('');
                        }}
                        className="h-8 px-3 text-xs font-medium rounded border border-black/15 dark:border-white/15 hover:border-[#315FEA]"
                      >
                        {t('content.saveVersion')}
                      </button>
                    </div>
                    <div className="flex flex-wrap items-center gap-1.5">
                      {CONTENT_STATUSES.map((st) => {
                        const isCurr = activeContent.status === st;
                        return (
                          <button
                            key={st}
                            type="button"
                            disabled={isCurr}
                            onClick={() => {
                              changeContentStatus(
                                activeContent.id,
                                st,
                                statusNote.trim() ||
                                  t('content.movedToNote', {
                                    status: labelContentStatus(st, lang),
                                  })
                              );
                              setStatusNote('');
                            }}
                            className={`px-2.5 py-1 text-[11px] font-medium rounded ${
                              isCurr
                                ? 'bg-[#315FEA] text-white cursor-default'
                                : 'border border-black/10 dark:border-white/10 hover:border-[#315FEA]/60'
                            }`}
                          >
                            {labelContentStatus(st, lang)}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </SurfacePanel>

                {/* Dossier, Post-Publish Attribution & Version History */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <SurfacePanel className="space-y-3">
                    <h3 className="font-display text-sm font-semibold">
                      {t('content.dossierTitle')}
                    </h3>
                    {localizedActive.dossier.length > 0 ? (
                      <ul className="space-y-2 text-xs">
                        {localizedActive.dossier.map((d) => (
                          <li
                            key={d.id}
                            className="p-2.5 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10"
                          >
                            <div className="font-mono text-[10px] text-[#315FEA] dark:text-[#7FA0FF]">
                              {t('content.dossierLevelDate', {
                                level: d.level,
                                date: fmtDate(d.consultedAt),
                              })}
                            </div>
                            <div className="font-medium mt-0.5">{d.claim}</div>
                            <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                              {d.sourceTitle}
                            </div>
                          </li>
                        ))}
                      </ul>
                    ) : (
                      <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
                        {t('content.dossierEmpty')}
                      </p>
                    )}

                    {activeContent.metrics && (
                      <div className="pt-3 border-t border-black/10 dark:border-white/10 space-y-2 text-xs">
                        <div className="flex items-center justify-between">
                          <span className="font-semibold">{t('content.metrics.title')}</span>
                          <span className="font-mono text-[11px] text-amber-700 dark:text-amber-400">
                            {labelAttributionStatus(activeContent.metrics.attributionStatus, lang)}
                          </span>
                        </div>
                        <div className="grid grid-cols-2 gap-2.5">
                          <div>
                            <div className="text-[#525B68] dark:text-[#AEB7C2]">
                              {t('content.metrics.viewsRet')}
                            </div>
                            <div className="font-mono font-semibold">
                              {fmtCompact(activeContent.metrics.views)} ·{' '}
                              {fmtNumber(activeContent.metrics.retention30sPct, 1)}%
                            </div>
                          </div>
                          <div>
                            <div className="text-[#525B68] dark:text-[#AEB7C2]">
                              {t('content.metrics.clicksTracking')}
                            </div>
                            <div className="font-mono font-semibold">
                              {fmtCompact(activeContent.metrics.clicks)} ({activeContent.metrics.trackingSrc})
                            </div>
                          </div>
                          <div>
                            <div className="text-[#525B68] dark:text-[#AEB7C2]">
                              {t('content.metrics.conversions')}
                            </div>
                            <div className="font-mono font-semibold">
                              {activeContent.metrics.conversions}
                            </div>
                          </div>
                          <div>
                            <div className="text-[#525B68] dark:text-[#AEB7C2]">
                              {t('content.metrics.revenue')}
                            </div>
                            <div className="font-mono font-semibold text-emerald-700 dark:text-emerald-400">
                              {fmtCurrency(
                                activeContent.metrics.revenueGenerated,
                                activeContent.metrics.currency
                              )}
                            </div>
                          </div>
                        </div>
                      </div>
                    )}
                  </SurfacePanel>

                  <SurfacePanel>
                    <h3 className="font-display text-sm font-semibold mb-3">
                      {t('content.versionsTitle', { count: localizedActive.versions.length })}
                    </h3>
                    <ul className="space-y-2.5 text-xs max-h-64 overflow-y-auto">
                      {localizedActive.versions.map((v) => (
                        <li
                          key={v.version + v.timestamp}
                          className="pb-2 border-b border-black/[0.06] dark:border-white/[0.06] last:border-0"
                        >
                          <div className="flex items-center justify-between font-mono text-[11px]">
                            <span className="font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                              {v.version} · {v.author}
                              {v.feedbackCategory
                                ? ` [${labelFeedbackCategory(v.feedbackCategory, lang)}]`
                                : ''}
                            </span>
                            <span className="text-[#525B68] dark:text-[#AEB7C2]">
                              {fmtDate(v.timestamp)}
                            </span>
                          </div>
                          <div className="font-mono text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                            hash: {v.manifestHash.slice(0, 14)}...
                          </div>
                          <p className="mt-0.5 text-[#525B68] dark:text-[#AEB7C2]">{v.note}</p>
                        </li>
                      ))}
                    </ul>
                  </SurfacePanel>
                </div>
              </>
            )}
          </div>
        </div>
      )}

      {/* Hash Authorization Modal */}
      <ModalDialog
        open={authModalOpen && Boolean(activeContent)}
        title={t('content.modal.authTitle')}
        subtitle={t('content.modal.authSubtitle')}
        onClose={() => setAuthModalOpen(false)}
      >
        {activeContent && (
          <form
            className="space-y-4 text-xs"
            onSubmit={(e) => {
              e.preventDefault();
              authorizeContentVersion(activeContent.id, {
                actor: authActor,
                validHours: Math.max(1, Number(authValidHours) || 48),
                note: authNote,
              });
              setAuthModalOpen(false);
            }}
          >
            <div className="p-3 rounded bg-[#F1F2F3] dark:bg-[#101216] border border-black/10 dark:border-white/10 font-mono text-[11px] space-y-1">
              <div>
                {t('content.modal.manifestHash', {
                  hash: preSendEval?.recalculatedHash ?? '',
                })}
              </div>
              <div>
                {t('content.modal.visibility', {
                  visibility: labelContentVisibility(activeContent.visibility, lang),
                })}
              </div>
              <div>{t('content.modal.rulesType')}</div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block font-medium mb-1">{t('content.modal.authorizer')}</label>
                <input
                  required
                  value={authActor}
                  onChange={(e) => setAuthActor(e.target.value)}
                  className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
                />
              </div>
              <div>
                <label className="block font-medium mb-1">{t('content.modal.validityHours')}</label>
                <input
                  type="number"
                  min="1"
                  max="168"
                  required
                  value={authValidHours}
                  onChange={(e) => setAuthValidHours(e.target.value)}
                  className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
                />
              </div>
            </div>
            <div>
              <label className="block font-medium mb-1">{t('content.modal.auditNote')}</label>
              <input
                value={authNote}
                onChange={(e) => setAuthNote(e.target.value)}
                placeholder={t('content.modal.auditNotePlaceholder')}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={() => setAuthModalOpen(false)}
                className="px-3.5 py-2 rounded border border-black/15 dark:border-white/15"
              >
                {t('common.cancel')}
              </button>
              <button
                type="submit"
                className="px-4 py-2 rounded bg-[#315FEA] text-white font-medium hover:bg-[#274FC9]"
              >
                {t('content.modal.confirmAuth')}
              </button>
            </div>
          </form>
        )}
      </ModalDialog>

      {/* Structured Rejection Feedback Modal */}
      <ModalDialog
        open={rejectModalOpen && Boolean(activeContent)}
        title={t('content.modal.rejectTitle')}
        subtitle={t('content.modal.rejectSubtitle')}
        onClose={() => setRejectModalOpen(false)}
      >
        {activeContent && (
          <form
            className="space-y-4 text-xs"
            onSubmit={(e) => {
              e.preventDefault();
              if (!rejectNote.trim()) return;
              rejectContentWithFeedback(activeContent.id, {
                category: rejectCategory,
                note: rejectNote.trim(),
              });
              setRejectModalOpen(false);
            }}
          >
            <div>
              <label className="block font-medium mb-1">{t('content.modal.rejectCategory')}</label>
              <select
                value={rejectCategory}
                onChange={(e) =>
                  setRejectCategory(
                    e.target.value as NonNullable<ContentVersion['feedbackCategory']>
                  )
                }
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                {FEEDBACK_CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {labelFeedbackCategory(cat, lang)}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block font-medium mb-1">{t('content.modal.rejectReason')}</label>
              <textarea
                required
                rows={3}
                value={rejectNote}
                onChange={(e) => setRejectNote(e.target.value)}
                placeholder={t('content.modal.rejectPlaceholder')}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
              />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={() => setRejectModalOpen(false)}
                className="px-3.5 py-2 rounded border border-black/15 dark:border-white/15"
              >
                {t('common.cancel')}
              </button>
              <button
                type="submit"
                className="px-4 py-2 rounded bg-rose-600 text-white font-medium hover:bg-rose-700"
              >
                {t('content.modal.confirmReject')}
              </button>
            </div>
          </form>
        )}
      </ModalDialog>

      {/* Create Content Modal */}
      <ModalDialog
        open={createOpen}
        title={t('content.modal.createTitle')}
        subtitle={t('content.modal.createSubtitle')}
        onClose={() => setCreateOpen(false)}
      >
        <form
          className="space-y-4 text-xs"
          onSubmit={(e) => {
            e.preventDefault();
            if (!newTitle.trim()) return;
            const created = createContent({
              brandId: newBrandId,
              channelId: newChannelId,
              productId: newProductId || undefined,
              title: newTitle.trim(),
              format: newFormat,
              category: newCategory,
              visibility: newVisibility,
              status: 'Brief',
              scheduledDate: newDate,
              brief: newBrief.trim() || t('content.modal.createTitle'),
              angleIdea: 'Abordagem técnica e comparativa.',
              script: '1. Gancho técnico\n2. Evidência prática\n3. Recomendação final',
              references: [],
            });
            setCreateOpen(false);
            setNewTitle('');
            setNewBrief('');
            navigate('content', { contentId: created.id, contentSubView: 'studio' });
          }}
        >
          <div>
            <label className="block font-medium mb-1">{t('content.modal.titleReq')}</label>
            <input
              required
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              placeholder={t('content.modal.titlePlaceholder')}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">{t('content.modal.brand')}</label>
              <select
                value={newBrandId}
                onChange={(e) => setNewBrandId(e.target.value)}
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
              <label className="block font-medium mb-1">{t('content.modal.channel')}</label>
              <select
                value={newChannelId}
                onChange={(e) => setNewChannelId(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                {state.channels.map((ch) => (
                  <option key={ch.id} value={ch.id}>
                    {ch.name} ({ch.platform})
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block font-medium mb-1">{t('content.modal.format')}</label>
              <select
                value={newFormat}
                onChange={(e) => setNewFormat(e.target.value as ContentFormat)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="Long-form">{labelContentFormat('Long-form', lang)}</option>
                <option value="Shorts">{labelContentFormat('Shorts', lang)}</option>
                <option value="Article">{labelContentFormat('Article', lang)}</option>
              </select>
            </div>
            <div>
              <label className="block font-medium mb-1">{t('content.modal.category')}</label>
              <select
                value={newCategory}
                onChange={(e) => setNewCategory(e.target.value as ContentCategory)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="Comercial contextual">{labelContentCategory('Comercial contextual', lang)}</option>
                <option value="Descoberta">{labelContentCategory('Descoberta', lang)}</option>
                <option value="Conexão">{labelContentCategory('Conexão', lang)}</option>
              </select>
            </div>
            <div>
              <label className="block font-medium mb-1">{t('content.modal.visibilityLabel')}</label>
              <select
                value={newVisibility}
                onChange={(e) => setNewVisibility(e.target.value as ContentVisibility)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="private">{labelContentVisibility('private', lang)}</option>
                <option value="unlisted">{labelContentVisibility('unlisted', lang)}</option>
                <option value="public">{labelContentVisibility('public', lang)}</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-medium mb-1">{t('content.modal.plannedDate')}</label>
              <input
                type="date"
                value={newDate}
                onChange={(e) => setNewDate(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent font-mono"
              />
            </div>
            <div>
              <label className="block font-medium mb-1">{t('content.modal.productOptional')}</label>
              <select
                value={newProductId}
                onChange={(e) => setNewProductId(e.target.value)}
                className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#171A20]"
              >
                <option value="">{t('common.none')}</option>
                {state.products.filter((p) => !p.isTest).map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div>
            <label className="block font-medium mb-1">{t('content.modal.brief')}</label>
            <textarea
              rows={2}
              value={newBrief}
              onChange={(e) => setNewBrief(e.target.value)}
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
              {t('content.modal.createBtn')}
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
