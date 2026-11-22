import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/routing/vyron_router.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/charts/chart_series.dart';
import '../../domain/models/brand_product_models.dart';
import '../../domain/models/content_channel_finance_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';
import '../charts/vyron_charts.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  ChartTimeRange _chartRange = ChartTimeRange.d30;
  PeriodFilter? _lastSyncedPeriod;
  String _customStart = demoDataEarliestDate;
  String _customEnd = demoReferenceDate;
  SeriesAggregationMode _chartMode = SeriesAggregationMode.cumulative;
  bool _comparePrev = false;
  String? _selectedPointId;
  String? _selectedBrandChartId;

  String _shortDateLabel(String iso, UiLanguage lang) {
    final full = formatDateForLang(iso, lang);
    return full.length >= 5 ? full.substring(0, 5) : full;
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = domain.settings.baseCurrency;
    final globalBrandFilter = appState.globalBrandFilter;
    final globalPeriodFilter = appState.globalPeriodFilter;
    final excludeTestData = appState.excludeTestData;

    if (_lastSyncedPeriod != globalPeriodFilter) {
      _lastSyncedPeriod = globalPeriodFilter;
      _chartRange = globalPeriodFilter.asChartRange;
    }

    String t(String key, [Map<String, String>? params]) =>
        translate(lang, key, params);

    final finance = calculateFinanceSummary(
      domain.financeEntries,
      currency,
      brandId: globalBrandFilter,
      period: globalPeriodFilter,
      excludeTest: excludeTestData,
    );

    final efficiency = computeOperationalEfficiency(
      finance,
      domain.contents,
      brandId: globalBrandFilter,
    );

    final filteredProducts = domain.products.where((p) {
      if (excludeTestData && p.isTest) return false;
      if (globalBrandFilter != 'all' &&
          p.brandId != globalBrandFilter &&
          !p.linkedBrandIds.contains(globalBrandFilter)) {
        return false;
      }
      return true;
    }).toList();

    final filteredContents = domain.contents
        .where(
          (c) => globalBrandFilter == 'all' || c.brandId == globalBrandFilter,
        )
        .toList();

    final filteredActivities = domain.activities
        .where(
          (a) =>
              globalBrandFilter == 'all' ||
              a.brandId == null ||
              a.brandId == globalBrandFilter,
        )
        .take(6)
        .map((a) => localizeActivity(a, lang))
        .toList();

    final scopedBrands = domain.brands
        .where((b) => globalBrandFilter == 'all' || b.id == globalBrandFilter)
        .map((b) => localizeBrand(b, lang))
        .toList();

    final brandRollups = computeBrandRollups(
      scopedBrands,
      domain.channels,
      domain.products,
      domain.contents,
      domain.financeEntries,
      currency,
      excludeTest: excludeTestData,
    );

    final productsInAnalysis = filteredProducts
        .where((p) => p.status == ProductStatus.candidate)
        .map((p) => localizeProduct(p, lang))
        .toList();

    final contentInProduction = filteredContents
        .where(
          (c) =>
              c.status == ContentStatus.brief ||
              c.status == ContentStatus.draft ||
              c.status == ContentStatus.inReview,
        )
        .toList();

    final pendingHashReviews = filteredContents
        .where(
          (c) =>
              c.status == ContentStatus.inReview ||
              (c.authorization == null && c.status == ContentStatus.approved),
        )
        .toList();

    final orphanedJobs = domain.jobRuns
        .where(
          (j) =>
              j.status == JobRunStatus.running ||
              j.status == JobRunStatus.unknown,
        )
        .toList();

    final runningAgents = domain.automations
        .where((a) => a.state == AgentRunState.running)
        .length;
    final errorAgents = domain.automations
        .where((a) => a.state == AgentRunState.error)
        .length;
    final pendingApprovalAgents = domain.automations.fold<int>(
      0,
      (sum, a) => sum + a.pendingApprovalCount,
    );

    final financeSeriesRes = buildOverviewFinanceSeries(
      domain.financeEntries,
      currency,
      brandId: globalBrandFilter,
      range: _chartRange,
      customStart: _customStart,
      customEnd: _customEnd,
      excludeTest: excludeTestData,
      includeProjection: true,
      mode: _chartMode,
    );

    final interactivePoints = financeSeriesRes.points.map((pt) {
      final shortDate = _shortDateLabel(pt.date, lang);
      return VyronTimeSeriesPoint(
        id: pt.id,
        label: pt.isProjection
            ? '$shortDate (${t('charts.projectionPrefix')})'
            : shortDate,
        fullDateLabel: formatDateForLang(pt.date, lang),
        isProjection: pt.isProjection,
        values: {
          'confirmed': pt.confirmedCommercial,
          'received': pt.receivedCash,
          'pending': pt.pendingCommissions,
          'projection': pt.projection,
          if (_comparePrev && financeSeriesRes.hasPreviousData)
            'previousConfirmed': pt.previousConfirmed,
        },
      );
    }).toList();

    final overviewSeriesConfig = <VyronSeriesConfig>[
      VyronSeriesConfig(
        id: 'confirmed',
        label: t('overview.chart.primary'),
        color: VyronColors.electricCobalt,
        areaFill: true,
      ),
      VyronSeriesConfig(
        id: 'received',
        label: t('overview.chart.secondary'),
        color: VyronColors.emerald,
      ),
      VyronSeriesConfig(
        id: 'pending',
        label: t('overview.chart.pending'),
        color: VyronColors.amber,
      ),
      VyronSeriesConfig(
        id: 'projection',
        label: t('overview.chart.tertiary'),
        color: VyronColors.titanium,
        dashed: true,
        isProjection: true,
      ),
      if (_comparePrev && financeSeriesRes.hasPreviousData)
        VyronSeriesConfig(
          id: 'previousConfirmed',
          label: t('charts.prevPeriodSeries'),
          color: VyronColors.cobaltTextDark,
          dashed: true,
        ),
    ];

    OverviewFinancePoint? selectedOverviewPoint;
    if (_selectedPointId != null) {
      for (final pt in financeSeriesRes.points) {
        if (pt.id == _selectedPointId) {
          selectedOverviewPoint = pt;
          break;
        }
      }
    }

    final selectedOverviewEntries = selectedOverviewPoint != null
        ? domain.financeEntries
            .where((e) => selectedOverviewPoint!.entryIds.contains(e.id))
            .map((e) => localizeFinanceEntry(e, lang))
            .toList()
        : const <FinanceEntry>[];

    BrandRollup? selectedBrandRollup;
    if (_selectedBrandChartId != null) {
      for (final r in brandRollups) {
        if (r.brand.id == _selectedBrandChartId) {
          selectedBrandRollup = r;
          break;
        }
      }
    }

    final brandBarItems = brandRollups.map((r) {
      return VyronComparisonBarItem(
        id: r.brand.id,
        label: r.brand.name,
        sublabel:
            '${labelValidationStage(r.brand.validationStage, lang)} · ${formatCompactNumberForLang(r.totalViews30d, lang)} ${t('overview.brands.viewsSuffix')}',
        value: r.confirmedCommercial,
        formattedValue: formatCurrencyForLang(
          r.confirmedCommercial,
          currency,
          lang,
        ),
        color: parseVyronHexColor(r.brand.accentColor),
        badge: labelBrandStatus(r.brand.status, lang),
      );
    }).toList();

    final coverageNote = _comparePrev && !financeSeriesRes.hasPreviousData
        ? t('charts.prevNoDataNote')
        : financeSeriesRes.window.hasSparseCoverage
            ? t('charts.coverageNote')
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: t('overview.title'),
          subtitle: t(
            'overview.subtitle',
            {
              'currency': currency.wire,
              'period': globalPeriodFilter.wire,
            },
          ),
          actions: [
            OutlinedButton(
              onPressed: () => navigateToVyronModule(ref, NavModule.content),
              child: Text(
                t(
                  'overview.cta.hashApprovals',
                  {'count': '${pendingHashReviews.length}'},
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => navigateToVyronModule(ref, NavModule.products),
              child: Text(
                t(
                  'overview.cta.evaluateCandidates',
                  {'count': '${productsInAnalysis.length}'},
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Row 1: Strict Financial Separation + Operational Efficiency
        Semantics(
          label: t('overview.kpiSectionAria'),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 1040 ? 4 : (w >= 560 ? 2 : 1);
              final tileWidth = (w - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: VyronMetricBlock(
                      label: t('overview.kpi.netCash'),
                      value: formatCurrencyForLang(
                        finance.netRealizedCash,
                        currency,
                        lang,
                      ),
                      helper: t(
                        'overview.kpi.netCashHelper',
                        {
                          'amount': formatCurrencyForLang(
                            finance.receivedCashIn,
                            currency,
                            lang,
                          ),
                        },
                      ),
                      tone: finance.netRealizedCash >= 0
                          ? VyronMetricTone.emerald
                          : VyronMetricTone.crimson,
                      onTap: () => navigateToVyronModule(
                        ref,
                        NavModule.finance,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: VyronMetricBlock(
                      label: t('overview.kpi.confirmedCommercial'),
                      value: formatCurrencyForLang(
                        finance.confirmedCommercialResult,
                        currency,
                        lang,
                      ),
                      helper: t(
                        'overview.kpi.confirmedHelper',
                        {
                          'amount': formatCurrencyForLang(
                            finance.confirmedAwaitingPayout,
                            currency,
                            lang,
                          ),
                        },
                      ),
                      tone: VyronMetricTone.cobalt,
                      onTap: () => navigateToVyronModule(
                        ref,
                        NavModule.finance,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: VyronMetricBlock(
                      label: t('overview.kpi.pendingCommissions'),
                      value: formatCurrencyForLang(
                        finance.pendingCommissions,
                        currency,
                        lang,
                      ),
                      helper: t('overview.kpi.pendingHelper'),
                      tone: VyronMetricTone.amber,
                      onTap: () => navigateToVyronModule(
                        ref,
                        NavModule.finance,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: VyronMetricBlock(
                      label: t('overview.kpi.efficiency'),
                      value: efficiency.realizedCashPerHour != null
                          ? '${formatCurrencyForLang(efficiency.realizedCashPerHour!, currency, lang)}/h'
                          : t('common.na'),
                      helper: t(
                        'overview.kpi.efficiencyHelper',
                        {
                          'hours': formatNumberForLang(
                            efficiency.totalHumanHours,
                            lang,
                            1,
                          ),
                        },
                      ),
                      tone: VyronMetricTone.neutral,
                      onTap: () => navigateToVyronModule(
                        ref,
                        NavModule.analytics,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Architectural Readiness & Operational Strip
        VyronSurfacePanel(
          padding: VyronPanelPadding.md,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w >= 860 ? 4 : (w >= 520 ? 2 : 1);
              final colW = (w - (cols - 1) * 16) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: colW,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 15,
                              color: VyronColors.electricCobalt,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                t('overview.readiness.implementedTitle'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t('overview.readiness.implementedDesc'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11.5,
                                    color: palette.textMuted,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: colW,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('overview.readiness.integrationTitle'),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t(
                            'overview.readiness.integrationDesc',
                            {'count': '${pendingHashReviews.length}'},
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11.5,
                                    color: palette.textMuted,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: colW,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('overview.readiness.controlTitle'),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        VyronStatusLabel(
                          status: labelSystemControlState(
                            domain.systemControl.state,
                            lang,
                          ),
                          statusKey: domain.systemControl.state.wire,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${domain.systemControl.phaseBPublicAllowed ? t('common.publicOp') : t('common.privateEnv')} · ${domain.systemControl.publishingEnabled ? t('overview.readiness.publishingOn') : t('overview.readiness.publishingOff')}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: colW,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('overview.readiness.executorTitle'),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          orphanedJobs.isNotEmpty
                              ? t(
                                  'overview.readiness.orphanCount',
                                  {'count': '${orphanedJobs.length}'},
                                )
                              : t(
                                  'overview.readiness.reconciledCount',
                                  {'count': '${domain.jobRuns.length}'},
                                ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => navigateToVyronModule(
                            ref,
                            NavModule.settings,
                          ),
                          child: Text(
                            t('overview.readiness.viewMatrix'),
                            style: TextStyle(
                              fontFamily: VyronTypography.sans,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: palette.cobaltText,
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
        ),
        const SizedBox(height: 16),

        // Row 2: Interactive Financial Chart (7/12) + Brand Performance (5/12)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            final financeChartPanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t('overview.chart.title'),
                    subtitle: t('overview.chart.subtitle'),
                  ),
                  const SizedBox(height: 14),
                  VyronChartTimeframeToolbar(
                    language: lang,
                    range: _chartRange,
                    onRangeChange: (nextRange) {
                      setState(() {
                        _chartRange = nextRange;
                        _selectedPointId = null;
                      });
                    },
                    customStart: _customStart,
                    customEnd: _customEnd,
                    onCustomStartChange: (v) {
                      setState(() {
                        _customStart = v;
                        _selectedPointId = null;
                      });
                    },
                    onCustomEndChange: (v) {
                      setState(() {
                        _customEnd = v;
                        _selectedPointId = null;
                      });
                    },
                    comparePrevious: _comparePrev,
                    onToggleComparePrevious: () =>
                        setState(() => _comparePrev = !_comparePrev),
                    hasPreviousData: financeSeriesRes.hasPreviousData,
                    coverageNote: coverageNote,
                    extraControls: VyronSegmentedControl<SeriesAggregationMode>(
                      options: [
                        VyronSegmentOption(
                          value: SeriesAggregationMode.cumulative,
                          label: t('overview.chart.modeCumulative'),
                        ),
                        VyronSegmentOption(
                          value: SeriesAggregationMode.daily,
                          label: t('overview.chart.modeDaily'),
                        ),
                      ],
                      value: _chartMode,
                      onChanged: (mode) => setState(() => _chartMode = mode),
                    ),
                  ),
                  const SizedBox(height: 14),
                  VyronInteractiveTimeSeriesChart(
                    language: lang,
                    points: interactivePoints,
                    series: overviewSeriesConfig,
                    formatValue: (v) =>
                        formatCurrencyForLang(v, currency, lang),
                    formatYAxis: (v) =>
                        formatCompactNumberForLang(v, lang),
                    height: 245,
                    semanticLabel: t('overview.chart.title'),
                    selectedPointId: _selectedPointId,
                    onSelectPoint: (pt, _) {
                      setState(() {
                        _selectedPointId =
                            pt != null && _selectedPointId == pt.id
                                ? null
                                : pt?.id;
                      });
                    },
                  ),
                  if (selectedOverviewPoint != null) ...[
                    const SizedBox(height: 12),
                    _OverviewPointDrilldown(
                      language: lang,
                      currency: currency,
                      point: selectedOverviewPoint,
                      entries: selectedOverviewEntries,
                      brands: domain.brands,
                      onClose: () => setState(() => _selectedPointId = null),
                    ),
                  ],
                ],
              ),
            );

            final brandPerformancePanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t('overview.brands.title'),
                    subtitle: t('overview.brands.subtitle'),
                    trailing: TextButton(
                      onPressed: () =>
                          navigateToVyronModule(ref, NavModule.brands),
                      child: Text(t('overview.brands.manage')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  VyronInteractiveComparisonChart(
                    language: lang,
                    items: brandBarItems,
                    selectedId: _selectedBrandChartId,
                    onSelect: (bar) => setState(() {
                      _selectedBrandChartId = bar?.id;
                    }),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: palette.panelBorder),
                      ),
                    ),
                    child: selectedBrandRollup != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: parseVyronHexColor(
                                        selectedBrandRollup.brand.accentColor,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedBrandRollup.brand.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(
                                      () => _selectedBrandChartId = null,
                                    ),
                                    child: Text(t('common.close')),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t(
                                  'overview.brands.selectedSummary',
                                  {
                                    'received': formatCurrencyForLang(
                                      selectedBrandRollup.receivedCash,
                                      currency,
                                      lang,
                                    ),
                                    'pending': formatCurrencyForLang(
                                      selectedBrandRollup.pendingCommissions,
                                      currency,
                                      lang,
                                    ),
                                    'products':
                                        '${selectedBrandRollup.approvedProductsCount}',
                                  },
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: palette.textMuted),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => notifier
                                        .setGlobalBrandFilter(
                                      selectedBrandRollup!.brand.id,
                                    ),
                                    child:
                                        Text(t('overview.brands.isolateBrand')),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => navigateToVyronModule(
                                      ref,
                                      NavModule.brands,
                                      brandId: selectedBrandRollup!.brand.id,
                                      setBrandId: true,
                                    ),
                                    child: Text(t('overview.brands.openBrand')),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  t('overview.brands.filterHint'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.textMuted),
                                ),
                              ),
                              if (globalBrandFilter != 'all')
                                TextButton(
                                  onPressed: () =>
                                      notifier.setGlobalBrandFilter('all'),
                                  child: Text(t('overview.brands.clearFilter')),
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
                  Expanded(flex: 7, child: financeChartPanel),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: brandPerformancePanel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                financeChartPanel,
                const SizedBox(height: 16),
                brandPerformancePanel,
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Row 3: 3 Operational Queues
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 980 ? 3 : 1;
            final panelW = (w - (cols - 1) * 14) / cols;

            final productsPanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t('overview.products.title'),
                    trailing: TextButton(
                      onPressed: () =>
                          navigateToVyronModule(ref, NavModule.products),
                      child: Text(t('overview.products.viewAll')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (productsInAnalysis.isEmpty)
                    Text(
                      t('overview.products.empty'),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.textMuted),
                    )
                  else
                    for (final prod in productsInAnalysis.take(4))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _OverviewQueueItemCard(
                          onTap: () => navigateToVyronModule(
                            ref,
                            NavModule.products,
                            productId: prod.id,
                            setProductId: true,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(fontSize: 13),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${prod.platform} · ${prod.category} · ${prod.currency.wire}',
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: 11,
                                            color: palette.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    prod.opportunityScore != null
                                        ? '${prod.opportunityScore}/100'
                                        : t('common.na'),
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: palette.cobaltText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    labelProductGradeBadge(
                                      prod.qualityGrade,
                                      lang,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 10.5,
                                          color: palette.textMuted,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            );

            final contentPanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t('overview.content.title'),
                    trailing: TextButton(
                      onPressed: () => navigateToVyronModule(
                        ref,
                        NavModule.content,
                        contentSubView: ContentSubView.calendar,
                      ),
                      child: Text(t('overview.content.calendar')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final item in contentInProduction.take(4))
                    Builder(
                      builder: (context) {
                        final loc = localizeContentDisplay(item, lang);
                        Brand? brand;
                        for (final b in domain.brands) {
                          if (b.id == item.brandId) {
                            brand = b;
                            break;
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _OverviewQueueItemCard(
                            onTap: () => navigateToVyronModule(
                              ref,
                              NavModule.content,
                              contentId: item.id,
                              setContentId: true,
                              contentSubView: ContentSubView.studio,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${brand?.name ?? item.brandId} · ${labelContentFormat(item.format, lang)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 11,
                                        color: palette.textMuted,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  loc.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: VyronStatusLabel(
                                        status: labelContentStatus(
                                          item.status,
                                          lang,
                                        ),
                                        statusKey: item.status.wire,
                                      ),
                                    ),
                                    Text(
                                      formatDateForLang(
                                        item.scheduledDate,
                                        lang,
                                      ),
                                      style: TextStyle(
                                        fontFamily: VyronTypography.mono,
                                        fontSize: 11,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );

            final automationsPanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: t('overview.automations.title'),
                    trailing: TextButton(
                      onPressed: () => navigateToVyronModule(
                        ref,
                        NavModule.automations,
                      ),
                      child: Text(t('overview.automations.cta')),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniCountStat(
                          value: '$runningAgents',
                          label: t('overview.automations.running'),
                          valueColor: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniCountStat(
                          value: '$pendingApprovalAgents',
                          label: t('overview.automations.approvals'),
                          valueColor: isDark
                              ? VyronColors.amberDarkText
                              : VyronColors.amberLightText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniCountStat(
                          value: '$errorAgents',
                          label: t('overview.automations.failures'),
                          valueColor: isDark
                              ? VyronColors.crimsonDarkText
                              : VyronColors.crimsonLightText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(
                            'overview.automations.stateLabel',
                            {
                              'state': labelSystemControlState(
                                domain.systemControl.state,
                                lang,
                              ),
                            },
                          ),
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 12,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          localizeSystemControlReason(
                            domain.systemControl.reason,
                            lang,
                          ),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (domain.systemControl.state == SystemControlStatus.active)
                    OutlinedButton.icon(
                      key: const Key('overview-quick-halt-btn'),
                      onPressed: () {
                        notifier.haltSystemControl(
                          t('common.owner'),
                          t('overview.haltReasonCard'),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? VyronColors.crimsonDarkText
                            : VyronColors.crimsonLightText,
                        side: BorderSide(
                          color: VyronColors.crimson.withValues(alpha: 0.4),
                        ),
                      ),
                      icon: const Icon(Icons.pause_circle_outline, size: 16),
                      label: Text(t('overview.automations.quickHalt')),
                    )
                  else
                    ElevatedButton.icon(
                      key: const Key('overview-reconcile-resume-btn'),
                      onPressed: () {
                        notifier.reconcileJobsDemo();
                        final res = notifier.resumeSystemControl(
                          t('common.owner'),
                          t('overview.haltReasonCard'),
                        );
                        if (!res.ok && res.reason != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.reason!)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VyronColors.emerald,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(t('overview.automations.reconcileResume')),
                    ),
                ],
              ),
            );

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(width: panelW, child: productsPanel),
                SizedBox(width: panelW, child: contentPanel),
                SizedBox(width: panelW, child: automationsPanel),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Row 4: Recent Activity & Audit Trail
        VyronSurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VyronSectionTitle(
                title: t('overview.activity.title'),
                trailing: TextButton(
                  onPressed: () =>
                      navigateToVyronModule(ref, NavModule.activity),
                  child: Text(t('overview.activity.fullHistory')),
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 740) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowHeight: 36,
                          dataRowMinHeight: 46,
                          dataRowMaxHeight: 68,
                          columnSpacing: 18,
                          horizontalMargin: 8,
                          dividerThickness: 0.7,
                          columns: [
                            DataColumn(label: Text(t('common.date'))),
                            DataColumn(label: Text(t('common.category'))),
                            DataColumn(label: Text(t('common.action'))),
                            DataColumn(label: Text(t('common.detail'))),
                            DataColumn(
                              label: Text(t('overview.activity.colAuthor')),
                            ),
                          ],
                          rows: [
                            for (final act in filteredActivities)
                              DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      formatDateTimeForLang(
                                        act.timestamp,
                                        lang,
                                      ),
                                      style: TextStyle(
                                        fontFamily: VyronTypography.mono,
                                        fontSize: 11.5,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    VyronStatusLabel(
                                      status: labelActivityCategory(
                                        act.category,
                                        lang,
                                      ),
                                      statusKey: act.severity.wire,
                                    ),
                                  ),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 220),
                                      child: Text(
                                        act.action,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 280),
                                      child: Text(
                                        act.detail,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      act.actor,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final act in filteredActivities)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: palette.panelBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  VyronStatusLabel(
                                    status: labelActivityCategory(
                                      act.category,
                                      lang,
                                    ),
                                    statusKey: act.severity.wire,
                                  ),
                                  Text(
                                    formatDateTimeForLang(act.timestamp, lang),
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
                                act.action,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                act.detail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: palette.textMuted,
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
        ),
      ],
    );
  }
}

class _OverviewPointDrilldown extends StatelessWidget {
  const _OverviewPointDrilldown({
    required this.language,
    required this.currency,
    required this.point,
    required this.entries,
    required this.brands,
    required this.onClose,
  });

  final UiLanguage language;
  final CurrencyCode currency;
  final OverviewFinancePoint point;
  final List<FinanceEntry> entries;
  final List<Brand> brands;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('overview-chart-drilldown'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? VyronColors.obsidianBlack : VyronColors.coolWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: VyronColors.electricCobalt.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      translate(
                        language,
                        'overview.chart.drillTitle',
                        {'date': formatDateForLang(point.date, language)},
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (point.isProjection)
                      VyronToneBadge(
                        label: translate(
                          language,
                          'overview.chart.drillProjectionNote',
                        ),
                        tone: VyronMetricTone.amber,
                      ),
                  ],
                ),
              ),
              Text(
                translate(
                  language,
                  'overview.chart.drillCount',
                  {'count': '${entries.length}'},
                ),
                style: TextStyle(
                  fontFamily: VyronTypography.mono,
                  fontSize: 11,
                  color: palette.textMuted,
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: translate(language, 'common.close'),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(
              translate(language, 'overview.chart.drillEmpty'),
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            )
          else
            for (final e in entries)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            e.description,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${brands.cast<Brand?>().firstWhere((b) => b?.id == e.brandId, orElse: () => null)?.name ?? e.brandId} · ${labelFinanceType(e.type, language)} · ${labelCommissionStage(e.stage, language)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrencyForLang(
                            convertCurrency(e.amount, e.currency, currency),
                            currency,
                            language,
                          ),
                          style: TextStyle(
                            fontFamily: VyronTypography.mono,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                        if (e.currency != currency)
                          Text(
                            formatCurrencyForLang(
                              e.amount,
                              e.currency,
                              language,
                            ),
                            style: TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 10,
                              color: palette.textMuted,
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
  }
}

class _OverviewQueueItemCard extends StatelessWidget {
  const _OverviewQueueItemCard({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: palette.panelBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: VyronColors.electricCobalt.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    );
  }
}

class _MiniCountStat extends StatelessWidget {
  const _MiniCountStat({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: VyronTypography.mono,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
