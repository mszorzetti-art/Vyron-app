import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/charts/chart_series.dart';
import '../../domain/models/brand_product_models.dart';
import '../../domain/models/content_channel_finance_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';
import '../charts/vyron_charts.dart';

enum _FinanceStageFilter {
  all,
  pending,
  confirmed,
  received,
  expenses,
  projections,
}

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  _FinanceStageFilter _stageFilter = _FinanceStageFilter.all;
  String _platformView = 'table';

  late ChartTimeRange _chartRange;
  String _customStart = '2026-10-28';
  String _customEnd = '2026-11-18';
  bool _comparePrev = false;
  SeriesAggregationMode _cashflowMode = SeriesAggregationMode.daily;
  String? _selectedCashflowDate;

  @override
  void initState() {
    super.initState();
    _chartRange = periodFilterToChartRange(
      ref.read(vyronStateProvider).globalPeriodFilter,
    );
  }

  String _brandName(List<Brand> brands, String brandId, UiLanguage lang) {
    for (final b in brands) {
      if (b.id == brandId) return b.name;
    }
    return translate(lang, 'common.na');
  }

  String _stageText(FinanceEntry entry, UiLanguage lang) {
    if (entry.isProjection) {
      return translate(lang, 'finance.stageProjection');
    }
    if (entry.type == FinanceEntryType.expense ||
        entry.type == FinanceEntryType.reinvestment) {
      return labelFinanceType(entry.type, lang);
    }
    return labelCommissionStage(entry.stage, lang);
  }

  Future<void> _openCreateModal(
    BuildContext context,
    List<Brand> brands,
    UiLanguage lang,
  ) {
    return showVyronModalDialog<void>(
      context: context,
      language: lang,
      title: translate(lang, 'finance.modal.title'),
      subtitle: translate(lang, 'finance.modal.subtitle'),
      builder: (_) => _CreateFinanceEntryForm(
        brands: brands,
        language: lang,
        defaultBrandId: brands.isNotEmpty ? brands.first.id : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VyronAppState>(vyronStateProvider, (prev, next) {
      if (prev?.globalPeriodFilter != next.globalPeriodFilter) {
        setState(() {
          _chartRange = periodFilterToChartRange(next.globalPeriodFilter);
          _selectedCashflowDate = null;
        });
      }
    });

    final appState = ref.watch(vyronStateProvider);
    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = domain.settings.baseCurrency;
    final brandFilter = appState.globalBrandFilter;
    final periodFilter = appState.globalPeriodFilter;
    final excludeTest = appState.excludeTestData;

    final summary = calculateFinanceSummary(
      domain.financeEntries,
      currency,
      brandId: brandFilter,
      period: periodFilter,
      excludeTest: excludeTest,
    );

    final startDate = getPeriodStartDate(periodFilter);
    final localizedEntries = domain.financeEntries
        .map((e) => localizeFinanceEntry(e, lang))
        .toList();

    final baseEntries = localizedEntries.where((e) {
      if (excludeTest && e.isTest) return false;
      if (brandFilter != 'all' && e.brandId != brandFilter) return false;
      if (!e.isProjection && e.date.compareTo(startDate) < 0) return false;
      return true;
    }).toList();

    final ledgerRows = baseEntries.where((e) {
      switch (_stageFilter) {
        case _FinanceStageFilter.all:
          return true;
        case _FinanceStageFilter.projections:
          return e.isProjection;
        case _FinanceStageFilter.expenses:
          return !e.isProjection &&
              (e.type == FinanceEntryType.expense ||
                  e.type == FinanceEntryType.reinvestment);
        case _FinanceStageFilter.pending:
          return !e.isProjection &&
              (e.type == FinanceEntryType.commission ||
                  e.type == FinanceEntryType.directRevenue) &&
              e.stage == CommissionStage.pending;
        case _FinanceStageFilter.confirmed:
          return !e.isProjection &&
              (e.type == FinanceEntryType.commission ||
                  e.type == FinanceEntryType.directRevenue) &&
              e.stage == CommissionStage.confirmed;
        case _FinanceStageFilter.received:
          return !e.isProjection &&
              (e.type == FinanceEntryType.commission ||
                  e.type == FinanceEntryType.directRevenue) &&
              e.stage == CommissionStage.received;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group by platform (realized/confirmed/pending, strictly excluding projections)
    final platformMap = <String, _PlatformTotals>{};
    for (final e in baseEntries) {
      if (e.isProjection) continue;
      if (e.type != FinanceEntryType.commission &&
          e.type != FinanceEntryType.directRevenue) {
        continue;
      }
      final val = convertCurrency(e.amount, e.currency, currency);
      final current = platformMap.putIfAbsent(
        e.platform,
        () => _PlatformTotals(platform: e.platform),
      );
      if (e.stage == CommissionStage.pending) current.pending += val;
      if (e.stage == CommissionStage.confirmed) current.confirmed += val;
      if (e.stage == CommissionStage.received) current.received += val;
    }
    final platformBreakdown = platformMap.values.toList()
      ..sort((a, b) => b.received.compareTo(a.received));

    final cashflowRes = buildFinanceCashflowSeries(
      domain.financeEntries,
      currency,
      brandId: brandFilter,
      range: _chartRange,
      customStart: _customStart,
      customEnd: _customEnd,
      excludeTest: excludeTest,
      includeProjections: true,
      mode: _cashflowMode,
    );

    final chartPoints = cashflowRes.points
        .map(
          (pt) => VyronTimeSeriesPoint(
            id: pt.id,
            label: pt.isProjection
                ? '${translate(lang, 'charts.projectionPrefix')} ${formatDateForLang(pt.date, lang).substring(0, math.min(5, formatDateForLang(pt.date, lang).length))}'
                : formatDateForLang(pt.date, lang).substring(
                    0,
                    math.min(5, formatDateForLang(pt.date, lang).length),
                  ),
            fullDateLabel: formatDateForLang(pt.date, lang),
            isProjection: pt.isProjection,
            values: {
              'received': pt.receivedInflow,
              'confirmed': pt.confirmedCommercial,
              'pending': pt.pendingCommissions,
              'outflows': pt.outflows,
              'projection': pt.projection,
              if (_comparePrev && cashflowRes.hasPreviousData)
                'previousReceived': pt.previousReceived,
            },
          ),
        )
        .toList();

    final chartSeries = <VyronSeriesConfig>[
      VyronSeriesConfig(
        id: 'received',
        label: translate(lang, 'finance.chart.seriesReceived'),
        color: VyronColors.emerald,
        areaFill: true,
        strokeWidth: 2.2,
      ),
      VyronSeriesConfig(
        id: 'confirmed',
        label: translate(lang, 'finance.chart.seriesConfirmed'),
        color: VyronColors.electricCobalt,
      ),
      VyronSeriesConfig(
        id: 'pending',
        label: translate(lang, 'finance.chart.seriesPending'),
        color: VyronColors.amber,
        dashed: true,
      ),
      VyronSeriesConfig(
        id: 'outflows',
        label: translate(lang, 'finance.chart.seriesOutflows'),
        color: VyronColors.crimson,
        defaultHidden: true,
      ),
      VyronSeriesConfig(
        id: 'projection',
        label: translate(lang, 'finance.chart.seriesProjection'),
        color: palette.textMuted,
        dashed: true,
        isProjection: true,
      ),
      if (_comparePrev && cashflowRes.hasPreviousData)
        VyronSeriesConfig(
          id: 'previousReceived',
          label: translate(lang, 'charts.prevPeriodSeries'),
          color: palette.textMuted,
          dashed: true,
        ),
    ];

    FinanceCashflowPoint? selectedCashflowPoint;
    if (_selectedCashflowDate != null) {
      for (final pt in cashflowRes.points) {
        if (pt.id == _selectedCashflowDate || pt.date == _selectedCashflowDate) {
          selectedCashflowPoint = pt;
          break;
        }
      }
    }

    final selectedPointEntries = selectedCashflowPoint == null
        ? const <FinanceEntry>[]
        : localizedEntries.where((e) {
            if (excludeTest && e.isTest) return false;
            return selectedCashflowPoint!.entryIds.contains(e.id) ||
                e.date == selectedCashflowPoint.date;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: translate(lang, 'finance.title'),
          subtitle: translate(lang, 'finance.subtitle'),
          actions: [
            VyronToggleSwitch(
              key: const Key('finance-include-test-toggle'),
              value: !excludeTest,
              compact: true,
              label: translate(lang, 'finance.includeTest'),
              onChanged: (v) => notifier.setExcludeTestData(!v),
            ),
            VyronSegmentedControl<CurrencyCode>(
              options: const [
                VyronSegmentOption(value: CurrencyCode.brl, label: 'BRL'),
                VyronSegmentOption(value: CurrencyCode.usd, label: 'USD'),
                VyronSegmentOption(value: CurrencyCode.eur, label: 'EUR'),
              ],
              value: currency,
              onChanged: notifier.setBaseCurrency,
            ),
            ElevatedButton.icon(
              key: const Key('finance-new-entry-btn'),
              onPressed: () => _openCreateModal(context, domain.brands, lang),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(translate(lang, 'finance.newEntry')),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 4 KPI blocks
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 980
                ? 4
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
            const spacing = 12.0;
            final cardWidth =
                (constraints.maxWidth - (cols - 1) * spacing) / cols;
            final cards = [
              VyronMetricBlock(
                key: const Key('finance-kpi-pending'),
                label: translate(lang, 'finance.kpi.pending'),
                value: formatCurrencyForLang(
                  summary.pendingCommissions,
                  currency,
                  lang,
                ),
                helper: translate(lang, 'finance.kpi.pendingHelper'),
                tone: VyronMetricTone.amber,
              ),
              VyronMetricBlock(
                key: const Key('finance-kpi-confirmed'),
                label: translate(lang, 'finance.kpi.confirmed'),
                value: formatCurrencyForLang(
                  summary.confirmedCommercialResult,
                  currency,
                  lang,
                ),
                helper: translate(lang, 'finance.kpi.confirmedHelper', {
                  'amount': formatCurrencyForLang(
                    summary.confirmedAwaitingPayout,
                    currency,
                    lang,
                  ),
                }),
                tone: VyronMetricTone.cobalt,
              ),
              VyronMetricBlock(
                key: const Key('finance-kpi-budget'),
                label: translate(lang, 'finance.kpi.budget'),
                value: formatCurrencyForLang(
                  summary.availableReinvestmentBudget,
                  currency,
                  lang,
                ),
                helper: translate(lang, 'finance.kpi.budgetHelper', {
                  'amount': formatCurrencyForLang(
                    summary.receivedCashIn,
                    currency,
                    lang,
                  ),
                }),
                tone: VyronMetricTone.emerald,
              ),
              VyronMetricBlock(
                key: const Key('finance-kpi-projections'),
                label: translate(lang, 'finance.kpi.projections'),
                value: formatCurrencyForLang(
                  summary.projectedFutureRevenue,
                  currency,
                  lang,
                ),
                helper: translate(lang, 'finance.kpi.projectionsHelper'),
                tone: VyronMetricTone.neutral,
              ),
            ];
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final c in cards) SizedBox(width: cardWidth, child: c),
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Interactive Cashflow Timeline
        VyronSurfacePanel(
          padding: VyronPanelPadding.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VyronSectionTitle(
                title: translate(lang, 'finance.chart.title'),
                subtitle: translate(lang, 'finance.chart.subtitle', {
                  'currency': currency.wire,
                }),
              ),
              const SizedBox(height: 14),
              VyronChartTimeframeToolbar(
                language: lang,
                range: _chartRange,
                onRangeChange: (r) => setState(() {
                  _chartRange = r;
                  _selectedCashflowDate = null;
                }),
                customStart: _customStart,
                customEnd: _customEnd,
                onCustomStartChange: (v) => setState(() => _customStart = v),
                onCustomEndChange: (v) => setState(() => _customEnd = v),
                comparePrevious: _comparePrev,
                onToggleComparePrevious: () =>
                    setState(() => _comparePrev = !_comparePrev),
                hasPreviousData: cashflowRes.hasPreviousData,
                coverageNote: translate(lang, 'charts.coverageNote'),
                extraControls: VyronSegmentedControl<SeriesAggregationMode>(
                  options: [
                    VyronSegmentOption(
                      value: SeriesAggregationMode.daily,
                      label: translate(lang, 'finance.chart.modeDaily'),
                    ),
                    VyronSegmentOption(
                      value: SeriesAggregationMode.cumulative,
                      label: translate(lang, 'finance.chart.modeCumulative'),
                    ),
                  ],
                  value: _cashflowMode,
                  onChanged: (m) => setState(() => _cashflowMode = m),
                ),
              ),
              const SizedBox(height: 14),
              VyronInteractiveTimeSeriesChart(
                language: lang,
                points: chartPoints,
                series: chartSeries,
                formatValue: (v) => formatCurrencyForLang(v, currency, lang),
                semanticLabel: translate(lang, 'finance.chart.title'),
                selectedPointId: selectedCashflowPoint?.id,
                onSelectPoint: (pt, _) {
                  setState(() {
                    _selectedCashflowDate = pt?.id;
                  });
                },
              ),
              if (selectedCashflowPoint != null &&
                  selectedPointEntries.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  key: const Key('finance-cashflow-drilldown'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? VyronColors.obsidianBlack.withValues(alpha: 0.7)
                        : palette.surfaceAlt.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: VyronColors.electricCobalt.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              translate(lang, 'finance.chart.drillTitle', {
                                'date': formatDateForLang(
                                  selectedCashflowPoint.date,
                                  lang,
                                ),
                              }),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _selectedCashflowDate = null),
                            child: Text(translate(lang, 'charts.clearPin')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final entry in selectedPointEntries) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: palette.panelBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: palette.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_brandName(domain.brands, entry.brandId, lang)} · ${entry.platform}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: palette.textMuted,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  VyronStatusLabel(
                                    status: _stageText(entry, lang),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatCurrencyForLang(
                                      convertCurrency(
                                        entry.amount,
                                        entry.currency,
                                        currency,
                                      ),
                                      currency,
                                      lang,
                                    ),
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textPrimary,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Platform breakdown + Outflows & FX rates
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;

            final platformPanel = VyronSurfacePanel(
              padding: VyronPanelPadding.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          translate(lang, 'finance.byPlatformTitle'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      VyronSegmentedControl<String>(
                        options: [
                          VyronSegmentOption(
                            value: 'table',
                            label:
                                translate(lang, 'finance.chart.platformTableTab'),
                          ),
                          VyronSegmentOption(
                            value: 'chart',
                            label:
                                translate(lang, 'finance.chart.platformChartTab'),
                          ),
                        ],
                        value: _platformView,
                        onChanged: (v) => setState(() => _platformView = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_platformView == 'chart')
                    VyronInteractiveComparisonChart(
                      language: lang,
                      allowTableToggle: false,
                      items: [
                        for (final p in platformBreakdown)
                          VyronComparisonBarItem(
                            id: p.platform,
                            label: p.platform,
                            sublabel:
                                '${translate(lang, 'finance.col.confirmed')}: ${formatCurrencyForLang(p.confirmed, currency, lang)} · ${translate(lang, 'finance.col.pending')}: ${formatCurrencyForLang(p.pending, currency, lang)}',
                            value: p.received,
                            formattedValue: formatCurrencyForLang(
                              p.received,
                              currency,
                              lang,
                            ),
                            color: p.received > 0
                                ? VyronColors.emerald
                                : VyronColors.electricCobalt,
                          ),
                      ],
                    )
                  else if (platformBreakdown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        translate(lang, 'charts.emptyPeriod'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: palette.textMuted),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, tableCons) {
                        if (tableCons.maxWidth < 500) {
                          return Column(
                            children: [
                              for (final row in platformBreakdown) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: palette.surfaceAlt
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: palette.panelBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row.platform,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 14,
                                        runSpacing: 4,
                                        children: [
                                          _MiniVal(
                                            label: translate(
                                              lang,
                                              'finance.col.pending',
                                            ),
                                            val: formatCurrencyForLang(
                                              row.pending,
                                              currency,
                                              lang,
                                            ),
                                            color: isDark
                                                ? VyronColors.amberDarkText
                                                : VyronColors.amberLightText,
                                          ),
                                          _MiniVal(
                                            label: translate(
                                              lang,
                                              'finance.col.confirmed',
                                            ),
                                            val: formatCurrencyForLang(
                                              row.confirmed,
                                              currency,
                                              lang,
                                            ),
                                            color: palette.cobaltText,
                                          ),
                                          _MiniVal(
                                            label: translate(
                                              lang,
                                              'finance.col.received',
                                            ),
                                            val: formatCurrencyForLang(
                                              row.received,
                                              currency,
                                              lang,
                                            ),
                                            color: isDark
                                                ? VyronColors.emeraldDarkText
                                                : VyronColors.emeraldLightText,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: palette.panelBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      translate(lang, 'finance.col.platform'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(lang, 'finance.col.pending'),
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(lang, 'finance.col.confirmed'),
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(lang, 'finance.col.received'),
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final row in platformBreakdown)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: palette.panelBorder
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        row.platform,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: palette.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formatCurrencyForLang(
                                          row.pending,
                                          currency,
                                          lang,
                                        ),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 12,
                                          color: isDark
                                              ? VyronColors.amberDarkText
                                              : VyronColors.amberLightText,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formatCurrencyForLang(
                                          row.confirmed,
                                          currency,
                                          lang,
                                        ),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 12,
                                          color: palette.cobaltText,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formatCurrencyForLang(
                                          row.received,
                                          currency,
                                          lang,
                                        ),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? VyronColors.emeraldDarkText
                                              : VyronColors.emeraldLightText,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            );

            final outflowsPanel = VyronSurfacePanel(
              padding: VyronPanelPadding.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    translate(lang, 'finance.outflowsTitle'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, outCons) {
                      final twoCols = outCons.maxWidth >= 340;
                      final cards = [
                        _OutflowCard(
                          label: translate(lang, 'finance.expensesRealized'),
                          value: formatCurrencyForLang(
                            summary.expensesCashOut,
                            currency,
                            lang,
                          ),
                          valueColor: isDark
                              ? VyronColors.crimsonDarkText
                              : VyronColors.crimsonLightText,
                        ),
                        _OutflowCard(
                          label: translate(lang, 'finance.reinvestments'),
                          value: formatCurrencyForLang(
                            summary.reinvestmentsCashOut,
                            currency,
                            lang,
                          ),
                          valueColor: palette.textPrimary,
                        ),
                      ];
                      if (!twoCols) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 10),
                            cards[1],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 10),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? VyronColors.obsidianBlack.withValues(alpha: 0.65)
                          : palette.surfaceAlt.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          translate(lang, 'finance.fxTitle'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              translate(lang, 'finance.fxUsd'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: palette.textMuted),
                            ),
                            Text(
                              formatCurrencyForLang(
                                fxToBrl[CurrencyCode.usd] ?? 5.72,
                                CurrencyCode.brl,
                                lang,
                              ),
                              style: TextStyle(
                                fontFamily: VyronTypography.mono,
                                fontSize: 12,
                                color: palette.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              translate(lang, 'finance.fxEur'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: palette.textMuted),
                            ),
                            Text(
                              formatCurrencyForLang(
                                fxToBrl[CurrencyCode.eur] ?? 6.18,
                                CurrencyCode.brl,
                                lang,
                              ),
                              style: TextStyle(
                                fontFamily: VyronTypography.mono,
                                fontSize: 12,
                                color: palette.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: platformPanel),
                  const SizedBox(width: 14),
                  Expanded(child: outflowsPanel),
                ],
              );
            }
            return Column(
              children: [
                platformPanel,
                const SizedBox(height: 14),
                outflowsPanel,
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Ledger filter + Responsive ledger table/cards
        VyronSegmentedControl<_FinanceStageFilter>(
          options: [
            VyronSegmentOption(
              value: _FinanceStageFilter.all,
              label: translate(lang, 'finance.filter.all'),
            ),
            VyronSegmentOption(
              value: _FinanceStageFilter.pending,
              label: translate(lang, 'finance.filter.pending'),
            ),
            VyronSegmentOption(
              value: _FinanceStageFilter.confirmed,
              label: translate(lang, 'finance.filter.confirmed'),
            ),
            VyronSegmentOption(
              value: _FinanceStageFilter.received,
              label: translate(lang, 'finance.filter.received'),
            ),
            VyronSegmentOption(
              value: _FinanceStageFilter.expenses,
              label: translate(lang, 'finance.filter.expenses'),
            ),
            VyronSegmentOption(
              value: _FinanceStageFilter.projections,
              label: translate(lang, 'finance.filter.projections'),
            ),
          ],
          value: _stageFilter,
          onChanged: (v) => setState(() => _stageFilter = v),
        ),
        const SizedBox(height: 12),

        VyronSurfacePanel(
          padding: VyronPanelPadding.sm,
          child: ledgerRows.isEmpty
              ? VyronEmptyState(
                  title: translate(lang, 'charts.emptyPeriod'),
                  description: translate(lang, 'finance.subtitle'),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 720) {
                      return Column(
                        children: [
                          for (final row in ledgerRows) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: row.isTest
                                    ? VyronColors.amber.withValues(alpha: 0.08)
                                    : palette.surfaceAlt
                                        .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: palette.panelBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatDateForLang(row.date, lang),
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 11,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                      VyronStatusLabel(
                                        status: _stageText(row, lang),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        row.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontSize: 13),
                                      ),
                                      if (row.isProjection)
                                        VyronToneBadge(
                                          label: translate(
                                            lang,
                                            'finance.tag.projection',
                                          ),
                                        ),
                                      if (row.isTest)
                                        VyronToneBadge(
                                          label: translate(
                                            lang,
                                            'finance.tag.test',
                                          ),
                                          tone: VyronMetricTone.amber,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_brandName(domain.brands, row.brandId, lang)} · ${row.platform}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: palette.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${formatCurrencyForLang(row.amount, row.currency, lang)}${row.fxSource != null ? ' · ${row.fxSource}' : ''}',
                                          style: TextStyle(
                                            fontFamily: VyronTypography.mono,
                                            fontSize: 11,
                                            color: palette.textMuted,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        formatCurrencyForLang(
                                          convertCurrency(
                                            row.amount,
                                            row.currency,
                                            currency,
                                          ),
                                          currency,
                                          lang,
                                        ),
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: row.type ==
                                                      FinanceEntryType.expense ||
                                                  row.type ==
                                                      FinanceEntryType
                                                          .reinvestment
                                              ? (isDark
                                                  ? VyronColors.crimsonDarkText
                                                  : VyronColors
                                                      .crimsonLightText)
                                              : palette.textPrimary,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth - 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom:
                                      BorderSide(color: palette.panelBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 96,
                                    child: Text(
                                      translate(lang, 'finance.table.date'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      translate(lang, 'finance.table.desc'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      translate(
                                        lang,
                                        'finance.table.brandPlatform',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(lang, 'finance.table.stage'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(
                                        lang,
                                        'finance.table.originalFx',
                                      ),
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(
                                        lang,
                                        'finance.table.converted',
                                        {'currency': currency.wire},
                                      ),
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final row in ledgerRows)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: row.isTest
                                      ? VyronColors.amber
                                          .withValues(alpha: 0.06)
                                      : null,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: palette.panelBorder
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 96,
                                      child: Text(
                                        formatDateForLang(row.date, lang),
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 12,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              row.description,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: palette.textPrimary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            if (row.isProjection)
                                              Text(
                                                translate(
                                                  lang,
                                                  'finance.tag.projection',
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: palette.textMuted,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            if (row.isTest)
                                              VyronToneBadge(
                                                label: translate(
                                                  lang,
                                                  'finance.tag.test',
                                                ),
                                                tone: VyronMetricTone.amber,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${_brandName(domain.brands, row.brandId, lang)} · ${row.platform}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: palette.textMuted,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: VyronStatusLabel(
                                        status: _stageText(row, lang),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formatCurrencyForLang(
                                              row.amount,
                                              row.currency,
                                              lang,
                                            ),
                                            style: TextStyle(
                                              fontFamily: VyronTypography.mono,
                                              fontSize: 12,
                                              color: palette.textMuted,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          if (row.fxSource != null)
                                            Text(
                                              row.fxSource!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: palette.textMuted,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formatCurrencyForLang(
                                          convertCurrency(
                                            row.amount,
                                            row.currency,
                                            currency,
                                          ),
                                          currency,
                                          lang,
                                        ),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: row.type ==
                                                      FinanceEntryType.expense ||
                                                  row.type ==
                                                      FinanceEntryType
                                                          .reinvestment
                                              ? (isDark
                                                  ? VyronColors.crimsonDarkText
                                                  : VyronColors
                                                      .crimsonLightText)
                                              : palette.textPrimary,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PlatformTotals {
  _PlatformTotals({required this.platform});
  final String platform;
  double pending = 0;
  double confirmed = 0;
  double received = 0;
}

class _MiniVal extends StatelessWidget {
  const _MiniVal({
    required this.label,
    required this.val,
    required this.color,
  });

  final String label;
  final String val;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: VyronTypography.sans,
          fontSize: 11,
          color: palette.textMuted,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: val,
            style: TextStyle(
              fontFamily: VyronTypography.mono,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutflowCard extends StatelessWidget {
  const _OutflowCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? VyronColors.obsidianBlack.withValues(alpha: 0.65)
            : palette.surfaceAlt.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: VyronTypography.mono,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateFinanceEntryForm extends ConsumerStatefulWidget {
  const _CreateFinanceEntryForm({
    required this.brands,
    required this.language,
    required this.defaultBrandId,
  });

  final List<Brand> brands;
  final UiLanguage language;
  final String defaultBrandId;

  @override
  ConsumerState<_CreateFinanceEntryForm> createState() =>
      _CreateFinanceEntryFormState();
}

class _CreateFinanceEntryFormState
    extends ConsumerState<_CreateFinanceEntryForm> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _platformController = TextEditingController(
    text: 'Amazon Associates BR',
  );
  final TextEditingController _amountController = TextEditingController(
    text: '850',
  );

  late String _brandId;
  FinanceEntryType _type = FinanceEntryType.commission;
  CommissionStage _stage = CommissionStage.pending;
  CurrencyCode _currency = CurrencyCode.brl;
  String _date = '2026-11-18';
  bool _isProjection = false;
  bool _isTest = false;

  @override
  void initState() {
    super.initState();
    _brandId = widget.defaultBrandId;
  }

  @override
  void dispose() {
    _descController.dispose();
    _platformController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial =
        DateTime.tryParse('${_date}T00:00:00Z') ?? DateTime.utc(2026, 11, 18);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.utc(2024, 1, 1),
      lastDate: DateTime.utc(2030, 12, 31),
    );
    if (picked == null) return;
    final y = picked.year.toString().padLeft(4, '0');
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    setState(() {
      _date = '$y-$m-$d';
    });
  }

  void _submit() {
    final desc = _descController.text.trim();
    if (desc.isEmpty) return;
    final parsedAmount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ??
            0.0;
    final effectiveStage = (_type == FinanceEntryType.expense ||
            _type == FinanceEntryType.reinvestment)
        ? CommissionStage.received
        : _stage;

    ref.read(vyronStateProvider.notifier).addFinanceEntry(
          FinanceEntryCreateInput(
            brandId: _brandId,
            platform: _platformController.text.trim().isNotEmpty
                ? _platformController.text.trim()
                : 'Manual',
            description: desc,
            type: _type,
            stage: effectiveStage,
            amount: math.max(0.0, parsedAmount),
            currency: _currency,
            fxRateToBRL: fxToBrl[_currency],
            fxSource: _currency == CurrencyCode.brl
                ? 'Nativo BRL'
                : 'PTAX/BCE Manual (Demo)',
            date: _date,
            isTest: _isTest,
            isProjection: _isProjection,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final palette = context.vyronColors;
    final stageLocked = _type == FinanceEntryType.expense ||
        _type == FinanceEntryType.reinvestment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          translate(lang, 'finance.modal.descReq'),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('finance-modal-desc'),
          controller: _descController,
          decoration: InputDecoration(
            hintText: translate(lang, 'finance.modal.descPlaceholder'),
          ),
        ),
        const SizedBox(height: 12),
        VyronDropdownField<String>(
          labelText: translate(lang, 'finance.modal.brand'),
          value: _brandId,
          items: [
            for (final b in widget.brands)
              DropdownMenuItem(value: b.id, child: Text(b.name)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _brandId = v);
          },
        ),
        const SizedBox(height: 12),
        Text(
          translate(lang, 'finance.modal.platformOrigin'),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('finance-modal-platform'),
          controller: _platformController,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: VyronDropdownField<FinanceEntryType>(
                labelText: translate(lang, 'finance.modal.type'),
                value: _type,
                items: [
                  for (final t in FinanceEntryType.values)
                    DropdownMenuItem(
                      value: t,
                      child: Text(labelFinanceType(t, lang)),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _type = v;
                    if (v == FinanceEntryType.expense ||
                        v == FinanceEntryType.reinvestment) {
                      _stage = CommissionStage.received;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: IgnorePointer(
                ignoring: stageLocked,
                child: Opacity(
                  opacity: stageLocked ? 0.55 : 1.0,
                  child: VyronDropdownField<CommissionStage>(
                    labelText: translate(lang, 'finance.modal.stage'),
                    value: _stage,
                    items: [
                      DropdownMenuItem(
                        value: CommissionStage.pending,
                        child: Text(
                          translate(lang, 'finance.modal.stagePendingOpt'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: CommissionStage.confirmed,
                        child: Text(
                          translate(lang, 'finance.modal.stageConfirmedOpt'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: CommissionStage.received,
                        child: Text(
                          translate(lang, 'finance.modal.stageReceivedOpt'),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _stage = v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translate(lang, 'finance.modal.amount'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('finance-modal-amount'),
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: VyronDropdownField<CurrencyCode>(
                  labelText: translate(lang, 'finance.modal.currency'),
                  value: _currency,
                  items: const [
                    DropdownMenuItem(
                      value: CurrencyCode.brl,
                      child: Text('BRL'),
                    ),
                    DropdownMenuItem(
                      value: CurrencyCode.usd,
                      child: Text('USD'),
                    ),
                    DropdownMenuItem(
                      value: CurrencyCode.eur,
                      child: Text('EUR'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(6),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: translate(lang, 'finance.modal.date'),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDateForLang(_date, lang),
                  style: TextStyle(
                    fontFamily: VyronTypography.mono,
                    fontSize: 13,
                    color: palette.textPrimary,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: palette.textMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _isProjection,
          onChanged: (v) => setState(() => _isProjection = v ?? false),
          title: Text(
            translate(lang, 'finance.modal.isProjection'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _isTest,
          onChanged: (v) => setState(() => _isTest = v ?? false),
          title: Text(
            translate(lang, 'finance.modal.isTest'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translate(lang, 'common.cancel')),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              key: const Key('finance-modal-submit'),
              onPressed: _submit,
              child: Text(translate(lang, 'finance.modal.submit')),
            ),
          ],
        ),
      ],
    );
  }
}
