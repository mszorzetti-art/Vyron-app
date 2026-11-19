import React, { useState } from 'react';
import {
  Activity,
  BarChart3,
  Bell,
  Bot,
  ChevronDown,
  ChevronRight,
  FileText,
  Layers,
  LayoutDashboard,
  Lock,
  LogOut,
  Menu,
  Moon,
  OctagonAlert,
  Package,
  Radio,
  Settings,
  Sun,
  User,
  Wallet,
  X,
} from 'lucide-react';
import { useVyronAccess } from '../context/VyronAccessContext';
import { useVyron } from '../context/VyronContext';
import { useI18n } from '../i18n/useI18n';
import { I18nKey } from '../i18n/ptBR';
import {
  localizeAgent,
  localizeProduct,
  localizeSystemControlReason,
} from '../i18n/seedTranslations';
import { NavModule, PeriodFilter } from '../types/vyron';
import { canResumeSystemControl } from '../utils/vyronRules';
import { ModalDialog } from './ui';
import { VyronWordmark } from './VyronBrand';

const NAV_GROUPS: Array<{
  labelKey: I18nKey;
  items: Array<{ id: NavModule; labelKey: I18nKey; icon: React.FC<{ className?: string }> }>;
}> = [
  {
    labelKey: 'nav.group.operation',
    items: [
      { id: 'overview', labelKey: 'nav.overview', icon: LayoutDashboard },
      { id: 'brands', labelKey: 'nav.brands', icon: Layers },
      { id: 'products', labelKey: 'nav.products', icon: Package },
      { id: 'content', labelKey: 'nav.content', icon: FileText },
      { id: 'channels', labelKey: 'nav.channels', icon: Radio },
    ],
  },
  {
    labelKey: 'nav.group.performance',
    items: [
      { id: 'analytics', labelKey: 'nav.analytics', icon: BarChart3 },
      { id: 'finance', labelKey: 'nav.finance', icon: Wallet },
    ],
  },
  {
    labelKey: 'nav.group.governance',
    items: [
      { id: 'automations', labelKey: 'nav.automations', icon: Bot },
      { id: 'activity', labelKey: 'nav.activity', icon: Activity },
      { id: 'notifications', labelKey: 'nav.notifications', icon: Bell },
      { id: 'settings', labelKey: 'nav.settings', icon: Settings },
    ],
  },
];

const MODULE_LABEL_KEYS: Record<NavModule, I18nKey> = {
  overview: 'nav.overview',
  brands: 'nav.brands',
  products: 'nav.products',
  content: 'nav.content',
  channels: 'nav.channels',
  analytics: 'nav.analytics',
  finance: 'nav.finance',
  automations: 'nav.automations',
  activity: 'nav.activity',
  notifications: 'nav.notifications',
  settings: 'nav.settings',
};

export const Layout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const {
    state,
    activeModule,
    selectedBrandId,
    selectedProductId,
    selectedAutomationId,
    contentSubView,
    globalBrandFilter,
    globalPeriodFilter,
    navigate,
    setGlobalBrandFilter,
    setGlobalPeriodFilter,
    toggleTheme,
    haltSystemControl,
    resumeSystemControl,
    reconcileJobsDemo,
  } = useVyron();
  const { lock, logout } = useVyronAccess();
  const { lang, t } = useI18n();

  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [ownerMenuOpen, setOwnerMenuOpen] = useState(false);
  const [controlModalMode, setControlModalMode] = useState<'halt' | 'resume' | null>(null);
  const [controlActor, setControlActor] = useState(state.settings.ownerName);
  const [controlReason, setControlReason] = useState('');
  const [controlError, setControlError] = useState('');

  const unreadCount = state.notifications.filter((n) => !n.read).length;
  const pendingApprovals = state.automations.reduce(
    (sum, a) => sum + a.pendingApprovalCount,
    0
  );
  const isHalted = state.systemControl.state === 'HALTED';
  const resumeGate = canResumeSystemControl(state.jobRuns, lang);

  const breadcrumbItems: Array<{ label: string; onClick?: () => void }> = [
    {
      label: t(MODULE_LABEL_KEYS[activeModule]),
      onClick: () => navigate(activeModule),
    },
  ];

  if (activeModule === 'brands' && selectedBrandId) {
    const b = state.brands.find((x) => x.id === selectedBrandId);
    if (b) breadcrumbItems.push({ label: b.name });
  }
  if (activeModule === 'products' && selectedProductId) {
    const p = state.products.find((x) => x.id === selectedProductId);
    if (p) breadcrumbItems.push({ label: localizeProduct(p, lang).name });
  }
  if (activeModule === 'content' && contentSubView === 'calendar') {
    breadcrumbItems.push({ label: t('nav.breadcrumb.editorialCalendar') });
  }
  if (activeModule === 'automations' && selectedAutomationId) {
    const a = state.automations.find((x) => x.id === selectedAutomationId);
    if (a) breadcrumbItems.push({ label: localizeAgent(a, lang).name });
  }

  const handleNavClick = (id: NavModule) => {
    navigate(id);
    setMobileMenuOpen(false);
  };

  const openControlModal = (mode: 'halt' | 'resume') => {
    setControlActor(state.settings.ownerName);
    setControlReason('');
    setControlError('');
    setControlModalMode(mode);
  };

  const handleControlSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!controlActor.trim() || !controlReason.trim()) {
      setControlError(t('controls.modal.missingFields'));
      return;
    }
    if (controlModalMode === 'halt') {
      haltSystemControl(controlActor, controlReason);
      setControlModalMode(null);
      return;
    }
    if (controlModalMode === 'resume') {
      const res = resumeSystemControl(controlActor, controlReason);
      if (!res.ok) {
        setControlError(res.reason ?? t('controls.modal.resumeBlockedDefault'));
        return;
      }
      setControlModalMode(null);
    }
  };

  const SidebarContent = (
    <div className="flex flex-col h-full bg-white dark:bg-[#14171C] border-r border-black/10 dark:border-white/10">
      <div className="h-14 px-5 flex items-center justify-between border-b border-black/10 dark:border-white/10 shrink-0">
        <button
          type="button"
          onClick={() => handleNavClick('overview')}
          className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] rounded"
          aria-label={t('nav.goOverviewAria')}
        >
          <VyronWordmark markSize={24} />
        </button>
        <button
          type="button"
          onClick={() => setMobileMenuOpen(false)}
          className="lg:hidden p-1.5 rounded text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]"
          aria-label={t('nav.closeNavAria')}
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-6" aria-label={t('nav.mainAria')}>
        {NAV_GROUPS.map((group) => (
          <div key={group.labelKey}>
            <div className="px-2.5 mb-2 text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]/80">
              {t(group.labelKey)}
            </div>
            <ul className="space-y-0.5">
              {group.items.map((item) => {
                const Icon = item.icon;
                const isActive = activeModule === item.id;
                const count =
                  item.id === 'notifications' && unreadCount > 0
                    ? unreadCount
                    : item.id === 'automations' && pendingApprovals > 0
                    ? pendingApprovals
                    : null;

                return (
                  <li key={item.id}>
                    <button
                      type="button"
                      onClick={() => handleNavClick(item.id)}
                      aria-current={isActive ? 'page' : undefined}
                      className={`w-full flex items-center justify-between gap-2 px-2.5 py-2 rounded-md text-[13px] font-medium whitespace-nowrap focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] ${
                        isActive
                          ? 'bg-[#315FEA]/12 text-[#315FEA] dark:bg-[#315FEA]/20 dark:text-[#7FA0FF]'
                          : 'text-[#4A525D] dark:text-[#AEB7C2] hover:bg-black/[0.04] dark:hover:bg-white/[0.04] hover:text-[#101216] dark:hover:text-[#F1F2F3]'
                      }`}
                    >
                      <span className="flex items-center gap-2.5 min-w-0">
                        <Icon className="w-4 h-4 shrink-0" aria-hidden="true" />
                        <span className="truncate">{t(item.labelKey)}</span>
                      </span>
                      {count !== null && (
                        <span className="font-mono tabular-nums text-[11px] font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                          {count}
                        </span>
                      )}
                    </button>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>

      <div className="p-3.5 border-t border-black/10 dark:border-white/10 space-y-3 shrink-0">
        <div className="space-y-2">
          <div className="px-0.5 flex items-center justify-between gap-2">
            <span className="text-[10px] font-semibold uppercase tracking-[0.07em] text-[#525B68] dark:text-[#AEB7C2]/80">
              {t('controls.title')}
            </span>
            <span
              className={`inline-flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-[0.06em] shrink-0 ${
                isHalted
                  ? 'text-rose-700 dark:text-rose-400'
                  : 'text-emerald-700 dark:text-emerald-400'
              }`}
            >
              <span
                aria-hidden="true"
                className={`w-1.5 h-1.5 rounded-full ${
                  isHalted ? 'bg-rose-500' : 'bg-emerald-500'
                }`}
              />
              <span>{isHalted ? t('controls.statusHalted') : t('controls.statusActive')}</span>
            </span>
          </div>

          {isHalted ? (
            <button
              type="button"
              onClick={() => openControlModal('resume')}
              className="w-full h-9 flex items-center justify-center gap-2 px-3 rounded-md text-xs font-semibold tracking-[0.04em] bg-[#292E36] hover:bg-[#343B46] text-[#F1F2F3] border border-white/10 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] whitespace-nowrap"
            >
              <OctagonAlert className="w-3.5 h-3.5 text-rose-400 shrink-0" aria-hidden="true" />
              <span>{t('controls.resumeSystem')}</span>
            </button>
          ) : (
            <button
              type="button"
              onClick={() => openControlModal('halt')}
              className="w-full h-9 flex items-center justify-center gap-2 px-3 rounded-md text-xs font-semibold tracking-[0.06em] uppercase bg-[#9E2430] hover:bg-[#871E28] dark:bg-[#A62633] dark:hover:bg-[#8F1F2B] text-white border border-rose-400/20 shadow-xs transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] whitespace-nowrap"
            >
              <OctagonAlert className="w-3.5 h-3.5 shrink-0" aria-hidden="true" />
              <span>{t('controls.stopAll')}</span>
            </button>
          )}
        </div>

        <div className="px-0.5 flex items-center justify-between gap-2 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
          <span className="truncate">
            {state.systemControl.phaseBPublicAllowed
              ? t('common.publicOp')
              : t('common.privateEnv')}
          </span>
          <span className="font-mono font-medium tabular-nums text-[#292E36] dark:text-[#AEB7C2] shrink-0">
            {state.settings.baseCurrency}
          </span>
        </div>

        <div className="pt-3 border-t border-black/[0.08] dark:border-white/[0.08] flex items-center justify-between gap-2">
          <div className="min-w-0">
            <div className="text-xs font-semibold text-[#101216] dark:text-[#F1F2F3] truncate leading-tight">
              {state.settings.ownerName}
            </div>
            <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]/80 truncate mt-0.5 leading-tight">
              {t('common.owner')}
            </div>
          </div>
          <div className="flex items-center gap-1.5 shrink-0">
            <button
              type="button"
              onClick={() => {
                setMobileMenuOpen(false);
                lock('manual');
              }}
              aria-label={t('nav.lockShort')}
              title={t('nav.lockTooltip')}
              className="w-7 h-7 inline-flex items-center justify-center rounded-md border border-black/10 dark:border-white/10 text-[#525B68] dark:text-[#AEB7C2] hover:text-[#315FEA] dark:hover:text-[#7FA0FF] hover:border-[#315FEA]/40 hover:bg-[#315FEA]/[0.06] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
            >
              <Lock className="w-3.5 h-3.5" aria-hidden="true" />
            </button>
            <button
              type="button"
              onClick={() => {
                setMobileMenuOpen(false);
                logout();
              }}
              aria-label={t('nav.logoutShort')}
              title={t('nav.logoutTooltip')}
              className="w-7 h-7 inline-flex items-center justify-center rounded-md border border-black/10 dark:border-white/10 text-[#525B68] dark:text-[#AEB7C2] hover:text-rose-600 dark:hover:text-rose-400 hover:border-rose-500/40 hover:bg-rose-500/[0.08] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
            >
              <LogOut className="w-3.5 h-3.5" aria-hidden="true" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen flex bg-[#F1F2F3] dark:bg-[#101216] text-[#101216] dark:text-[#F1F2F3]">
      <aside className="hidden lg:block w-[248px] shrink-0 sticky top-0 h-screen">
        {SidebarContent}
      </aside>

      {mobileMenuOpen && (
        <div className="fixed inset-0 z-50 lg:hidden flex">
          <div
            className="fixed inset-0 bg-black/60"
            onClick={() => setMobileMenuOpen(false)}
            aria-hidden="true"
          />
          <aside className="relative z-10 w-[264px] max-w-[82vw] h-full">
            {SidebarContent}
          </aside>
        </div>
      )}

      <div className="flex-1 min-w-0 flex flex-col">
        <header className="sticky top-0 z-30 h-14 px-4 sm:px-6 bg-[#F1F2F3]/95 dark:bg-[#101216]/95 backdrop-blur-sm border-b border-black/10 dark:border-white/10 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3 min-w-0">
            <button
              type="button"
              onClick={() => setMobileMenuOpen(true)}
              className="lg:hidden p-2 -ml-2 rounded-md text-[#525B68] dark:text-[#AEB7C2] hover:bg-black/5 dark:hover:bg-white/5"
              aria-label={t('nav.openNavAria')}
            >
              <Menu className="w-5 h-5" />
            </button>
            <nav aria-label="Breadcrumb" className="flex items-center gap-1.5 text-xs sm:text-sm min-w-0">
              <span className="hidden sm:inline text-[#525B68] dark:text-[#AEB7C2]">Vyron</span>
              {breadcrumbItems.map((bc, idx) => (
                <React.Fragment key={bc.label}>
                  <ChevronRight
                    className="hidden sm:inline w-3.5 h-3.5 text-[#AEB7C2] shrink-0"
                    aria-hidden="true"
                  />
                  {bc.onClick && idx < breadcrumbItems.length - 1 ? (
                    <button
                      type="button"
                      onClick={bc.onClick}
                      className="hidden sm:inline text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3] truncate"
                    >
                      {bc.label}
                    </button>
                  ) : (
                    <span className="font-medium text-[#101216] dark:text-[#F1F2F3] truncate">
                      {bc.label}
                    </span>
                  )}
                </React.Fragment>
              ))}
            </nav>
          </div>

          <div className="flex items-center gap-2 sm:gap-3 shrink-0">
            <label htmlFor="global-brand-select" className="sr-only">
              {t('nav.filterBrandAria')}
            </label>
            <select
              id="global-brand-select"
              value={globalBrandFilter}
              onChange={(e) => setGlobalBrandFilter(e.target.value)}
              className="hidden md:block h-8 px-2.5 text-xs rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 text-[#101216] dark:text-[#F1F2F3] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
            >
              <option value="all">{t('nav.allBrands')}</option>
              {state.brands.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name}
                </option>
              ))}
            </select>

            <label htmlFor="global-period-select" className="sr-only">
              {t('nav.filterPeriodAria')}
            </label>
            <select
              id="global-period-select"
              value={globalPeriodFilter}
              onChange={(e) => setGlobalPeriodFilter(e.target.value as PeriodFilter)}
              className="h-8 px-2.5 text-xs font-mono rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 text-[#101216] dark:text-[#F1F2F3] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
            >
              <option value="7d">7d</option>
              <option value="30d">30d</option>
              <option value="90d">90d</option>
              <option value="12m">12m</option>
            </select>

            <button
              type="button"
              onClick={toggleTheme}
              aria-label={
                state.settings.theme === 'dark'
                  ? t('nav.theme.toLight')
                  : t('nav.theme.toDark')
              }
              className="h-8 px-2.5 inline-flex items-center gap-1.5 text-xs font-medium rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 text-[#101216] dark:text-[#F1F2F3] hover:border-[#315FEA]/50 whitespace-nowrap"
            >
              {state.settings.theme === 'dark' ? (
                <>
                  <Sun className="w-3.5 h-3.5 text-[#AEB7C2]" aria-hidden="true" />
                  <span className="hidden sm:inline">{t('nav.theme.light')}</span>
                </>
              ) : (
                <>
                  <Moon className="w-3.5 h-3.5 text-[#292E36]" aria-hidden="true" />
                  <span className="hidden sm:inline">{t('nav.theme.dark')}</span>
                </>
              )}
            </button>

            <button
              type="button"
              onClick={() => navigate('notifications')}
              aria-label={t('nav.notificationsAria', { count: unreadCount })}
              className="relative h-8 px-2.5 inline-flex items-center gap-1.5 text-xs font-medium rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 text-[#101216] dark:text-[#F1F2F3] hover:border-[#315FEA]/50"
            >
              <Bell className="w-3.5 h-3.5" aria-hidden="true" />
              {unreadCount > 0 && (
                <span className="font-mono tabular-nums text-[11px] font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                  {unreadCount}
                </span>
              )}
            </button>

            <div className="relative">
              <button
                type="button"
                onClick={() => setOwnerMenuOpen((v) => !v)}
                aria-expanded={ownerMenuOpen}
                aria-haspopup="menu"
                aria-label={t('nav.ownerMenuAria', { name: state.settings.ownerName })}
                className="h-8 px-2.5 inline-flex items-center gap-1.5 text-xs font-medium rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 text-[#101216] dark:text-[#F1F2F3] hover:border-[#315FEA]/50 whitespace-nowrap"
              >
                <User className="w-3.5 h-3.5 text-[#315FEA]" aria-hidden="true" />
                <span className="hidden sm:inline max-w-[140px] truncate">
                  {state.settings.ownerName}
                </span>
                <ChevronDown className="w-3 h-3 text-[#AEB7C2]" aria-hidden="true" />
              </button>

              {ownerMenuOpen && (
                <>
                  <div
                    className="fixed inset-0 z-40"
                    onClick={() => setOwnerMenuOpen(false)}
                    aria-hidden="true"
                  />
                  <div
                    role="menu"
                    className="absolute right-0 mt-1.5 w-60 z-50 rounded-lg bg-white dark:bg-[#171A20] border border-black/12 dark:border-white/12 shadow-lg py-1.5 text-xs"
                  >
                    <div className="px-3.5 py-2 border-b border-black/[0.06] dark:border-white/[0.06]">
                      <div className="font-semibold text-[#101216] dark:text-[#F1F2F3] truncate">
                        {state.settings.ownerName}
                      </div>
                      <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                        {t('nav.ownerEnv')}
                      </div>
                    </div>
                    <button
                      type="button"
                      role="menuitem"
                      onClick={() => {
                        setOwnerMenuOpen(false);
                        lock('manual');
                      }}
                      className="w-full px-3.5 py-2 text-left flex items-center gap-2 text-[#101216] dark:text-[#F1F2F3] hover:bg-black/[0.04] dark:hover:bg-white/[0.04]"
                    >
                      <Lock className="w-3.5 h-3.5 text-[#315FEA]" aria-hidden="true" />
                      <span>{t('nav.lockVyron')}</span>
                    </button>
                    <button
                      type="button"
                      role="menuitem"
                      onClick={() => {
                        setOwnerMenuOpen(false);
                        navigate('settings');
                      }}
                      className="w-full px-3.5 py-2 text-left flex items-center gap-2 text-[#101216] dark:text-[#F1F2F3] hover:bg-black/[0.04] dark:hover:bg-white/[0.04]"
                    >
                      <Settings className="w-3.5 h-3.5 text-[#525B68] dark:text-[#AEB7C2]" aria-hidden="true" />
                      <span>{t('nav.preferencesAccess')}</span>
                    </button>
                    <div className="my-1 border-t border-black/[0.06] dark:border-white/[0.06]" />
                    <button
                      type="button"
                      role="menuitem"
                      onClick={() => {
                        setOwnerMenuOpen(false);
                        logout();
                      }}
                      className="w-full px-3.5 py-2 text-left flex items-center gap-2 text-rose-600 dark:text-rose-400 hover:bg-rose-500/10"
                    >
                      <LogOut className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>{t('nav.logout')}</span>
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </header>

        {isHalted && (
          <div className="px-4 sm:px-6 py-2.5 bg-rose-600/12 border-b border-rose-500/30 flex flex-wrap items-center justify-between gap-3 text-xs">
            <div className="flex items-center gap-2 text-rose-700 dark:text-rose-300 font-medium">
              <OctagonAlert className="w-4 h-4 shrink-0" aria-hidden="true" />
              <span>
                {t('controls.haltedBanner', {
                  reason: localizeSystemControlReason(state.systemControl.reason, lang),
                })}
              </span>
            </div>
            <button
              type="button"
              onClick={() => openControlModal('resume')}
              className="px-3 py-1 rounded bg-rose-600 text-white font-medium hover:bg-rose-700 whitespace-nowrap"
            >
              {t('controls.resumeSystem')}
            </button>
          </div>
        )}

        <main className="flex-1 px-4 sm:px-6 lg:px-8 py-6 max-w-[1440px] w-full mx-auto">
          {children}
        </main>
      </div>

      <ModalDialog
        open={controlModalMode !== null}
        title={
          controlModalMode === 'halt'
            ? t('controls.modal.haltTitle')
            : t('controls.modal.resumeTitle')
        }
        subtitle={
          controlModalMode === 'halt'
            ? t('controls.modal.haltSubtitle')
            : t('controls.modal.resumeSubtitle')
        }
        onClose={() => setControlModalMode(null)}
      >
        <form onSubmit={handleControlSubmit} className="space-y-4 text-xs">
          {controlModalMode === 'resume' && !resumeGate.allowed && (
            <div className="p-3 rounded bg-amber-500/12 border border-amber-500/35 text-amber-800 dark:text-amber-200 space-y-2">
              <div className="font-semibold">{t('controls.modal.orphanWarningTitle')}</div>
              <p>{resumeGate.reason}</p>
              <button
                type="button"
                onClick={() => {
                  reconcileJobsDemo();
                  setControlError('');
                }}
                className="px-3 py-1.5 rounded bg-amber-600 text-white font-medium hover:bg-amber-700"
              >
                {t('controls.modal.reconcileNow')}
              </button>
            </div>
          )}

          <div>
            <label className="block font-medium mb-1">{t('controls.modal.actorLabel')}</label>
            <input
              required
              value={controlActor}
              onChange={(e) => setControlActor(e.target.value)}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>

          <div>
            <label className="block font-medium mb-1">{t('controls.modal.reasonLabel')}</label>
            <textarea
              required
              rows={2}
              value={controlReason}
              onChange={(e) => {
                setControlReason(e.target.value);
                setControlError('');
              }}
              placeholder={
                controlModalMode === 'halt'
                  ? t('controls.modal.haltPlaceholder')
                  : t('controls.modal.resumePlaceholder')
              }
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>

          {controlError && (
            <p className="text-rose-600 dark:text-rose-400 font-medium">{controlError}</p>
          )}

          <div className="flex justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={() => setControlModalMode(null)}
              className="px-3.5 py-2 rounded border border-black/15 dark:border-white/15"
            >
              {t('common.cancel')}
            </button>
            <button
              type="submit"
              disabled={controlModalMode === 'resume' && !resumeGate.allowed}
              className={`px-4 py-2 rounded text-white font-medium disabled:opacity-45 ${
                controlModalMode === 'halt'
                  ? 'bg-rose-600 hover:bg-rose-700'
                  : 'bg-[#315FEA] hover:bg-[#274FC9]'
              }`}
            >
              {controlModalMode === 'halt'
                ? t('controls.modal.confirmHalt')
                : t('controls.modal.confirmResume')}
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
