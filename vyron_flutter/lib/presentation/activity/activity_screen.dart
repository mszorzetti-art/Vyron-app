import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/models/operations_settings_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  ActivityCategory? _catFilter;
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  String _formatActorLabel(String actor, UiLanguage lang) {
    if (actor == 'batch-executor') {
      return lang == UiLanguage.enUS
          ? 'Batch Runner (Local)'
          : 'Executor em Lote (Local)';
    }
    return actor;
  }

  Color _severityColor(ActivitySeverity severity, bool isDark) {
    switch (severity) {
      case ActivitySeverity.error:
        return isDark
            ? VyronColors.crimsonDarkText
            : VyronColors.crimsonLightText;
      case ActivitySeverity.warning:
        return isDark ? VyronColors.amberDarkText : VyronColors.amberLightText;
      case ActivitySeverity.success:
        return isDark
            ? VyronColors.emeraldDarkText
            : VyronColors.emeraldLightText;
      case ActivitySeverity.info:
        return isDark
            ? VyronColors.cobaltTextDark
            : VyronColors.electricCobalt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseFiltered = filterActivities(
      domain.activities,
      brandId: appState.globalBrandFilter,
      category: _catFilter,
      period: appState.globalPeriodFilter,
    );

    final localizedEvents =
        baseFiltered.map((e) => localizeActivity(e, lang)).toList();

    final trimmedQ = _query.trim().toLowerCase();
    final events = trimmedQ.isEmpty
        ? localizedEvents
        : localizedEvents.where((ev) {
            final hay = [
              ev.action,
              ev.detail,
              ev.justification ?? '',
              ev.actor,
              labelActivityCategory(ev.category, lang),
            ].join(' ').toLowerCase();
            return hay.contains(trimmedQ);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: translate(lang, 'activity.title'),
          subtitle: translate(lang, 'activity.subtitle'),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;
            final seg = VyronSegmentedControl<ActivityCategory?>(
              options: [
                VyronSegmentOption(
                  value: null,
                  label: translate(lang, 'common.all'),
                ),
                for (final c in ActivityCategory.values)
                  VyronSegmentOption(
                    value: c,
                    label: labelActivityCategory(c, lang),
                  ),
              ],
              value: _catFilter,
              onChanged: (v) => setState(() => _catFilter = v),
            );
            final search = TextField(
              key: const Key('activity-search-input'),
              controller: _queryController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: palette.textMuted,
                ),
                hintText: translate(lang, 'activity.searchPlaceholder'),
              ),
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 3, child: seg),
                  const SizedBox(width: 12),
                  SizedBox(width: 260, child: search),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                seg,
                const SizedBox(height: 10),
                search,
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        VyronSurfacePanel(
          padding: VyronPanelPadding.md,
          child: events.isEmpty
              ? VyronEmptyState(
                  title: translate(lang, 'activity.emptyTitle'),
                  description: translate(lang, 'activity.emptyDesc'),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var idx = 0; idx < events.length; idx++) ...[
                      _ActivityRow(
                        event: events[idx],
                        brandName: events[idx].brandId != null
                            ? domain.brands
                                .where((b) => b.id == events[idx].brandId)
                                .map((b) => b.name)
                                .fold<String?>(null, (_, v) => v)
                            : null,
                        actorLabel:
                            _formatActorLabel(events[idx].actor, lang),
                        severityColor:
                            _severityColor(events[idx].severity, isDark),
                        language: lang,
                        showDivider: idx < events.length - 1,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.event,
    this.brandName,
    required this.actorLabel,
    required this.severityColor,
    required this.language,
    required this.showDivider,
  });

  final ActivityEvent event;
  final String? brandName;
  final String actorLabel;
  final Color severityColor;
  final UiLanguage language;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: palette.panelBorder.withValues(alpha: 0.6),
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    event.action,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: severityColor,
                          fontSize: 13,
                        ),
                  ),
                  VyronToneBadge(
                    label: labelActivityCategory(event.category, language),
                  ),
                  if (brandName != null)
                    Text(
                      brandName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                            fontSize: 11,
                          ),
                    ),
                ],
              ),
              Text(
                '${formatDateTimeForLang(event.timestamp, language)} · $actorLabel',
                style: TextStyle(
                  fontFamily: VyronTypography.mono,
                  fontSize: 11,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            event.detail,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: palette.textMuted),
          ),
          if (event.justification != null &&
              event.justification!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? VyronColors.obsidianBlack.withValues(alpha: 0.6)
                    : palette.surfaceAlt.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.panelBorder),
              ),
              child: Text(
                translate(language, 'activity.justificationPrefix', {
                  'text': event.justification!,
                }),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: palette.textPrimary, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
