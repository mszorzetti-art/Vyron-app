import React, { useState } from 'react';
import { BellPlus, CheckCheck } from 'lucide-react';
import { useVyron } from '../context/VyronContext';
import { NotificationType } from '../types/vyron';
import { useI18n } from '../i18n/useI18n';
import { labelNotificationType } from '../i18n/domainLabels';
import { localizeNotification } from '../i18n/seedTranslations';
import {
  EmptyState,
  PageHeader,
  SegmentedControl,
  SurfacePanel,
} from '../components/ui';

export const NotificationsView: React.FC = () => {
  const {
    state,
    navigate,
    markNotificationRead,
    markAllNotificationsRead,
    simulateNotification,
  } = useVyron();
  const { lang, t, fmtDateTime } = useI18n();

  const [filter, setFilter] = useState<'all' | 'unread' | NotificationType>('all');

  const items = state.notifications.filter((n) => {
    if (filter === 'unread') return !n.read;
    if (filter !== 'all') return n.type === filter;
    return true;
  });

  const unreadCount = state.notifications.filter((n) => !n.read).length;

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('notifications.title')}
        subtitle={t('notifications.subtitle')}
        actions={
          <>
            <button
              type="button"
              onClick={simulateNotification}
              className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-medium rounded-md border border-black/10 dark:border-white/10 bg-white dark:bg-[#171A20] hover:border-[#315FEA]/50 whitespace-nowrap"
            >
              <BellPlus className="w-3.5 h-3.5" aria-hidden="true" />
              <span>{t('notifications.simulate')}</span>
            </button>
            <button
              type="button"
              onClick={markAllNotificationsRead}
              className="inline-flex items-center gap-1.5 px-3.5 py-2 text-xs font-medium rounded-md bg-[#315FEA] text-white hover:bg-[#274FC9] whitespace-nowrap"
            >
              <CheckCheck className="w-3.5 h-3.5" aria-hidden="true" />
              <span>{t('notifications.markAllRead')}</span>
            </button>
          </>
        }
      />

      <div className="flex flex-wrap items-center justify-between gap-4">
        <SegmentedControl
          ariaLabel={t('notifications.filterAria')}
          value={filter}
          onChange={(v) => setFilter(v as typeof filter)}
          options={[
            { value: 'all', label: t('notifications.filter.all', { count: state.notifications.length }) },
            { value: 'unread', label: t('notifications.filter.unread', { count: unreadCount }) },
            { value: 'approval_pending', label: t('notifications.filter.approvals') },
            { value: 'commission_received', label: t('notifications.filter.commissions') },
            { value: 'automation_error', label: t('notifications.filter.failures') },
          ]}
        />
        <button
          type="button"
          onClick={() => navigate('settings')}
          className="text-xs font-medium text-[#315FEA] dark:text-[#7FA0FF] hover:underline"
        >
          {t('notifications.prefsLink')}
        </button>
      </div>

      {items.length === 0 ? (
        <EmptyState
          title={t('notifications.emptyTitle')}
          description={t('notifications.emptyDesc')}
          actionLabel={t('notifications.simulate')}
          onAction={simulateNotification}
        />
      ) : (
        <SurfacePanel padding="none" className="overflow-hidden">
          <ul className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
            {items.map((rawN) => {
              const n = localizeNotification(rawN, lang);
              return (
                <li
                  key={n.id}
                  className={`p-4 sm:px-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4 ${
                    !n.read ? 'bg-[#315FEA]/[0.04]' : ''
                  }`}
                >
                  <div className="space-y-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-2 text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                      <span className="font-medium text-[#315FEA] dark:text-[#7FA0FF]">
                        {labelNotificationType(n.type, lang)}
                      </span>
                      <span aria-hidden="true">·</span>
                      <span className="font-mono tabular-nums">
                        {fmtDateTime(n.timestamp)}
                      </span>
                      {!n.read && (
                        <>
                          <span aria-hidden="true">·</span>
                          <span className="font-semibold text-[#101216] dark:text-[#F1F2F3]">
                            {t('notifications.unreadBadge')}
                          </span>
                        </>
                      )}
                    </div>
                    <div className="text-sm font-semibold text-[#101216] dark:text-[#F1F2F3]">
                      {n.title}
                    </div>
                    <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">{n.message}</p>
                  </div>

                  <div className="flex items-center gap-3 shrink-0 text-xs">
                    {!n.read && (
                      <button
                        type="button"
                        onClick={() => markNotificationRead(n.id)}
                        className="px-3 py-1.5 rounded border border-black/15 dark:border-white/15 hover:border-[#315FEA]"
                      >
                        {t('notifications.markRead')}
                      </button>
                    )}
                    <button
                      type="button"
                      onClick={() => {
                        markNotificationRead(n.id);
                        navigate(n.targetModule, {
                          productId: n.targetModule === 'products' ? n.targetId ?? null : null,
                          contentId: n.targetModule === 'content' ? n.targetId ?? null : null,
                        });
                      }}
                      className="px-3 py-1.5 rounded bg-[#315FEA] text-white font-medium hover:bg-[#274FC9]"
                    >
                      {t('notifications.openModule')}
                    </button>
                  </div>
                </li>
              );
            })}
          </ul>
        </SurfacePanel>
      )}
    </div>
  );
};

