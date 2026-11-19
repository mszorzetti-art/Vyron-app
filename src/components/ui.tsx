import React from 'react';
import { CheckCircle2, AlertTriangle, XCircle, Clock, PauseCircle, PlayCircle, Archive } from 'lucide-react';
import { useI18n } from '../i18n/useI18n';

export const PageHeader: React.FC<{
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
}> = ({ title, subtitle, actions }) => (
  <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pb-6 border-b border-black/10 dark:border-white/10">
    <div className="min-w-0">
      <h1 className="font-display text-2xl sm:text-[26px] font-semibold tracking-tight text-[#101216] dark:text-[#F1F2F3]">
        {title}
      </h1>
      {subtitle && (
        <p className="mt-1 text-sm text-[#525B68] dark:text-[#AEB7C2] max-w-2xl">
          {subtitle}
        </p>
      )}
    </div>
    {actions && (
      <div className="flex flex-wrap items-center gap-2.5 shrink-0">{actions}</div>
    )}
  </div>
);

export const SurfacePanel: React.FC<{
  children: React.ReactNode;
  className?: string;
  padding?: 'none' | 'sm' | 'md' | 'lg';
}> = ({ children, className = '', padding = 'md' }) => {
  const padMap = {
    none: '',
    sm: 'p-4',
    md: 'p-5',
    lg: 'p-6',
  };
  return (
    <div
      className={`bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 rounded-lg ${padMap[padding]} ${className}`}
    >
      {children}
    </div>
  );
};

export const MetricBlock: React.FC<{
  label: string;
  value: string;
  helper?: string;
  tone?: 'neutral' | 'cobalt' | 'emerald' | 'amber' | 'crimson';
  onClick?: () => void;
}> = ({ label, value, helper, tone = 'neutral', onClick }) => {
  const valueTone = {
    neutral: 'text-[#101216] dark:text-[#F1F2F3]',
    cobalt: 'text-[#315FEA] dark:text-[#6B8FFF]',
    emerald: 'text-emerald-700 dark:text-emerald-400',
    amber: 'text-amber-700 dark:text-amber-400',
    crimson: 'text-rose-700 dark:text-rose-400',
  }[tone];

  const Tag = onClick ? 'button' : 'div';
  return (
    <Tag
      type={onClick ? 'button' : undefined}
      onClick={onClick}
      className={`text-left bg-white dark:bg-[#171A20] border border-black/10 dark:border-white/10 rounded-lg p-4 sm:p-5 ${
        onClick
          ? 'hover:border-[#315FEA]/60 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]'
          : ''
      }`}
    >
      <div className="text-xs font-medium text-[#525B68] dark:text-[#AEB7C2] leading-snug">
        {label}
      </div>
      <div className={`mt-2 font-mono tabular-nums text-xl sm:text-2xl font-semibold tracking-tight ${valueTone}`}>
        {value}
      </div>
      {helper && (
        <div className="mt-1.5 text-xs text-[#525B68] dark:text-[#AEB7C2] leading-snug">
          {helper}
        </div>
      )}
    </Tag>
  );
};

export const StatusLabel: React.FC<{
  status: string;
  statusKey?: string;
}> = ({ status, statusKey }) => {
  const s = (statusKey ?? status).toLowerCase();
  let Icon = Clock;
  let colorClass = 'text-[#525B68] dark:text-[#AEB7C2]';

  if (
    s.includes('approved') ||
    s.includes('aprovado') ||
    s.includes('published') ||
    s.includes('publicado') ||
    s.includes('received') ||
    s.includes('recebido') ||
    s.includes('active') ||
    s.includes('ativo') ||
    s.includes('success') ||
    s.includes('succeeded') ||
    s.includes('concluído') ||
    s.includes('mitigado') ||
    s.includes('mitigated') ||
    s.includes('configurado') ||
    s.includes('configured') ||
    s.includes('pronto') ||
    s.includes('ready')
  ) {
    Icon = CheckCircle2;
    colorClass = 'text-emerald-700 dark:text-emerald-400';
  } else if (s.includes('running') || s.includes('em execução')) {
    Icon = PlayCircle;
    colorClass = 'text-[#315FEA] dark:text-[#6B8FFF]';
  } else if (
    s.includes('confirmed') ||
    s.includes('confirmado') ||
    s.includes('in review') ||
    s.includes('em revisão') ||
    s.includes('waiting') ||
    s.includes('aguardando') ||
    s.includes('atenção') ||
    s.includes('attention') ||
    s.includes('pendente') ||
    s.includes('pending') ||
    s.includes('infraestrutura') ||
    s.includes('infrastructure') ||
    s.includes('candidate') ||
    s.includes('candidato') ||
    s.includes('unknown') ||
    s.includes('desconhecido') ||
    s.includes('aberto') ||
    s === 'open'
  ) {
    Icon = Clock;
    colorClass = 'text-amber-700 dark:text-amber-400';
  } else if (
    s.includes('paused') ||
    s.includes('pausado') ||
    s.includes('idle') ||
    s.includes('em espera') ||
    s.includes('brief') ||
    s.includes('content plan') ||
    s.includes('planejamento') ||
    s.includes('draft') ||
    s.includes('rascunho') ||
    s.includes('not_applicable') ||
    s === 'n/a' ||
    s.includes('desativado') ||
    s.includes('disabled')
  ) {
    Icon = PauseCircle;
    colorClass = 'text-[#525B68] dark:text-[#AEB7C2]';
  } else if (s.includes('archived') || s.includes('arquivado')) {
    Icon = Archive;
    colorClass = 'text-[#525B68] dark:text-[#AEB7C2]';
  } else if (
    s.includes('rejected') ||
    s.includes('rejeitado') ||
    s.includes('error') ||
    s.includes('falh') ||
    s.includes('failed') ||
    s.includes('halted') ||
    s.includes('interrompido') ||
    s.includes('parado') ||
    s.includes('blocked') ||
    s.includes('bloqueado') ||
    s.includes('desconectado') ||
    s.includes('disconnected')
  ) {
    Icon = XCircle;
    colorClass = 'text-rose-700 dark:text-rose-400';
  }

  return (
    <span className={`inline-flex items-center gap-1.5 text-xs font-medium whitespace-nowrap ${colorClass}`}>
      <Icon className="w-3.5 h-3.5 shrink-0" aria-hidden="true" />
      <span>{status}</span>
    </span>
  );
};

export const EmptyState: React.FC<{
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
}> = ({ title, description, actionLabel, onAction }) => (
  <div className="bg-white dark:bg-[#171A20] border border-dashed border-black/15 dark:border-white/15 rounded-lg p-10 text-center">
    <AlertTriangle className="w-6 h-6 mx-auto text-[#AEB7C2]" aria-hidden="true" />
    <h3 className="mt-3 font-display text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
      {title}
    </h3>
    <p className="mt-1 text-xs text-[#525B68] dark:text-[#AEB7C2] max-w-md mx-auto">
      {description}
    </p>
    {actionLabel && onAction && (
      <button
        type="button"
        onClick={onAction}
        className="mt-4 px-4 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] transition-colors whitespace-nowrap"
      >
        {actionLabel}
      </button>
    )}
  </div>
);

export const SegmentedControl: React.FC<{
  options: Array<{ value: string; label: string }>;
  value: string;
  onChange: (val: string) => void;
  ariaLabel?: string;
}> = ({ options, value, onChange, ariaLabel }) => (
  <div
    role="tablist"
    aria-label={ariaLabel}
    className="inline-flex flex-wrap items-center gap-1 p-1 rounded-md bg-[#E6E9ED] dark:bg-[#101216] border border-black/10 dark:border-white/10"
  >
    {options.map((opt) => {
      const active = opt.value === value;
      return (
        <button
          key={opt.value}
          type="button"
          role="tab"
          aria-selected={active}
          onClick={() => onChange(opt.value)}
          className={`px-3 py-1.5 text-xs font-medium rounded whitespace-nowrap shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] ${
            active
              ? 'bg-white dark:bg-[#292E36] text-[#101216] dark:text-[#F1F2F3] shadow-xs'
              : 'text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]'
          }`}
        >
          {opt.label}
        </button>
      );
    })}
  </div>
);

export const ModalDialog: React.FC<{
  open: boolean;
  title: string;
  subtitle?: string;
  onClose: () => void;
  children: React.ReactNode;
}> = ({ open, title, subtitle, onClose, children }) => {
  const { t } = useI18n();
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/65 backdrop-blur-[2px]"
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
    >
      <div className="w-full max-w-lg bg-white dark:bg-[#171A20] border border-black/15 dark:border-white/15 rounded-lg overflow-hidden shadow-2xl max-h-[90vh] flex flex-col">
        <div className="px-6 py-4 border-b border-black/10 dark:border-white/10 flex items-start justify-between gap-4">
          <div>
            <h2 id="modal-title" className="font-display text-base font-semibold text-[#101216] dark:text-[#F1F2F3]">
              {title}
            </h2>
            {subtitle && (
              <p className="mt-0.5 text-xs text-[#525B68] dark:text-[#AEB7C2]">
                {subtitle}
              </p>
            )}
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t('common.closeWindow')}
            className="text-xs px-2.5 py-1.5 rounded border border-black/10 dark:border-white/10 text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]"
          >
            {t('common.close')}
          </button>
        </div>
        <div className="p-6 overflow-y-auto">{children}</div>
      </div>
    </div>
  );
};
