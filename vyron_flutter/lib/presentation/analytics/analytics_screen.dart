import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/charts/chart_series.dart';
import '../../domain/models/content_channel_finance_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';
import '../charts/vyron_charts.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _geoTab = 'geo';
  String _exportNotice = '';

  late ChartTimeRange _chartRange;
  String _customStart = '2026-10-28';
  String _customEnd = '2026-11-18';
  bool _comparePrev = false;
  AnalyticsMetricKey _metric = AnalyticsMetricKey.views;
  String _channelFilter = 'all';
  String _categoryFilter = 'all';
  String? _selectedContentPointId;
  String? _selectedChannelId;
  String? _selectedGeoId;

  @override
  void initState() {
    super.initState();
    _chartRange = periodFilterToChartRange(
      ref.read(vyronStateProvider).globalPeriodFilter,
    );
  }

  void _handleExportCsv(
    List<BrandRollup> brandRollups,
    CurrencyCode currency,
    PeriodFilter period,
    UiLanguage lang,
  ) {
    final header = [
      translate(lang, 'analytics.csv.brand'),
      translate(lang, 'analytics.csv.stage'),
      translate(lang, 'analytics.csv.views'),
      translate(lang, 'analytics.csv.approvedProducts'),
      translate(
        lang,
        'analytics.csv.confirmedCommercial',
        {'currency': currency.wire},
      ),
    ].join(',');

    final rows = brandRollups.map(
      (r) => [
        '"${r.brand.name}"',
        '"${labelValidationStage(r.brand.validationStage, lang)}"',
        r.totalViews30d,
        r.approvedProductsCount,
        r.confirmedCommercial.toStringAsFixed(2),
      ].join(','),
    );

    final csvContent = [header, ...rows].join('\n');
    unawaited(Clipboard.setData(ClipboardData(text: csvContent)));
    setState(() {
      _exportNotice = translate(
        lang,
        'analytics.exportNotice',
        {'period': period.wire},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VyronAppState>(vyronStateProvider, (prev, next) {
      if (prev?.globalPeriodFilter != next.globalPeriodFilter) {
        setState(() {
          _chartRange = periodFilterToChartRange(next.globalPeriodFilter);
          _selectedContentPointId = null;
        });
      }
    });

    final appState = ref.watch(vyronStateProvider);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final currency = domain.settings.baseCurrency;
    final globalBrandFilter = appState.globalBrandFilter;
    final globalPeriodFilter = appState.globalPeriodFilter;
    final excludeTestData = appState.excludeTestData;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String t(String key, [Map<String, String>? params]) =>
        translate(lang, key, params);

    final filteredChannels = domain.channels
        .where(
          (c) => globalBrandFilter == 'all' || c.brandId == globalBrandFilter,
        )
        .toList();

    final effectiveChannelFilter = _channelFilter == 'all' ||
            filteredChannels.any((c) => c.id == _channelFilter)
        ? _channelFilter
        : 'all';

    final filteredContents = domain.contents
        .where(
          (c) =>
              (globalBrandFilter == 'all' || c.brandId == globalBrandFilter) &&
              c.metrics != null,
        )
        .toList();

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
      globalBrandFilter,
    );

    final totalTraffic =
        filteredChannels.fold<int>(0, (acc, c) => acc + c.views30d);
    final totalClicks = filteredContents.fold<int>(
      0,
      (acc, c) => acc + (c.metrics?.clicks ?? 0),
    );
    final totalConversions = filteredContents.fold<int>(
      0,
      (acc, c) => acc + (c.metrics?.conversions ?? 0),
    );
    final conversionRate =
        totalClicks > 0 ? (totalConversions / totalClicks) * 100.0 : 2.9;

    final brandRollups = computeBrandRollups(
      domain.brands,
      domain.channels,
      domain.products,
      domain.contents,
      domain.financeEntries,
      currency,
      excludeTest: excludeTestData,
    );

    ContentCategory? activeCategory;
    if (_categoryFilter != 'all') {
      activeCategory = ContentCategory.fromWire(_categoryFilter);
    }

    final analyticsSeriesRes = buildAnalyticsContentPoints(
      domain.contents,
      currency,
      brandId: globalBrandFilter,
      channelId: effectiveChannelFilter,
      category: activeCategory,
      range: _chartRange,
      customStart: _customStart,
      customEnd: _customEnd,
    );

    final channelComparisonRows = buildChannelComparisonItems(
      domain.channels,
      domain.brands,
      brandId: globalBrandFilter,
      metric: ChannelChartMetric.views30d,
    );

    ChannelComparisonItem? selectedChannelRow;
    if (_selectedChannelId != null) {
      for (final row in channelComparisonRows) {
        if (row.channel.id == _selectedChannelId) {
          selectedChannelRow = row;
          break;
        }
      }
    }

    final seriesConfigs = _buildMetricSeriesConfigs(
      metric: _metric,
      currency: currency,
      lang: lang,
      t: t,
    );

    final analyticsPoints = analyticsSeriesRes.items.map((item) {
      ContentItem? raw;
      for (final c in domain.contents) {
        if (c.id == item.contentId) {
          raw = c;
          break;
        }
      }
      final title = raw != null
          ? localizeContentDisplay(raw, lang).title
          : item.title;
      final shortDate = formatDateForLang(item.date, lang).substring(0, 5);
      final shortTitle = title.substring(0, math.min(14, title.length));

      return VyronTimeSeriesPoint(
        id: item.id,
        label: '$shortDate · $shortTitle',
        fullDateLabel: '${formatDateForLang(item.date, lang)} · $title',
        isEstimate: item.isEstimate,
        values: {
          'views': item.views.toDouble(),
          'clicks': item.clicks.toDouble(),
          'conversions': item.conversions.toDouble(),
          'ctr': item.ctrPct,
          'epc': item.epc,
        },
      );
    }).toList();

    AnalyticsContentPoint? selectedAnalyticsItem;
    ContentItem? selectedRawContent;
    if (_selectedContentPointId != null) {
      for (final item in analyticsSeriesRes.items) {
        if (item.id == _selectedContentPointId) {
          selectedAnalyticsItem = item;
          break;
        }
      }
      if (selectedAnalyticsItem != null) {
        for (final c in domain.contents) {
          if (c.id == selectedAnalyticsItem.contentId) {
            selectedRawContent = c;
            break;
          }
        }
      }
    }

    final geoBreakdown = [
      VyronComparisonBarItem(
        id: 'br',
        label: t('analytics.geo.br'),
        sublabel: t('analytics.geo.brSub'),
        value: 44,
        formattedValue: formatPercentForLang(44, lang, 0),
      ),
      VyronComparisonBarItem(
        id: 'us',
        label: t('analytics.geo.us'),
        sublabel: t('analytics.geo.usSub'),
        value: 33,
        formattedValue: formatPercentForLang(33, lang, 0),
      ),
      VyronComparisonBarItem(
        id: 'eu',
        label: t('analytics.geo.eu'),
        sublabel: t('analytics.geo.euSub'),
        value: 16,
        formattedValue: formatPercentForLang(16, lang, 0),
      ),
      VyronComparisonBarItem(
        id: 'other',
        label: t('analytics.geo.other'),
        sublabel: t('analytics.geo.otherSub'),
        value: 7,
        formattedValue: formatPercentForLang(7, lang, 0),
      ),
    ];

    final langBreakdown = [
      VyronComparisonBarItem(
        id: 'en',
        label: t('analytics.lang.en'),
        sublabel: t('analytics.lang.enSub'),
        value: 54,
        formattedValue: formatPercentForLang(54, lang, 0),
      ),
      VyronComparisonBarItem(
        id: 'pt',
        label: t('analytics.lang.pt'),
        sublabel: t('analytics.lang.ptSub'),
        value: 46,
        formattedValue: formatPercentForLang(46, lang, 0),
      ),
    ];

    final mlEventsCount = domain.products.fold<int>(
          0,
          (acc, p) => acc + p.decisions.length,
        ) +
        domain.activities.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: t('analytics.title'),
          subtitle: t('analytics.subtitle'),
          actions: [
            ElevatedButton.icon(
              key: const Key('analytics-export-btn'),
              onPressed: () => _handleExportCsv(
                brandRollups,
                currency,
                globalPeriodFilter,
                lang,
              ),
              icon: const Icon(Icons.download_rounded, size: 17),
              label: Text(t('analytics.exportCsv')),
            ),
          ],
        ),

        if (_exportNotice.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            key: const Key('analytics-export-notice'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: VyronColors.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: VyronColors.emerald.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              _exportNotice,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? VyronColors.emeraldDarkText
                    : VyronColors.emeraldLightText,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // KPI Row
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 960
                ? 4
                : (constraints.maxWidth >= 560 ? 2 : 1);
            const gap = 14.0;
            final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;
            final rpmVal = totalTraffic > 0
                ? (finance.confirmedCommercialResult / totalTraffic) * 1000.0
                : 0.0;
            final effValue = efficiency.realizedCashPerHour != null
                ? '${formatCurrencyForLang(efficiency.realizedCashPerHour!, currency, lang)}/h'
                : t('common.na');

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: cardW,
                  child: VyronMetricBlock(
                    label: t('analytics.kpi.traffic'),
                    value: formatCompactNumberForLang(totalTraffic, lang),
                    helper: t(
                      'analytics.kpi.window',
                      {'period': globalPeriodFilter.wire},
                    ),
                    tone: VyronMetricTone.cobalt,
                  ),
                ),
                SizedBox(
                  width: cardW,
                  child: VyronMetricBlock(
                    label: t('analytics.kpi.conversions'),
                    value: '$totalConversions',
                    helper: t('analytics.kpi.clicksConv', {
                      'clicks': formatCompactNumberForLang(totalClicks, lang),
                      'rate': formatPercentForLang(conversionRate, lang, 2),
                    }),
                  ),
                ),
                SizedBox(
                  width: cardW,
                  child: VyronMetricBlock(
                    label: t('analytics.kpi.efficiency'),
                    value: effValue,
                    helper: t('analytics.kpi.hoursScope', {
                      'hours': formatNumberForLang(
                        efficiency.totalHumanHours,
                        lang,
                        1,
                      ),
                    }),
                    tone: VyronMetricTone.emerald,
                  ),
                ),
                SizedBox(
                  width: cardW,
                  child: VyronMetricBlock(
                    label: t('analytics.kpi.rpm'),
                    value: formatCurrencyForLang(rpmVal, currency, lang),
                    helper: t('analytics.kpi.rpmHelper'),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Content Evolution + Channel Performance
        LayoutBuilder(
          builder: (context, constraints) {
            final contentPanel = _buildContentEvolutionPanel(
              context,
              lang: lang,
              currency: currency,
              palette: palette,
              t: t,
              filteredChannels: filteredChannels,
              effectiveChannelFilter: effectiveChannelFilter,
              analyticsSeriesRes: analyticsSeriesRes,
              seriesConfigs: seriesConfigs,
              analyticsPoints: analyticsPoints,
              selectedAnalyticsItem: selectedAnalyticsItem,
              selectedRawContent: selectedRawContent,
            );
            final channelPanel = _buildChannelComparisonPanel(
              context,
              lang: lang,
              palette: palette,
              isDark: isDark,
              t: t,
              rows: channelComparisonRows,
              selectedRow: selectedChannelRow,
            );

            if (constraints.maxWidth >= 960) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: contentPanel),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: channelPanel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                contentPanel,
                const SizedBox(height: 18),
                channelPanel,
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Geography / Language
        VyronSurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    t('analytics.geo.title'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  VyronSegmentedControl<String>(
                    key: const Key('analytics-geo-switch'),
                    value: _geoTab,
                    onChanged: (val) => setState(() {
                      _geoTab = val;
                      _selectedGeoId = null;
                    }),
                    options: [
                      VyronSegmentOption(
                        value: 'geo',
                        label: t('analytics.geo.tabRegion'),
                      ),
                      VyronSegmentOption(
                        value: 'lang',
                        label: t('analytics.geo.tabLang'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              VyronInteractiveComparisonChart(
                language: lang,
                selectedId: _selectedGeoId,
                onSelect: (item) => setState(() => _selectedGeoId = item?.id),
                items: _geoTab == 'geo' ? geoBreakdown : langBreakdown,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Content & Product Attribution Table / Cards
        _buildAttributionPanel(
          context,
          filteredContents: filteredContents,
          currency: currency,
          lang: lang,
          palette: palette,
          isDark: isDark,
          t: t,
        ),
        const SizedBox(height: 18),

        // Bottom Row: Anomalies & Future ML Readiness
        LayoutBuilder(
          builder: (context, constraints) {
            final anomaliesPanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('analytics.anomalies.title'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('analytics.anomalies.item1Title'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? VyronColors.emeraldDarkText
                                : VyronColors.emeraldLightText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('analytics.anomalies.item1Desc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('analytics.anomalies.item2Title'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? VyronColors.amberDarkText
                                : VyronColors.amberLightText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('analytics.anomalies.item2Desc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            final mlPanel = VyronSurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('analytics.ml.title'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t('analytics.ml.desc'),
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: palette.panelBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _AttrCell(
                            label: t('analytics.ml.samples'),
                            value: t(
                              'analytics.ml.eventsCount',
                              {'count': '$mlEventsCount'},
                            ),
                          ),
                        ),
                        Expanded(
                          child: _AttrCell(
                            label: t('analytics.ml.keys'),
                            value: t('analytics.ml.keysVal'),
                          ),
                        ),
                        Expanded(
                          child: _AttrCell(
                            label: t('analytics.ml.pipelineState'),
                            value: t('analytics.ml.planned'),
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: anomaliesPanel),
                  const SizedBox(width: 18),
                  Expanded(child: mlPanel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                anomaliesPanel,
                const SizedBox(height: 18),
                mlPanel,
              ],
            );
          },
        ),
      ],
    );
  }

  List<VyronSeriesConfig> _buildMetricSeriesConfigs({
    required AnalyticsMetricKey metric,
    required CurrencyCode currency,
    required UiLanguage lang,
    required String Function(String, [Map<String, String>?]) t,
  }) {
    if (metric == AnalyticsMetricKey.clicks) {
      return [
        VyronSeriesConfig(
          id: 'clicks',
          label: t('analytics.chart.metricClicks'),
          color: VyronColors.electricCobalt,
          areaFill: true,
        ),
        VyronSeriesConfig(
          id: 'views',
          label: t('analytics.chart.metricViews'),
          color: VyronColors.titanium,
          dashed: true,
          defaultHidden: true,
        ),
      ];
    }
    if (metric == AnalyticsMetricKey.conversions) {
      return [
        VyronSeriesConfig(
          id: 'conversions',
          label: t('analytics.chart.metricConversions'),
          color: VyronColors.amber,
          areaFill: true,
          isEstimate: true,
        ),
        VyronSeriesConfig(
          id: 'clicks',
          label: t('analytics.chart.metricClicks'),
          color: VyronColors.electricCobalt,
          defaultHidden: true,
        ),
      ];
    }
    if (metric == AnalyticsMetricKey.ctr) {
      return [
        VyronSeriesConfig(
          id: 'ctr',
          label: t('analytics.chart.metricCtr'),
          color: VyronColors.electricCobalt,
          areaFill: true,
          formatValue: (v) => formatPercentForLang(v, lang, 2),
        ),
      ];
    }
    if (metric == AnalyticsMetricKey.epc) {
      return [
        VyronSeriesConfig(
          id: 'epc',
          label: t('analytics.chart.metricEpc', {'currency': currency.wire}),
          color: VyronColors.emerald,
          areaFill: true,
          isEstimate: true,
          formatValue: (v) => formatCurrencyForLang(v, currency, lang),
        ),
      ];
    }
    return [
      VyronSeriesConfig(
        id: 'views',
        label: t('analytics.chart.primary'),
        color: VyronColors.electricCobalt,
        areaFill: true,
      ),
      VyronSeriesConfig(
        id: 'clicks',
        label: t('analytics.chart.secondary'),
        color: VyronColors.emerald,
      ),
    ];
  }

  Widget _buildContentEvolutionPanel(
    BuildContext context, {
    required UiLanguage lang,
    required CurrencyCode currency,
    required VyronPalette palette,
    required String Function(String, [Map<String, String>?]) t,
    required List<Channel> filteredChannels,
    required String effectiveChannelFilter,
    required AnalyticsContentSeriesResult analyticsSeriesRes,
    required List<VyronSeriesConfig> seriesConfigs,
    required List<VyronTimeSeriesPoint> analyticsPoints,
    required AnalyticsContentPoint? selectedAnalyticsItem,
    required ContentItem? selectedRawContent,
  }) {
    String formatVal(double v) {
      if (_metric == AnalyticsMetricKey.ctr) {
        return formatPercentForLang(v, lang, 2);
      }
      if (_metric == AnalyticsMetricKey.epc) {
        return formatCurrencyForLang(v, currency, lang);
      }
      if (_metric == AnalyticsMetricKey.conversions) {
        return '${v.round()}';
      }
      return formatCompactNumberForLang(v, lang);
    }

    return VyronSurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('analytics.chart.title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            t('analytics.chart.subtitle'),
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          VyronChartTimeframeToolbar(
            language: lang,
            range: _chartRange,
            onRangeChange: (next) => setState(() {
              _chartRange = next;
              _selectedContentPointId = null;
            }),
            customStart: _customStart,
            customEnd: _customEnd,
            onCustomStartChange: (v) => setState(() => _customStart = v),
            onCustomEndChange: (v) => setState(() => _customEnd = v),
            comparePrevious: _comparePrev,
            onToggleComparePrevious: () =>
                setState(() => _comparePrev = !_comparePrev),
            hasPreviousData: analyticsSeriesRes.previousCount > 0,
            coverageNote: t('analytics.chart.coverageNotice'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              VyronSegmentedControl<AnalyticsMetricKey>(
                key: const Key('analytics-metric-switch'),
                value: _metric,
                onChanged: (next) => setState(() => _metric = next),
                options: [
                  VyronSegmentOption(
                    value: AnalyticsMetricKey.views,
                    label: t('analytics.chart.metricViews'),
                  ),
                  VyronSegmentOption(
                    value: AnalyticsMetricKey.clicks,
                    label: t('analytics.chart.metricClicks'),
                  ),
                  VyronSegmentOption(
                    value: AnalyticsMetricKey.conversions,
                    label: t('analytics.chart.metricConversions'),
                  ),
                  VyronSegmentOption(
                    value: AnalyticsMetricKey.ctr,
                    label: t('analytics.chart.metricCtr'),
                  ),
                  VyronSegmentOption(
                    value: AnalyticsMetricKey.epc,
                    label: t(
                      'analytics.chart.metricEpc',
                      {'currency': currency.wire},
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 175,
                    child: VyronDropdownField<String>(
                      key: const Key('analytics-channel-filter'),
                      value: effectiveChannelFilter,
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(
                            t('analytics.chart.allChannels'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final ch in filteredChannels)
                          DropdownMenuItem(
                            value: ch.id,
                            child: Text(
                              ch.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (next) {
                        if (next != null) {
                          setState(() {
                            _channelFilter = next;
                            _selectedContentPointId = null;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 175,
                    child: VyronDropdownField<String>(
                      key: const Key('analytics-category-filter'),
                      value: _categoryFilter,
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(
                            t('analytics.chart.allCategories'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final cat in ContentCategory.values)
                          DropdownMenuItem(
                            value: cat.wire,
                            child: Text(
                              labelContentCategory(cat, lang),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (next) {
                        if (next != null) {
                          setState(() {
                            _categoryFilter = next;
                            _selectedContentPointId = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          VyronInteractiveTimeSeriesChart(
            language: lang,
            points: analyticsPoints,
            series: seriesConfigs,
            formatValue: formatVal,
            semanticLabel: t(
              'charts.timeSeriesAria',
              {'label': t('analytics.chart.title')},
            ),
            selectedPointId: _selectedContentPointId,
            onSelectPoint: (pt, _) =>
                setState(() => _selectedContentPointId = pt?.id),
          ),
          if (selectedAnalyticsItem != null && selectedRawContent != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('analytics-point-drilldown'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.panelBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('analytics.chart.drillTitle', {
                                'date': formatDateForLang(
                                  selectedAnalyticsItem.date,
                                  lang,
                                ),
                              }),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${localizeContentDisplay(selectedRawContent, lang).title} · ${selectedAnalyticsItem.trackingSrc}',
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: t('charts.clearPin'),
                        onPressed: () =>
                            setState(() => _selectedContentPointId = null),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t('analytics.chart.drillMetrics', {
                      'views': formatCompactNumberForLang(
                        selectedAnalyticsItem.views,
                        lang,
                      ),
                      'clicks': formatCompactNumberForLang(
                        selectedAnalyticsItem.clicks,
                        lang,
                      ),
                      'ctr': formatPercentForLang(
                        selectedAnalyticsItem.ctrPct,
                        lang,
                        2,
                      ),
                      'epc': formatCurrencyForLang(
                        selectedAnalyticsItem.epc,
                        currency,
                        lang,
                      ),
                      'conv': '${selectedAnalyticsItem.conversions}',
                      'status': labelAttributionStatus(
                        selectedRawContent.metrics?.attributionStatus ??
                            AttributionStatus.estimativaEmInvestigacao,
                        lang,
                      ),
                    }),
                    style: const TextStyle(
                      fontFamily: VyronTypography.mono,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelComparisonPanel(
    BuildContext context, {
    required UiLanguage lang,
    required VyronPalette palette,
    required bool isDark,
    required String Function(String, [Map<String, String>?]) t,
    required List<ChannelComparisonItem> rows,
    required ChannelComparisonItem? selectedRow,
  }) {
    final items = rows
        .map(
          (row) => VyronComparisonBarItem(
            id: row.channel.id,
            label: row.channel.name,
            sublabel: '${row.brandName} · ${row.channel.platform.wire}',
            value: row.rawValue,
            formattedValue: formatCompactNumberForLang(row.rawValue, lang),
            color: parseVyronHexColor(row.accentColor),
          ),
        )
        .toList();

    return VyronSurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('analytics.channelChart.title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            t('analytics.channelChart.subtitle'),
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
          const SizedBox(height: 14),
          VyronInteractiveComparisonChart(
            language: lang,
            selectedId: _selectedChannelId,
            onSelect: (bar) => setState(() => _selectedChannelId = bar?.id),
            items: items,
          ),
          if (selectedRow != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('analytics-channel-drilldown'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.panelBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _AttrCell(
                      label: t('analytics.channelChart.viewsLabel'),
                      value: formatCompactNumberForLang(
                        selectedRow.channel.views30d,
                        lang,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _AttrCell(
                      label: t('analytics.channelChart.reachLabel'),
                      value: formatCompactNumberForLang(
                        selectedRow.channel.reach30d,
                        lang,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _AttrCell(
                      label: t('analytics.channelChart.growthLabel'),
                      value:
                          '${selectedRow.channel.growthPct30d >= 0 ? '+' : ''}${formatPercentForLang(selectedRow.channel.growthPct30d, lang, 1)}',
                      color: selectedRow.channel.growthPct30d >= 0
                          ? (isDark
                              ? VyronColors.emeraldDarkText
                              : VyronColors.emeraldLightText)
                          : (isDark
                              ? VyronColors.crimsonDarkText
                              : VyronColors.crimsonLightText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttributionPanel(
    BuildContext context, {
    required List<ContentItem> filteredContents,
    required CurrencyCode currency,
    required UiLanguage lang,
    required VyronPalette palette,
    required bool isDark,
    required String Function(String, [Map<String, String>?]) t,
  }) {
    final amberColor =
        isDark ? VyronColors.amberDarkText : VyronColors.amberLightText;
    final emeraldColor =
        isDark ? VyronColors.emeraldDarkText : VyronColors.emeraldLightText;

    return VyronSurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('analytics.attribution.title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            t('analytics.attribution.subtitle'),
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var idx = 0; idx < filteredContents.length; idx++) ...[
                      () {
                        final c = filteredContents[idx];
                        final loc = localizeContentDisplay(c, lang);
                        final m = c.metrics!;
                        final rev =
                            convertCurrency(m.revenueGenerated, m.currency, currency);
                        final attrLabel = labelAttributionStatus(
                          m.attributionStatus,
                          lang,
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: idx < filteredContents.length - 1
                              ? BoxDecoration(
                                  border: Border(
                                    bottom:
                                        BorderSide(color: palette.panelBorder),
                                  ),
                                )
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    m.trackingSrc,
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 11,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                  Text(
                                    attrLabel,
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 11,
                                      color: amberColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _AttrCell(
                                      label: t('analytics.attribution.colViewsRet'),
                                      value:
                                          '${formatCompactNumberForLang(m.views, lang)} (${formatPercentForLang(m.retention30sPct, lang, 0)})',
                                    ),
                                  ),
                                  Expanded(
                                    child: _AttrCell(
                                      label: t('analytics.attribution.colClicks'),
                                      value: formatCompactNumberForLang(
                                        m.clicks,
                                        lang,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _AttrCell(
                                      label: t('analytics.attribution.colConv'),
                                      value: '${m.conversions}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _AttrCell(
                                      label: t('analytics.attribution.colRev', {
                                        'currency': currency.wire,
                                      }),
                                      value: formatCurrencyForLang(
                                        rev,
                                        currency,
                                        lang,
                                      ),
                                      color: emeraldColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }(),
                    ],
                  ],
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: palette.panelBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 240,
                              child: Text(
                                t('analytics.attribution.colContent'),
                                style: _thStyle(palette),
                              ),
                            ),
                            SizedBox(
                              width: 155,
                              child: Text(
                                t('analytics.attribution.colTag'),
                                style: _thStyle(palette),
                              ),
                            ),
                            SizedBox(
                              width: 175,
                              child: Text(
                                t('analytics.attribution.colStatus'),
                                style: _thStyle(palette),
                              ),
                            ),
                            SizedBox(
                              width: 115,
                              child: Text(
                                t('analytics.attribution.colViewsRet'),
                                textAlign: TextAlign.right,
                                style: _thStyle(palette),
                              ),
                            ),
                            SizedBox(
                              width: 75,
                              child: Text(
                                t('analytics.attribution.colClicks'),
                                textAlign: TextAlign.right,
                                style: _thStyle(palette),
                              ),
                            ),
                            SizedBox(
                              width: 78,
                              child: Text(
                                t('analytics.attribution.colConv'),
                                textAlign: TextAlign.right,
                                style: _thStyle(palette),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                t('analytics.attribution.colRev', {
                                  'currency': currency.wire,
                                }),
                                textAlign: TextAlign.right,
                                style: _thStyle(palette),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (var idx = 0;
                          idx < filteredContents.length;
                          idx++) ...[
                        () {
                          final c = filteredContents[idx];
                          final loc = localizeContentDisplay(c, lang);
                          final m = c.metrics!;
                          final rev = convertCurrency(
                            m.revenueGenerated,
                            m.currency,
                            currency,
                          );
                          final attrLabel = labelAttributionStatus(
                            m.attributionStatus,
                            lang,
                          );

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: idx < filteredContents.length - 1
                                ? BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: palette.panelBorder,
                                      ),
                                    ),
                                  )
                                : null,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 240,
                                  child: Text(
                                    loc.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 155,
                                  child: Text(
                                    m.trackingSrc,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 11,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 175,
                                  child: Text(
                                    attrLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 11,
                                      color: amberColor,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 115,
                                  child: Text(
                                    '${formatCompactNumberForLang(m.views, lang)} (${formatPercentForLang(m.retention30sPct, lang, 0)})',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 75,
                                  child: Text(
                                    formatCompactNumberForLang(m.clicks, lang),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 78,
                                  child: Text(
                                    '${m.conversions}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    formatCurrencyForLang(rev, currency, lang),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: emeraldColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  TextStyle _thStyle(VyronPalette palette) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: palette.textMuted,
      );
}

class _AttrCell extends StatelessWidget {
  const _AttrCell({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: palette.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: VyronTypography.mono,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}
