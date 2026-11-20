import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/translate.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';
import 'adaptive_shell.dart';

/// Workspace provisório de alta fidelidade do Lote 4 para os 11 módulos.
/// Nos Lotes 6–8 cada rota substituirá este componente pela view definitiva.
class ModulePlaceholderView extends ConsumerWidget {
  const ModulePlaceholderView({
    super.key,
    required this.module,
    this.selectedEntityId,
  });

  final NavModule module;
  final String? selectedEntityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(vyronStateProvider);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final en = lang == UiLanguage.enUS;

    final brandFilter = appState.globalBrandFilter;
    final filteredProducts = domain.products
        .where(
          (p) =>
              !p.isTest &&
              (brandFilter == 'all' ||
                  p.brandId == brandFilter ||
                  p.linkedBrandIds.contains(brandFilter)),
        )
        .toList();
    final filteredContents = domain.contents
        .where((c) => brandFilter == 'all' || c.brandId == brandFilter)
        .toList();
    final finTotals = aggregateFinanceTotals(
      domain.financeEntries,
      baseCurrency: domain.settings.baseCurrency,
      brandId: brandFilter,
      excludeTest: appState.excludeTestData,
    );

    final unreadCount = domain.notifications.where((n) => !n.read).length;
    final pendingJobs = domain.jobRuns
        .where(
          (j) =>
              j.status == JobRunStatus.running ||
              j.status == JobRunStatus.unknown,
        )
        .length;

    final title = translate(lang, moduleLabelKey(module));
    final subtitle = selectedEntityId != null
        ? '${domain.settings.baseCurrency.wire} · ${appState.globalPeriodFilter.wire} · ID: $selectedEntityId'
        : '${domain.settings.baseCurrency.wire} · ${appState.globalPeriodFilter.wire} · '
            '${brandFilter == 'all' ? translate(lang, 'nav.allBrands') : brandFilter}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VyronPageHeader(
            title: title,
            subtitle: subtitle,
            actions: [
              VyronToneBadge(
                label: module.wire.toUpperCase(),
                tone: VyronMetricTone.cobalt,
                monospace: true,
              ),
              VyronStatusLabel(
                status: translate(
                  lang,
                  domain.systemControl.state == SystemControlStatus.halted
                      ? 'controls.statusHalted'
                      : 'controls.statusActive',
                ),
                statusKey: domain.systemControl.state.wire,
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              final spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - (cols - 1) * spacing) / cols;

              final metrics = <Widget>[
                VyronMetricBlock(
                  label: translate(lang, 'overview.kpi.netCash'),
                  value: formatCurrencyForLang(
                    finTotals.netCash,
                    domain.settings.baseCurrency,
                    lang,
                  ),
                  tone: VyronMetricTone.emerald,
                ),
                VyronMetricBlock(
                  label: translate(lang, 'nav.products'),
                  value: '${filteredProducts.length}',
                  helper: en ? 'Real catalog entries' : 'Itens reais no catálogo',
                  tone: VyronMetricTone.cobalt,
                ),
                VyronMetricBlock(
                  label: translate(lang, 'nav.content'),
                  value: '${filteredContents.length}',
                  helper: en ? 'Editorial items' : 'Peças editoriais',
                  tone: VyronMetricTone.neutral,
                ),
                VyronMetricBlock(
                  label: translate(lang, 'nav.notifications'),
                  value: '$unreadCount',
                  helper: pendingJobs > 0
                      ? (en
                          ? '$pendingJobs pending run(s)'
                          : '$pendingJobs execução(ões) pendente(s)')
                      : (en ? 'Runs reconciled' : 'Execuções conciliadas'),
                  tone: pendingJobs > 0
                      ? VyronMetricTone.amber
                      : VyronMetricTone.neutral,
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final m in metrics)
                    SizedBox(width: itemWidth, child: m),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          VyronSurfacePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  en
                      ? 'Vyron native shell and reactive Riverpod domain state active (${domain.brands.length} brands, ${domain.automations.length} agents, ${domain.activities.length} audit events).'
                      : 'Shell nativo Vyron e estado reativo Riverpod ativos (${domain.brands.length} marcas, ${domain.automations.length} agentes, ${domain.activities.length} eventos de auditoria).',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
