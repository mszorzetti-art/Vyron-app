import React, { useState } from 'react';
import {
  Activity,
  BarChart3,
  Bell,
  Bot,
  ChevronRight,
  FileText,
  Layers,
  LayoutDashboard,
  Menu,
  Moon,
  OctagonAlert,
  Package,
  Radio,
  Settings,
  Sun,
  Wallet,
  X,
} from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { NavModule, PeriodFilter } from '../types/vyron';
import { canResumeSystemControl } from '../utils/vyronRules';
import { ModalDialog } from './ui';
import { VyronWordmark } from './VyronBrand';

const NAV_GROUPS: Array<{
  label: string;
  items: Array<{ id: NavModule; label: string; icon: React.FC<{ className?: string }> }>;
}> = [
  {
    label: 'Operação',
    items: [
      { id: 'overview', label: 'Overview', icon: LayoutDashboard },
      { id: 'brands', label: 'Brands', icon: Layers },
      { id: 'products', label: 'Products & Intelligence', icon: Package },
      { id: 'content', label: 'Content Studio', icon: FileText },
      { id: 'channels', label: 'Channels', icon: Radio },
    ],
  },
  {
    label: 'Desempenho & Capital',
    items: [
      { id: 'analytics', label: 'Analytics', icon: BarChart3 },
      { id: 'finance', label: 'Finance', icon: Wallet },
    ],
  },
  {
    label: 'Governança',
    items: [
      { id: 'automations', label: 'Automations & Agents', icon: Bot },
      { id: 'activity', label: 'Activity', icon: Activity },
      { id: 'notifications', label: 'Notifications', icon: Bell },
      { id: 'settings', label: 'Settings', icon: Settings },
    ],
  },
];

const MODULE_LABELS: Record<NavModule, string> = {
  overview: 'Overview',
  brands: 'Brands',
  products: 'Products & Intelligence',
  content: 'Content Studio',
  channels: 'Channels',
  analytics: 'Analytics',
  finance: 'Finance',
  automations: 'Automations & Agents',
  activity: 'Activity',
  notifications: 'Notifications',
  settings: 'Settings',
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

  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
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
  const resumeGate = canResumeSystemControl(state.jobRuns);

  const breadcrumbItems: Array<{ label: string; onClick?: () => void }> = [
    {
      label: MODULE_LABELS[activeModule],
      onClick: () => navigate(activeModule),
    },
  ];

  if (activeModule === 'brands' && selectedBrandId) {
    const b = state.brands.find((x) => x.id === selectedBrandId);
    if (b) breadcrumbItems.push({ label: b.name });
  }
  if (activeModule === 'products' && selectedProductId) {
    const p = state.products.find((x) => x.id === selectedProductId);
    if (p) breadcrumbItems.push({ label: p.name });
  }
  if (activeModule === 'content' && contentSubView === 'calendar') {
    breadcrumbItems.push({ label: 'Calendário Editorial' });
  }
  if (activeModule === 'automations' && selectedAutomationId) {
    const a = state.automations.find((x) => x.id === selectedAutomationId);
    if (a) breadcrumbItems.push({ label: a.name });
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
      setControlError('Informe actor e motivo obrigatórios para registro no audit_log.');
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
        setControlError(res.reason ?? 'Não foi possível retomar enquanto houver jobs pendentes.');
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
          aria-label="Ir para Overview Vyron"
        >
          <VyronWordmark markSize={24} />
        </button>
        <button
          type="button"
          onClick={() => setMobileMenuOpen(false)}
          className="lg:hidden p-1.5 rounded text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]"
          aria-label="Fechar navegação"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-6" aria-label="Navegação Principal">
        {NAV_GROUPS.map((group) => (
          <div key={group.label}>
            <div className="px-2.5 mb-2 text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2]/80">
              {group.label}
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
                        <span className="truncate">{item.label}</span>
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

      <div className="p-3 border-t border-black/10 dark:border-white/10 space-y-2.5 shrink-0">
        <div className="px-2 flex items-center justify-between text-[11px] font-mono">
          <span className="text-[#525B68] dark:text-[#AEB7C2]">system_controls</span>
          <span
            className={
              isHalted
                ? 'font-semibold text-rose-600 dark:text-rose-400'
                : 'font-semibold text-emerald-700 dark:text-emerald-400'
            }
          >
            {state.systemControl.state}
          </span>
        </div>

        {isHalted ? (
          <button
            type="button"
            onClick={() => openControlModal('resume')}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-md text-xs font-medium bg-rose-600 text-white hover:bg-rose-700 whitespace-nowrap"
          >
            <OctagonAlert className="w-3.5 h-3.5 shrink-0" aria-hidden="true" />
            <span>HALTED · Retomar Sistema</span>
          </button>
        ) : (
          <button
            type="button"
            onClick={() => openControlModal('halt')}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-md text-xs font-medium border border-rose-500/35 text-rose-700 dark:text-rose-400 hover:bg-rose-500/10 whitespace-nowrap"
          >
            <OctagonAlert className="w-3.5 h-3.5 shrink-0" aria-hidden="true" />
            <span>Stop All (Halt)</span>
          </button>
        )}

        <div className="px-2 pt-0.5 flex items-center justify-between text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
          <span className="truncate">
            {state.systemControl.phaseBPublicAllowed ? 'Fase B Pública' : 'Fase A Privada'}
          </span>
          <span className="font-mono">{state.settings.baseCurrency}</span>
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
              aria-label="Abrir menu de navegação"
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
                      className="text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3] truncate"
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
              Filtrar por marca
            </label>
            <select
              id="global-brand-select"
              value={globalBrandFilter}
              onChange={(e) => setGlobalBrandFilter(e.target.value)}
              className="hidden md:block h-8 px-2.5 text-xs rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 text-[#101216] dark:text-[#F1F2F3] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
            >
              <option value="all">Todas as Marcas</option>
              {state.brands.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name}
                </option>
              ))}
            </select>

            <label htmlFor="global-period-select" className="sr-only">
              Filtrar por período
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
                  ? 'Alternar para tema claro'
                  : 'Alternar para tema escuro'
              }
              className="h-8 px-2.5 inline-flex items-center gap-1.5 text-xs font-medium rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 text-[#101216] dark:text-[#F1F2F3] hover:border-[#315FEA]/50 whitespace-nowrap"
            >
              {state.settings.theme === 'dark' ? (
                <>
                  <Sun className="w-3.5 h-3.5 text-[#AEB7C2]" aria-hidden="true" />
                  <span className="hidden sm:inline">Claro</span>
                </>
              ) : (
                <>
                  <Moon className="w-3.5 h-3.5 text-[#292E36]" aria-hidden="true" />
                  <span className="hidden sm:inline">Escuro</span>
                </>
              )}
            </button>

            <button
              type="button"
              onClick={() => navigate('notifications')}
              aria-label={`Notificações (${unreadCount} não lidas)`}
              className="relative h-8 px-2.5 inline-flex items-center gap-1.5 text-xs font-medium rounded-md bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 text-[#101216] dark:text-[#F1F2F3] hover:border-[#315FEA]/50"
            >
              <Bell className="w-3.5 h-3.5" aria-hidden="true" />
              {unreadCount > 0 && (
                <span className="font-mono tabular-nums text-[11px] font-semibold text-[#315FEA] dark:text-[#7FA0FF]">
                  {unreadCount}
                </span>
              )}
            </button>
          </div>
        </header>

        {isHalted && (
          <div className="px-4 sm:px-6 py-2.5 bg-rose-600/12 border-b border-rose-500/30 flex flex-wrap items-center justify-between gap-3 text-xs">
            <div className="flex items-center gap-2 text-rose-700 dark:text-rose-300 font-medium">
              <OctagonAlert className="w-4 h-4 shrink-0" aria-hidden="true" />
              <span>
                system_controls = HALTED ({state.systemControl.reason}) — Execuções --commit e envios externos bloqueados (fail-closed).
              </span>
            </div>
            <button
              type="button"
              onClick={() => openControlModal('resume')}
              className="px-3 py-1 rounded bg-rose-600 text-white font-medium hover:bg-rose-700 whitespace-nowrap"
            >
              Retomar Sistema
            </button>
          </div>
        )}

        <main className="flex-1 px-4 sm:px-6 lg:px-8 py-6 max-w-[1440px] w-full mx-auto">
          {children}
        </main>
      </div>

      {/* Stop All / Resume Modal with Actor + Reason + Job Reconciliation Gate */}
      <ModalDialog
        open={controlModalMode !== null}
        title={
          controlModalMode === 'halt'
            ? 'Acionar Stop All (autopilot control halt)'
            : 'Retomar Sistema (autopilot control resume)'
        }
        subtitle={
          controlModalMode === 'halt'
            ? 'Altera system_controls para HALTED e grava evento append-only no audit_log.'
            : 'Exige ator, motivo e zero job_runs pendentes/órfãos (running ou unknown).'
        }
        onClose={() => setControlModalMode(null)}
      >
        <form onSubmit={handleControlSubmit} className="space-y-4 text-xs">
          {controlModalMode === 'resume' && !resumeGate.allowed && (
            <div className="p-3 rounded bg-amber-500/12 border border-amber-500/35 text-amber-800 dark:text-amber-200 space-y-2">
              <div className="font-semibold">Trava de Segurança: Job Órfão Detectado</div>
              <p>{resumeGate.reason}</p>
              <button
                type="button"
                onClick={() => {
                  reconcileJobsDemo();
                  setControlError('');
                }}
                className="px-3 py-1.5 rounded bg-amber-600 text-white font-medium hover:bg-amber-700"
              >
                Executar jobs reconcile Agora
              </button>
            </div>
          )}

          <div>
            <label className="block font-medium mb-1">Actor (Responsável) *</label>
            <input
              required
              value={controlActor}
              onChange={(e) => setControlActor(e.target.value)}
              className="w-full px-3 py-2 rounded border border-black/15 dark:border-white/15 bg-transparent"
            />
          </div>

          <div>
            <label className="block font-medium mb-1">Motivo (gravado no audit_log) *</label>
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
                  ? 'Ex.: Revisão manual de links comerciais antes do próximo lote.'
                  : 'Ex.: Jobs órfãos reconciliados e verificações concluídas.'
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
              Cancelar
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
              {controlModalMode === 'halt' ? 'Confirmar Stop All (HALTED)' : 'Confirmar Retomada (ACTIVE)'}
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
};
