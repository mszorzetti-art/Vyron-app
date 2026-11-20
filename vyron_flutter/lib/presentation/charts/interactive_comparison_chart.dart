import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  });

  final UiLanguage language;
  final List<VyronComparisonBarItem> items;
  final String? selectedId;
  final ValueChanged<VyronComparisonBarItem?>? onSelect;
  final String? emptyMessage;

  @override
  State<VyronInteractiveComparisonChart> createState() =>
      _VyronInteractiveComparisonChartState();
}

class _VyronInteractiveComparisonChartState
    extends State<VyronInteractiveComparisonChart> {
  String? _hoverId;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = widget.items;

    if (items.isEmpty) {
      return Container(
        key: const Key('vyron-comparison-empty'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: palette.panelBorder),
        ),
        child: Text(
          widget.emptyMessage ??
              translate(widget.language, 'charts.noComparisonBars'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
              ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var idx = 0; idx < items.length; idx++) ...[
          if (idx > 0) const SizedBox(height: 8),
          _buildRow(items[idx], maxAbs, palette, isDark),
        ],
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
                  painter: _DashedMissingTrackPainter(
                    color: palette.border,
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(3),
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
                          opacity: (isSelected ||
                                  isHovered ||
                                  widget.selectedId == null)
                              ? 1.0
                              : 0.65,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(3),
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
