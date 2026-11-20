import 'package:flutter/material.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/translate.dart';
import '../../core/theme/vyron_colors.dart';
import '../../domain/charts/chart_series.dart';
import '../../domain/models/vyron_enums.dart';

class VyronChartTimeframeToolbar extends StatelessWidget {
  const VyronChartTimeframeToolbar({
    super.key,
    required this.language,
    required this.range,
    required this.onRangeChange,
    required this.customStart,
    required this.customEnd,
    required this.onCustomStartChange,
    required this.onCustomEndChange,
    this.comparePrevious = false,
    this.onToggleComparePrevious,
    this.hasPreviousData = true,
    this.coverageNote,
    this.extraControls,
  });

  final UiLanguage language;
  final ChartTimeRange range;
  final ValueChanged<ChartTimeRange> onRangeChange;
  final String customStart;
  final String customEnd;
  final ValueChanged<String> onCustomStartChange;
  final ValueChanged<String> onCustomEndChange;
  final bool comparePrevious;
  final VoidCallback? onToggleComparePrevious;
  final bool hasPreviousData;
  final String? coverageNote;
  final Widget? extraControls;

  Future<void> _pickDate(
    BuildContext context, {
    required String currentIso,
    required ValueChanged<String> onPicked,
  }) async {
    final initial = DateTime.tryParse('${currentIso}T00:00:00Z') ??
        DateTime.utc(2026, 11, 18);
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
    onPicked('$y-$m-$d');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackBg = isDark ? VyronColors.obsidianBlack : palette.surfaceAlt;
    final activeBg = isDark ? VyronColors.graphite : VyronColors.lightSurface;

    final ranges = <(ChartTimeRange, String)>[
      (ChartTimeRange.d7, translate(language, 'charts.range7d')),
      (ChartTimeRange.d30, translate(language, 'charts.range30d')),
      (ChartTimeRange.d90, translate(language, 'charts.range90d')),
      (ChartTimeRange.m12, translate(language, 'charts.range12m')),
      (ChartTimeRange.custom, translate(language, 'charts.rangeCustom')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: trackBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: palette.panelBorder),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in ranges)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: InkWell(
                              key: Key('vyron-chart-range-${item.$1.name}'),
                              onTap: () => onRangeChange(item.$1),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: range == item.$1
                                      ? activeBg
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.$2,
                                  style: TextStyle(
                                    fontFamily: VyronTypography.sans,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: range == item.$1
                                        ? palette.textPrimary
                                        : palette.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (onToggleComparePrevious != null)
                  InkWell(
                    key: const Key('vyron-chart-compare-prev'),
                    onTap: onToggleComparePrevious,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: comparePrevious
                            ? VyronColors.electricCobalt.withValues(alpha: 0.12)
                            : (isDark
                                ? VyronColors.obsidianBlack
                                : palette.surface),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: comparePrevious
                              ? VyronColors.electricCobalt
                              : palette.panelBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.compare_arrows_rounded,
                            size: 14,
                            color: comparePrevious
                                ? palette.cobaltText
                                : palette.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            translate(
                              language,
                              comparePrevious
                                  ? 'charts.compareActive'
                                  : 'charts.comparePrev',
                            ),
                            style: TextStyle(
                              fontFamily: VyronTypography.sans,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: comparePrevious
                                  ? palette.cobaltText
                                  : palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (extraControls != null) extraControls!,
          ],
        ),
        if (range == ChartTimeRange.custom) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: palette.textMuted,
              ),
              _DateChipButton(
                key: const Key('vyron-chart-custom-start'),
                label: formatDateForLang(customStart, language),
                tooltip: translate(language, 'charts.customStartAria'),
                onTap: () => _pickDate(
                  context,
                  currentIso: customStart,
                  onPicked: onCustomStartChange,
                ),
              ),
              Text(
                '—',
                style: TextStyle(
                  fontFamily: VyronTypography.sans,
                  fontSize: 11,
                  color: palette.textMuted,
                ),
              ),
              _DateChipButton(
                key: const Key('vyron-chart-custom-end'),
                label: formatDateForLang(customEnd, language),
                tooltip: translate(language, 'charts.customEndAria'),
                onTap: () => _pickDate(
                  context,
                  currentIso: customEnd,
                  onPicked: onCustomEndChange,
                ),
              ),
            ],
          ),
        ],
        if (comparePrevious && !hasPreviousData) ...[
          const SizedBox(height: 8),
          Text(
            translate(language, 'charts.prevNoDataNote'),
            style: TextStyle(
              fontFamily: VyronTypography.sans,
              fontSize: 11,
              color: isDark
                  ? VyronColors.amberDarkText
                  : VyronColors.amberLightText,
            ),
          ),
        ] else if (coverageNote != null && coverageNote!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            coverageNote!,
            style: TextStyle(
              fontFamily: VyronTypography.sans,
              fontSize: 11,
              color: palette.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _DateChipButton extends StatelessWidget {
  const _DateChipButton({
    super.key,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? VyronColors.obsidianBlack : palette.surface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: palette.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: VyronTypography.mono,
                fontSize: 11,
                color: palette.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
