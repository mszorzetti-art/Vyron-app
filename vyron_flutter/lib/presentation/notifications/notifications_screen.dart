import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/routing/vyron_router.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/models/operations_settings_models.dart';
import '../../domain/models/vyron_enums.dart';

enum _NotificationFilter {
  all,
  unread,
  approvalPending,
  commissionReceived,
  automationError,
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;
  bool _unreadOnlyToggle = false;

  VyronMetricTone _badgeTone(NotificationType type) {
    switch (type) {
      case NotificationType.automationError:
        return VyronMetricTone.crimson;
      case NotificationType.approvalPending:
        return VyronMetricTone.amber;
      case NotificationType.commissionReceived:
        return VyronMetricTone.emerald;
      case NotificationType.opportunity:
      case NotificationType.financial:
      case NotificationType.operational:
        return VyronMetricTone.cobalt;
    }
  }

  void _openNotificationTarget(NotificationItem item) {
    final notifier = ref.read(vyronStateProvider.notifier);
    if (!item.read) {
      notifier.markNotificationRead(item.id);
    }

    navigateToVyronModule(
      ref,
      item.targetModule,
      productId: item.targetModule == NavModule.products ? item.targetId : null,
      setProductId:
          item.targetModule == NavModule.products &&
          item.targetId != null &&
          item.targetId!.isNotEmpty,
      contentId: item.targetModule == NavModule.content ? item.targetId : null,
      setContentId:
          item.targetModule == NavModule.content &&
          item.targetId != null &&
          item.targetId!.isNotEmpty,
      automationId: item.targetModule == NavModule.automations
          ? item.targetId
          : null,
      setAutomationId:
          item.targetModule == NavModule.automations &&
          item.targetId != null &&
          item.targetId!.isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;

    final unreadCount = domain.notifications.where((n) => !n.read).length;
    final localizedItems = domain.notifications
        .map((n) => localizeNotification(n, lang))
        .toList();

    final items = localizedItems.where((n) {
      if (_unreadOnlyToggle && n.read) return false;
      switch (_filter) {
        case _NotificationFilter.all:
          return true;
        case _NotificationFilter.unread:
          return !n.read;
        case _NotificationFilter.approvalPending:
          return n.type == NotificationType.approvalPending;
        case _NotificationFilter.commissionReceived:
          return n.type == NotificationType.commissionReceived;
        case _NotificationFilter.automationError:
          return n.type == NotificationType.automationError;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: translate(lang, 'notifications.title'),
          subtitle: translate(lang, 'notifications.subtitle'),
          actions: [
            VyronToggleSwitch(
              key: const Key('notifications-unread-toggle'),
              value: _unreadOnlyToggle,
              label: translate(lang, 'notifications.unreadToggle'),
              compact: true,
              onChanged: (v) => setState(() => _unreadOnlyToggle = v),
            ),
            OutlinedButton.icon(
              key: const Key('notifications-simulate-btn'),
              onPressed: notifier.simulateNotification,
              icon: const Icon(Icons.notifications_active_outlined, size: 16),
              label: Text(translate(lang, 'notifications.simulate')),
            ),
            ElevatedButton.icon(
              key: const Key('notifications-mark-all-btn'),
              onPressed: unreadCount == 0
                  ? null
                  : notifier.markAllNotificationsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: Text(translate(lang, 'notifications.markAllRead')),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            VyronSegmentedControl<_NotificationFilter>(
              options: [
                VyronSegmentOption(
                  value: _NotificationFilter.all,
                  label: translate(lang, 'notifications.filter.all', {
                    'count': domain.notifications.length,
                  }),
                ),
                VyronSegmentOption(
                  value: _NotificationFilter.unread,
                  label: translate(lang, 'notifications.filter.unread', {
                    'count': unreadCount,
                  }),
                ),
                VyronSegmentOption(
                  value: _NotificationFilter.approvalPending,
                  label: translate(lang, 'notifications.filter.approvals'),
                ),
                VyronSegmentOption(
                  value: _NotificationFilter.commissionReceived,
                  label: translate(lang, 'notifications.filter.commissions'),
                ),
                VyronSegmentOption(
                  value: _NotificationFilter.automationError,
                  label: translate(lang, 'notifications.filter.failures'),
                ),
              ],
              value: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
            TextButton.icon(
              key: const Key('notifications-prefs-link'),
              onPressed: () => navigateToVyronModule(ref, NavModule.settings),
              icon: const Icon(Icons.tune_rounded, size: 15),
              label: Text(translate(lang, 'notifications.prefsLink')),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (items.isEmpty)
          VyronEmptyState(
            title: translate(lang, 'notifications.emptyTitle'),
            description: translate(lang, 'notifications.emptyDesc'),
          )
        else
          Column(
            children: [
              for (final item in items) ...[
                VyronSurfacePanel(
                  key: Key('notif-card-${item.id}'),
                  padding: VyronPanelPadding.md,
                  borderColor: !item.read
                      ? VyronColors.electricCobalt.withValues(alpha: 0.45)
                      : null,
                  backgroundColor: !item.read
                      ? VyronColors.electricCobalt.withValues(alpha: 0.05)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                VyronToneBadge(
                                  label: labelNotificationType(item.type, lang),
                                  tone: _badgeTone(item.type),
                                ),
                                if (!item.read)
                                  VyronToneBadge(
                                    label: translate(
                                      lang,
                                      'notifications.unreadBadge',
                                    ),
                                    tone: VyronMetricTone.cobalt,
                                  ),
                                Text(
                                  formatDateTimeForLang(item.timestamp, lang),
                                  style: TextStyle(
                                    fontFamily: VyronTypography.mono,
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          VyronToggleSwitch(
                            key: Key('notif-read-toggle-${item.id}'),
                            value: item.read,
                            compact: true,
                            label: translate(
                              lang,
                              'notifications.readSwitchLabel',
                            ),
                            onChanged: (_) =>
                                notifier.toggleNotificationRead(item.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: palette.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            key: Key('notif-open-${item.id}'),
                            onPressed: () => _openNotificationTarget(item),
                            icon: const Icon(
                              Icons.arrow_outward_rounded,
                              size: 15,
                            ),
                            label: Text(
                              translate(lang, 'notifications.openModule'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}
