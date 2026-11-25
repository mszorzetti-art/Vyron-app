import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/i18n/translate.dart';
import '../../core/theme/vyron_colors.dart';
import '../../domain/models/vyron_enums.dart';
import 'chart_models.dart';

class VyronInteractiveComparisonChart extends StatefulWidget {
  const VyronInteractiveComparisonChart({
    super.key,
    required this.language,
    required this.items,
    this.selectedId,
    this.onSelect,
    this.emptyMessage,
    this.allowTableToggle = true,
  });

  final UiLanguage language;
  final List<VyronComparisonBarItem> items;
  final String? selectedId;
  final ValueChanged<VyronComparisonBarItem?>? onSelect;
  final String? emptyMessage;
  final bool allowTableToggle;

  @override
  State<VyronInteractiveComparisonChart> createState() =>
      _VyronInteractiveComparisonChartState();
}

class _VyronInteractiveComparisonChartState
    extends State<VyronInteractiveComparisonChart> {
  String? _hoverId;
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = widget.language;
    final items = widget.items;

    if (items.isEmpty) {
      return Container(
        key: const Key('vyron-comparison-empty'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.panelBorder),
        ),
        child: Text(
          widget.emptyMessage ?? translate(lang, 'charts.noComparisonBars'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: palette.textMuted),
        ),
      );
    }

    var maxAbs = 1.0;
    for (final item in items) {
      final v = item.value;
      if (v != null && v.isFinite) {
        maxAbs = math.max(maxAbs, v.abs());
      }
    }

    final trackBg = isDark ? VyronColors.obsidianBlack : palette.surfaceAlt;
    final activeBg = isDark ? VyronColors.graphite : VyronColors.lightSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.allowTableToggle) ...[
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: trackBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.panelBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniModeBtn(
                    key: const Key('vyron-comparison-mode-bar'),
                    icon: Icons.bar_chart_rounded,
                    label: translate(lang, 'charts.modeBar'),
                    active: !_showTable,
                    activeBg: activeBg,
                    onTap: () => setState(() => _showTable = false),
                  ),
                  const SizedBox(width: 2),
                  _MiniModeBtn(
                    key: const Key('vyron-comparison-mode-table'),
                    icon: Icons.table_chart_outlined,
                    label: translate(lang, 'charts.modeTable'),
                    active: _showTable,
                    activeBg: activeBg,
                    onTap: () => setState(() => _showTable = true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_showTable)
          _ComparisonDataTable(
            items: items,
            selectedId: widget.selectedId,
            onSelect: widget.onSelect,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var idx = 0; idx < items.length; idx++) ...[
                if (idx > 0) const SizedBox(height: 8),
                _buildRow(items[idx], maxAbs, palette, isDark),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildRow(
    VyronComparisonBarItem item,
    double maxAbs,
    VyronPaletteExtension palette,
    bool isDark,
  ) {
    final isMissing =
        item.isMissing || item.value == null || !item.value!.isFinite;
    final isSelected = widget.selectedId == item.id;
    final isHovered = _hoverId == item.id;
    final factor = isMissing
        ? 0.0
        : ((item.value!.abs() / maxAbs).clamp(0.04, 1.0)).toDouble();

    final barColor = !isMissing && (item.value ?? 0.0) < 0
        ? (isDark ? VyronColors.crimsonDarkText : VyronColors.crimsonLightText)
        : (item.color ?? VyronColors.electricCobalt);

    final rowContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: item.label,
                      style: TextStyle(
                        fontFamily: VyronTypography.sans,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                      children: [
                        if (item.badge != null && item.badge!.isNotEmpty)
                          TextSpan(
                            text: ' · ${item.badge}',
                            style: TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 10,
                              color: palette.textMuted,
                            ),
                          ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.sublabel != null && item.sublabel!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.sublabel!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: VyronTypography.sans,
                        fontSize: 11,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item.formattedValue,
              style: TextStyle(
                fontFamily: VyronTypography.mono,
                fontSize: isMissing ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: isMissing
                    ? (isDark
                          ? VyronColors.amberDarkText
                          : VyronColors.amberLightText)
                    : palette.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 8,
          width: double.infinity,
          child: isMissing
              ? CustomPaint(
                  painter: _DashedMissingTrackPainter(color: palette.border),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: isDark
                              ? VyronColors.graphite
                              : VyronColors.lightSurfaceAlt,
                        ),
                      ),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 200),
                        widthFactor: factor,
                        heightFactor: 1,
                        alignment: Alignment.centerLeft,
                        child: Opacity(
                          opacity:
                              (isSelected ||
                                  isHovered ||
                                  widget.selectedId == null)
                              ? 1.0
                              : 0.65,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  barColor.withValues(alpha: 0.85),
                                  barColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );

    if (widget.onSelect == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: rowContent,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverId = item.id),
      onExit: (_) => setState(() => _hoverId = null),
      child: Material(
        color: isSelected
            ? VyronColors.electricCobalt.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          key: Key('vyron-bar-item-${item.id}'),
          onTap: () => widget.onSelect!(isSelected ? null : item),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? VyronColors.electricCobalt
                    : Colors.transparent,
              ),
            ),
            child: rowContent,
          ),
        ),
      ),
    );
  }
}

class _MiniModeBtn extends StatelessWidget {
  const _MiniModeBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.activeBg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? palette.cobaltText : palette.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: VyronTypography.sans,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? palette.textPrimary : palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonDataTable extends StatelessWidget {
  const _ComparisonDataTable({
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final List<VyronComparisonBarItem> items;
  final String? selectedId;
  final ValueChanged<VyronComparisonBarItem?>? onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      key: const Key('vyron-comparison-table'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: palette.panelBorder),
            InkWell(
              onTap: onSelect == null
                  ? null
                  : () =>
                        onSelect!(selectedId == items[i].id ? null : items[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                color: selectedId == items[i].id
                    ? VyronColors.electricCobalt.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            items[i].label,
                            style: TextStyle(
                              fontFamily: VyronTypography.sans,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: palette.textPrimary,
                            ),
                          ),
                          if (items[i].sublabel != null &&
                              items[i].sublabel!.isNotEmpty)
                            Text(
                              items[i].sublabel!,
                              style: TextStyle(
                                fontFamily: VyronTypography.sans,
                                fontSize: 10,
                                color: palette.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      items[i].formattedValue,
                      style: TextStyle(
                        fontFamily: VyronTypography.mono,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedMissingTrackPainter extends CustomPainter {
  const _DashedMissingTrackPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      final endX = math.min(x + dash, size.width);
      canvas.drawLine(Offset(x, 0.5), Offset(endX, 0.5), paint);
      canvas.drawLine(
        Offset(x, size.height - 0.5),
        Offset(endX, size.height - 0.5),
        paint,
      );
      x += dash + gap;
    }
    canvas.drawLine(const Offset(0.5, 0), Offset(0.5, size.height), paint);
    canvas.drawLine(
      Offset(size.width - 0.5, 0),
      Offset(size.width - 0.5, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedMissingTrackPainter oldDelegate) =>
      oldDelegate.color != color;
}
