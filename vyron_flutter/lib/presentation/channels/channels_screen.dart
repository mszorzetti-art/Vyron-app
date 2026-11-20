import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/translate.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/charts/chart_series.dart';
import '../../domain/models/content_channel_finance_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../charts/vyron_charts.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  String _platformFilter = 'all';
  ChannelChartMetric _chartMetric = ChannelChartMetric.views30d;
  String? _selectedChannelId;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String t(String key, [Map<String, String>? params]) =>
        translate(lang, key, params);

    final visibleChannels = domain.channels.where((ch) {
      if (appState.globalBrandFilter != 'all' &&
          ch.brandId != appState.globalBrandFilter) {
        return false;
      }
      if (_platformFilter != 'all' && ch.platform.wire != _platformFilter) {
        return false;
      }
      return true;
    }).toList();

    final totalFollowers =
        visibleChannels.fold<int>(0, (acc, c) => acc + c.followers);
    final totalViews =
        visibleChannels.fold<int>(0, (acc, c) => acc + c.views30d);
    final ytChannels = visibleChannels
        .where((c) => c.platform == ChannelPlatform.youtube)
        .toList();
    final unlockedYtCount =
        ytChannels.where((c) => c.advancedFeaturesUnlocked).length;
    final avgShortsBridge = ytChannels.isNotEmpty
        ? ytChannels.fold<double>(
              0.0,
              (acc, c) => acc + (c.shortsToLongPct ?? 0.0),
            ) /
            ytChannels.length
        : 0.0;
    final avgEngagement = visibleChannels.isNotEmpty
        ? visibleChannels.fold<double>(
              0.0,
              (acc, c) => acc + c.engagementRatePct,
            ) /
            visibleChannels.length
        : 0.0;

    final chartRows = buildChannelComparisonItems(
      visibleChannels,
      domain.brands,
      metric: _chartMetric,
    );

    Channel? selectedChannel;
    if (_selectedChannelId != null) {
      for (final ch in visibleChannels) {
        if (ch.id == _selectedChannelId) {
          selectedChannel = ch;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: t('channels.title'),
          subtitle: t('channels.subtitle'),
          actions: [
            ElevatedButton.icon(
              key: const Key('channels-add-btn'),
              onPressed: () => _openCreateChannelModal(context, lang),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(t('channels.add')),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // KPI Row
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 960
                ? 4
                : (constraints.maxWidth >= 560 ? 2 : 1);
            const gap = 14.0;
            final cardWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: VyronMetricBlock(
                    label: t('channels.kpi.audience'),
                    value: formatCompactNumberForLang(totalFollowers, lang),
                    helper: t(
                      'channels.kpi.audienceHelper',
                      {'count': '${visibleChannels.length}'},
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: VyronMetricBlock(
                    label: t('channels.kpi.views'),
                    value: formatCompactNumberForLang(totalViews, lang),
                    helper: t(
                      'channels.kpi.viewsHelper',
                      {'pct': formatPercentForLang(avgEngagement, lang, 1)},
                    ),
                    tone: VyronMetricTone.cobalt,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: VyronMetricBlock(
                    label: t('channels.kpi.ytAdvanced'),
                    value: '$unlockedYtCount/${ytChannels.length}',
                    helper: t('channels.kpi.ytAdvancedHelper'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: VyronMetricBlock(
                    label: t('channels.kpi.shortsBridge'),
                    value: formatPercentForLang(avgShortsBridge, lang, 1),
                    helper: t('channels.kpi.shortsBridgeHelper'),
                    tone: VyronMetricTone.emerald,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Platform Segmented Filter
        Align(
          alignment: Alignment.centerLeft,
          child: VyronSegmentedControl<String>(
            key: const Key('channels-platform-filter'),
            value: _platformFilter,
            onChanged: (val) => setState(() {
              _platformFilter = val;
              _selectedChannelId = null;
            }),
            options: [
              VyronSegmentOption(
                value: 'all',
                label: t('channels.allPlatforms'),
              ),
              for (final p in ChannelPlatform.values)
                VyronSegmentOption(value: p.wire, label: p.wire),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (visibleChannels.isEmpty)
          VyronEmptyState(
            title: t('channels.emptyTitle'),
            description: t('channels.emptyDesc'),
            actionLabel: t('channels.add'),
            onAction: () => _openCreateChannelModal(context, lang),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final listPanel = _buildChannelsListPanel(
                context,
                visibleChannels: visibleChannels,
                lang: lang,
                palette: palette,
                isDark: isDark,
                t: t,
                onSync: notifier.syncChannelDemo,
              );
              final chartPanel = _buildComparisonPanel(
                context,
                chartRows: chartRows,
                selectedChannel: selectedChannel,
                lang: lang,
                palette: palette,
                t: t,
              );

              if (constraints.maxWidth >= 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: listPanel),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: chartPanel),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  listPanel,
                  const SizedBox(height: 18),
                  chartPanel,
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildChannelsListPanel(
    BuildContext context, {
    required List<Channel> visibleChannels,
    required UiLanguage lang,
    required VyronPalette palette,
    required bool isDark,
    required String Function(String, [Map<String, String>?]) t,
    required void Function(String id) onSync,
  }) {
    final domain = ref.read(vyronStateProvider).domain;

    String findBrandName(String brandId) {
      for (final b in domain.brands) {
        if (b.id == brandId) return b.name;
      }
      return brandId;
    }

    return VyronSurfacePanel(
      padding: VyronPanelPadding.none,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var idx = 0; idx < visibleChannels.length; idx++) ...[
                  () {
                    final ch = visibleChannels[idx];
                    final brandName = findBrandName(ch.brandId);
                    final growthPositive = ch.growthPct30d >= 0;
                    return Container(
                      key: Key('channel-card-${ch.id}'),
                      padding: const EdgeInsets.all(14),
                      decoration: idx < visibleChannels.length - 1
                          ? BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: palette.panelBorder),
                              ),
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ch.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$brandName · ${ch.handle}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                key: Key('channel-sync-${ch.id}'),
                                onPressed: () => onSync(ch.id),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                ),
                                label: Text(t('channels.testSync')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${ch.platform.wire} · ${ch.language}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: palette.textMuted,
                                ),
                              ),
                              Text(
                                ch.advancedFeaturesUnlocked
                                    ? t('channels.linksOk')
                                    : t('channels.linksOff'),
                                style: TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 10,
                                  color: palette.textMuted,
                                ),
                              ),
                              VyronStatusLabel(
                                status: labelChannelIntegrationStatus(
                                  ch.integrationStatus,
                                  lang,
                                ),
                                statusKey: ch.integrationStatus.wire,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _ChMetricCell(
                                  label: t('channels.table.publications'),
                                  value: '${ch.publications30d}',
                                ),
                              ),
                              Expanded(
                                child: _ChMetricCell(
                                  label: t('channels.table.growth'),
                                  value:
                                      '${growthPositive ? '+' : ''}${formatPercentForLang(ch.growthPct30d, lang, 1)}',
                                  color: growthPositive
                                      ? (isDark
                                          ? VyronColors.emeraldDarkText
                                          : VyronColors.emeraldLightText)
                                      : (isDark
                                          ? VyronColors.crimsonDarkText
                                          : VyronColors.crimsonLightText),
                                ),
                              ),
                              Expanded(
                                child: _ChMetricCell(
                                  label: t('channels.table.views'),
                                  value: formatCompactNumberForLang(
                                    ch.views30d,
                                    lang,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _ChMetricCell(
                                  label: t('channels.table.bridge'),
                                  value: ch.shortsToLongPct != null
                                      ? formatPercentForLang(
                                          ch.shortsToLongPct!,
                                          lang,
                                          1,
                                        )
                                      : '-',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt.withValues(alpha: 0.4),
                      border: Border(
                        bottom: BorderSide(color: palette.panelBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 190,
                          child: Text(
                            t('channels.table.channelBrand'),
                            style: _thStyle(palette),
                          ),
                        ),
                        SizedBox(
                          width: 145,
                          child: Text(
                            t('channels.table.platformLinks'),
                            style: _thStyle(palette),
                          ),
                        ),
                        SizedBox(
                          width: 68,
                          child: Text(
                            t('channels.table.publications'),
                            textAlign: TextAlign.right,
                            style: _thStyle(palette),
                          ),
                        ),
                        SizedBox(
                          width: 82,
                          child: Text(
                            t('channels.table.growth'),
                            textAlign: TextAlign.right,
                            style: _thStyle(palette),
                          ),
                        ),
                        SizedBox(
                          width: 82,
                          child: Text(
                            t('channels.table.views'),
                            textAlign: TextAlign.right,
                            style: _thStyle(palette),
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(
                            t('channels.table.bridge'),
                            textAlign: TextAlign.right,
                            style: _thStyle(palette),
                          ),
                        ),
                        SizedBox(
                          width: 145,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              t('channels.table.integration'),
                              style: _thStyle(palette),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 92,
                          child: Text(
                            t('channels.table.sync'),
                            textAlign: TextAlign.right,
                            style: _thStyle(palette),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var idx = 0; idx < visibleChannels.length; idx++) ...[
                    () {
                      final ch = visibleChannels[idx];
                      final brandName = findBrandName(ch.brandId);
                      final growthPositive = ch.growthPct30d >= 0;
                      return Container(
                        key: Key('channel-row-${ch.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: idx < visibleChannels.length - 1
                            ? BoxDecoration(
                                border: Border(
                                  bottom:
                                      BorderSide(color: palette.panelBorder),
                                ),
                              )
                            : null,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 190,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ch.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$brandName · ${ch.handle}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 145,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ch.platform.wire} · ${ch.language}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                  Text(
                                    ch.advancedFeaturesUnlocked
                                        ? t('channels.linksOk')
                                        : t('channels.linksOff'),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      fontSize: 10,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 68,
                              child: Text(
                                '${ch.publications30d}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 12,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 82,
                              child: Text(
                                '${growthPositive ? '+' : ''}${formatPercentForLang(ch.growthPct30d, lang, 1)}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 12,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: growthPositive
                                      ? (isDark
                                          ? VyronColors.emeraldDarkText
                                          : VyronColors.emeraldLightText)
                                      : (isDark
                                          ? VyronColors.crimsonDarkText
                                          : VyronColors.crimsonLightText),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 82,
                              child: Text(
                                formatCompactNumberForLang(ch.views30d, lang),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 12,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 72,
                              child: Text(
                                ch.shortsToLongPct != null
                                    ? formatPercentForLang(
                                        ch.shortsToLongPct!,
                                        lang,
                                        1,
                                      )
                                    : '-',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 12,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 145,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: VyronStatusLabel(
                                  status: labelChannelIntegrationStatus(
                                    ch.integrationStatus,
                                    lang,
                                  ),
                                  statusKey: ch.integrationStatus.wire,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 92,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  key: Key('channel-sync-${ch.id}'),
                                  onPressed: () => onSync(ch.id),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(0, 30),
                                  ),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 13,
                                  ),
                                  label: Text(
                                    t('channels.testSync'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
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
    );
  }

  Widget _buildComparisonPanel(
    BuildContext context, {
    required List<ChannelComparisonItem> chartRows,
    required Channel? selectedChannel,
    required UiLanguage lang,
    required VyronPalette palette,
    required String Function(String, [Map<String, String>?]) t,
  }) {
    final items = chartRows.map((row) {
      final formattedValue = switch (_chartMetric) {
        ChannelChartMetric.engagementRatePct =>
          formatPercentForLang(row.rawValue, lang, 1),
        ChannelChartMetric.growthPct30d =>
          '${row.rawValue >= 0 ? '+' : ''}${formatPercentForLang(row.rawValue, lang, 1)}',
        _ => formatCompactNumberForLang(row.rawValue, lang),
      };
      return VyronComparisonBarItem(
        id: row.channel.id,
        label: row.channel.name,
        sublabel: '${row.brandName} · ${row.channel.platform.wire}',
        value: row.rawValue,
        formattedValue: formattedValue,
        color: parseVyronHexColor(row.accentColor),
      );
    }).toList();

    return VyronSurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('channels.chartTitle'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            t('channels.chartSubtitle'),
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
          const SizedBox(height: 12),
          VyronDropdownField<ChannelChartMetric>(
            key: const Key('channels-chart-metric-dropdown'),
            value: _chartMetric,
            items: [
              DropdownMenuItem(
                value: ChannelChartMetric.views30d,
                child: Text(t('channels.chartMetric.views')),
              ),
              DropdownMenuItem(
                value: ChannelChartMetric.reach30d,
                child: Text(t('channels.chartMetric.reach')),
              ),
              DropdownMenuItem(
                value: ChannelChartMetric.followers,
                child: Text(t('channels.chartMetric.followers')),
              ),
              DropdownMenuItem(
                value: ChannelChartMetric.engagementRatePct,
                child: Text(t('channels.chartMetric.engagement')),
              ),
              DropdownMenuItem(
                value: ChannelChartMetric.growthPct30d,
                child: Text(t('channels.chartMetric.growth')),
              ),
            ],
            onChanged: (next) {
              if (next != null) setState(() => _chartMetric = next);
            },
          ),
          const SizedBox(height: 14),
          VyronInteractiveComparisonChart(
            language: lang,
            selectedId: _selectedChannelId,
            onSelect: (bar) => setState(() => _selectedChannelId = bar?.id),
            items: items,
          ),
          if (selectedChannel != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('channels-selected-detail'),
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
                    '${selectedChannel.name} (${selectedChannel.handle})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('channels.chartSelectedDetail', {
                      'platform': selectedChannel.platform.wire,
                      'publications': '${selectedChannel.publications30d}',
                      'sync': formatDateTimeForLang(
                        selectedChannel.lastSyncAt,
                        lang,
                      ),
                    }),
                    style: TextStyle(
                      fontFamily: VyronTypography.mono,
                      fontSize: 11,
                      color: palette.textMuted,
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

  TextStyle _thStyle(VyronPalette palette) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: palette.textMuted,
      );

  Future<void> _openCreateChannelModal(
    BuildContext context,
    UiLanguage lang,
  ) async {
    final domain = ref.read(vyronStateProvider).domain;
    final notifier = ref.read(vyronStateProvider.notifier);

    final nameCtrl = TextEditingController();
    final handleCtrl = TextEditingController();
    var brandId = domain.brands.isNotEmpty ? domain.brands.first.id : '';
    var platform = ChannelPlatform.youtube;
    var language = 'PT-BR';
    var advUnlocked = false;
    final formKey = GlobalKey<FormState>();

    await showVyronModalDialog<void>(
      context: context,
      title: translate(lang, 'channels.modal.title'),
      subtitle: translate(lang, 'channels.modal.subtitle'),
      language: lang,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('create-channel-name'),
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: translate(lang, 'channels.modal.nameReq'),
                      hintText:
                          translate(lang, 'channels.modal.namePlaceholder'),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '*' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: VyronDropdownField<ChannelPlatform>(
                          key: const Key('create-channel-platform'),
                          labelText:
                              translate(lang, 'channels.modal.platform'),
                          value: platform,
                          items: [
                            for (final p in ChannelPlatform.values)
                              DropdownMenuItem(value: p, child: Text(p.wire)),
                          ],
                          onChanged: (next) {
                            if (next != null) {
                              setModalState(() => platform = next);
                            }
                          },
                        ),
                      ),
                      if (domain.brands.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: VyronDropdownField<String>(
                            key: const Key('create-channel-brand'),
                            labelText: translate(lang, 'channels.modal.brand'),
                            value: brandId,
                            items: [
                              for (final b in domain.brands)
                                DropdownMenuItem(
                                  value: b.id,
                                  child: Text(
                                    b.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (next) {
                              if (next != null) {
                                setModalState(() => brandId = next);
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('create-channel-handle'),
                          controller: handleCtrl,
                          decoration: InputDecoration(
                            labelText:
                                translate(lang, 'channels.modal.handleReq'),
                            hintText: translate(
                              lang,
                              'channels.modal.handlePlaceholder',
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? '*' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: VyronDropdownField<String>(
                          key: const Key('create-channel-lang'),
                          labelText:
                              translate(lang, 'channels.modal.language'),
                          value: language,
                          items: const [
                            DropdownMenuItem(
                              value: 'PT-BR',
                              child: Text('PT-BR'),
                            ),
                            DropdownMenuItem(
                              value: 'EN-US',
                              child: Text('EN-US'),
                            ),
                            DropdownMenuItem(
                              value: 'FR-FR',
                              child: Text('FR-FR'),
                            ),
                            DropdownMenuItem(
                              value: 'ES-ES',
                              child: Text('ES-ES'),
                            ),
                          ],
                          onChanged: (next) {
                            if (next != null) {
                              setModalState(() => language = next);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    key: const Key('create-channel-adv'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: VyronColors.electricCobalt,
                    value: advUnlocked,
                    title: Text(
                      translate(lang, 'channels.modal.advCheckbox'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onChanged: (v) {
                      if (v != null) setModalState(() => advUnlocked = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(translate(lang, 'common.cancel')),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        key: const Key('create-channel-submit'),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          notifier.createChannel(
                            ChannelCreateInput(
                              brandId: brandId,
                              name: nameCtrl.text.trim(),
                              handle: handleCtrl.text.trim(),
                              platform: platform,
                              language: language,
                              advancedFeaturesUnlocked: advUnlocked,
                              integrationStatus:
                                  ChannelIntegrationStatus.configuradoDemo,
                              followers: 1200,
                              growthPct30d: 4.5,
                              views30d: 8400,
                              reach30d: 11200,
                              engagementRatePct: 4.2,
                              shortsToLongPct:
                                  platform == ChannelPlatform.youtube
                                      ? 9.0
                                      : null,
                              publications30d: 2,
                            ),
                          );
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(translate(lang, 'channels.modal.submit')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    handleCtrl.dispose();
  }
}

class _ChMetricCell extends StatelessWidget {
  const _ChMetricCell({
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
