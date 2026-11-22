import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/translate.dart';
import '../../core/theme/vyron_colors.dart';
import '../../domain/models/vyron_enums.dart';
import 'chart_models.dart';

typedef VyronPointSelectedCallback = void Function(
  VyronTimeSeriesPoint? point,
  int? index,
);

class VyronInteractiveTimeSeriesChart extends StatefulWidget {
  const VyronInteractiveTimeSeriesChart({
    super.key,
    required this.language,
    required this.points,
    required this.series,
    required this.formatValue,
    this.formatYAxis,
    this.height = 250,
    required this.semanticLabel,
    this.selectedPointId,
    this.onSelectPoint,
    this.emptyMessage,
    this.allowBarMode = true,
    this.initialDisplayMode = VyronChartDisplayMode.line,
  });

  final UiLanguage language;
  final List<VyronTimeSeriesPoint> points;
  final List<VyronSeriesConfig> series;
  final VyronValueFormatter formatValue;
  final VyronValueFormatter? formatYAxis;
  final double height;
  final String semanticLabel;
  final String? selectedPointId;
  final VyronPointSelectedCallback? onSelectPoint;
  final String? emptyMessage;
  final bool allowBarMode;
  final VyronChartDisplayMode initialDisplayMode;

  @override
  State<VyronInteractiveTimeSeriesChart> createState() =>
      _VyronInteractiveTimeSeriesChartState();
}

class _VyronInteractiveTimeSeriesChartState
    extends State<VyronInteractiveTimeSeriesChart> {
  int? _hoverIdx;
  late VyronChartDisplayMode _displayMode;
  VyronChartDisplayMode _lastChartMode = VyronChartDisplayMode.line;
  late Map<String, bool> _hiddenSeriesIds;

  @override
  void initState() {
    super.initState();
    _displayMode = widget.initialDisplayMode;
    if (widget.initialDisplayMode != VyronChartDisplayMode.table) {
      _lastChartMode = widget.initialDisplayMode;
    }
    _hiddenSeriesIds = {
      for (final s in widget.series)
        if (s.defaultHidden) s.id: true,
    };
  }

  @override
  void didUpdateWidget(covariant VyronInteractiveTimeSeriesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series != widget.series) {
      final next = <String, bool>{};
      for (final s in widget.series) {
        if (_hiddenSeriesIds.containsKey(s.id)) {
          next[s.id] = _hiddenSeriesIds[s.id]!;
        } else if (s.defaultHidden) {
          next[s.id] = true;
        }
      }
      _hiddenSeriesIds = next;
    }
    if (_hoverIdx != null && _hoverIdx! >= widget.points.length) {
      _hoverIdx = null;
    }
  }

  List<VyronSeriesConfig> get _visibleSeries => widget.series
      .where((s) => _hiddenSeriesIds[s.id] != true)
      .toList();

  int? get _selectedIdx {
    final selId = widget.selectedPointId;
    if (selId == null || selId.isEmpty) return null;
    for (var i = 0; i < widget.points.length; i++) {
      if (widget.points[i].id == selId) return i;
    }
    return null;
  }

  void _toggleSeries(String id) {
    final next = Map<String, bool>.from(_hiddenSeriesIds);
    next[id] = !(next[id] ?? false);
    final remaining = widget.series.where((s) => next[s.id] != true).length;
    if (remaining == 0) return; // Mantém ao menos 1 série ativa
    setState(() {
      _hiddenSeriesIds = next;
    });
  }

  void _setDisplayMode(VyronChartDisplayMode mode) {
    setState(() {
      if (mode != VyronChartDisplayMode.table) {
        _lastChartMode = mode;
      }
      _displayMode = mode;
    });
  }

  void _toggleTableMode() {
    if (_displayMode == VyronChartDisplayMode.table) {
      _setDisplayMode(_lastChartMode);
    } else {
      _setDisplayMode(VyronChartDisplayMode.table);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || widget.points.isEmpty) return;
    final cur = _hoverIdx ?? _selectedIdx ?? 0;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final next = math.min(widget.points.length - 1, cur + 1);
      setState(() => _hoverIdx = next);
      widget.onSelectPoint?.call(widget.points[next], next);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final prev = math.max(0, cur - 1);
      setState(() => _hoverIdx = prev);
      widget.onSelectPoint?.call(widget.points[prev], prev);
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      setState(() => _hoverIdx = 0);
      widget.onSelectPoint?.call(widget.points[0], 0);
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      final last = widget.points.length - 1;
      setState(() => _hoverIdx = last);
      widget.onSelectPoint?.call(widget.points[last], last);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _hoverIdx = null);
      widget.onSelectPoint?.call(null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = widget.language;
    final points = widget.points;

    if (points.isEmpty) {
      return Container(
        key: const Key('vyron-chart-empty'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
        decoration: BoxDecoration(
          color: palette.background.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.panelBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 22,
              color: palette.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              widget.emptyMessage ?? translate(lang, 'charts.emptyPeriod'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
            ),
          ],
        ),
      );
    }

    final visibleSeries = _visibleSeries;
    final selectedIdx = _selectedIdx;
    final activeIdx = _hoverIdx ?? selectedIdx;
    final activePoint =
        activeIdx != null && activeIdx < points.length ? points[activeIdx] : null;
    final deltaText = computePointDeltaText(
      points: points,
      visibleSeries: visibleSeries,
      activeIdx: activeIdx,
      defaultFormatter: widget.formatValue,
      language: lang,
    );

    final trackBg = isDark ? VyronColors.obsidianBlack : palette.surfaceAlt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Legenda interativa + Limpar pin + Seletor Linhas / Barras / Tabela
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in widget.series)
                  _SeriesLegendChip(
                    key: Key('vyron-chart-legend-${s.id}'),
                    config: s,
                    hidden: _hiddenSeriesIds[s.id] == true,
                    onTap: () => _toggleSeries(s.id),
                  ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.selectedPointId != null &&
                    widget.onSelectPoint != null)
                  InkWell(
                    key: const Key('vyron-chart-clear-pin'),
                    onTap: () {
                      setState(() => _hoverIdx = null);
                      widget.onSelectPoint?.call(null, null);
                    },
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: VyronColors.electricCobalt.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: palette.cobaltText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            translate(lang, 'charts.clearPin'),
                            style: TextStyle(
                              fontFamily: VyronTypography.sans,
                              fontSize: 11,
                              color: palette.cobaltText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Semantics(
                  label: translate(lang, 'charts.modeAria'),
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
                        _ChartModeButton(
                          key: const Key('vyron-chart-mode-line'),
                          icon: Icons.show_chart_rounded,
                          label: translate(lang, 'charts.modeLine'),
                          active: _displayMode == VyronChartDisplayMode.line,
                          onTap: () =>
                              _setDisplayMode(VyronChartDisplayMode.line),
                        ),
                        if (widget.allowBarMode) ...[
                          const SizedBox(width: 2),
                          _ChartModeButton(
                            key: const Key('vyron-chart-mode-bar'),
                            icon: Icons.bar_chart_rounded,
                            label: translate(lang, 'charts.modeBar'),
                            active: _displayMode == VyronChartDisplayMode.bar,
                            onTap: () =>
                                _setDisplayMode(VyronChartDisplayMode.bar),
                          ),
                        ],
                        const SizedBox(width: 2),
                        _ChartModeButton(
                          key: const Key('vyron-chart-table-toggle'),
                          icon: Icons.table_chart_outlined,
                          label: _displayMode == VyronChartDisplayMode.table
                              ? translate(lang, 'charts.toggleTableHide')
                              : translate(lang, 'charts.modeTable'),
                          active: _displayMode == VyronChartDisplayMode.table,
                          onTap: _toggleTableMode,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _displayMode == VyronChartDisplayMode.table
              ? _ChartDataTable(
                  key: const ValueKey('vyron-mode-table'),
                  points: points,
                  visibleSeries: visibleSeries,
                  selectedPointId: widget.selectedPointId,
                  formatValue: widget.formatValue,
                  language: lang,
                  onSelectPoint: widget.onSelectPoint,
                )
              : Semantics(
                  key: ValueKey('vyron-mode-${_displayMode.name}'),
                  label: widget.semanticLabel,
                  child: Focus(
                    onKeyEvent: (_, event) {
                      _handleKeyEvent(event);
                      return KeyEventResult.ignored;
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final chartWidth = constraints.maxWidth;
                        final chartSize = Size(chartWidth, widget.height);
                        final geometry = TimeSeriesChartGeometry(
                          size: chartSize,
                          points: points,
                          visibleSeries: visibleSeries,
                        );

                        void scrubAt(double dx) {
                          final idx = geometry.findNearestIndex(dx);
                          if (idx != null && idx != _hoverIdx) {
                            setState(() => _hoverIdx = idx);
                          }
                        }

                        void commitOrToggleAt(double dx) {
                          final idx = geometry.findNearestIndex(dx);
                          if (idx == null) return;
                          setState(() => _hoverIdx = idx);
                          final cb = widget.onSelectPoint;
                          if (cb == null) return;
                          final pt = points[idx];
                          if (widget.selectedPointId == pt.id) {
                            setState(() => _hoverIdx = null);
                            cb(null, null);
                          } else {
                            cb(pt, idx);
                          }
                        }

                        final activeX = activeIdx != null
                            ? geometry.xAt(activeIdx)
                            : chartWidth / 2;
                        const tooltipWidth = 242.0;
                        final flipLeft = activeX > chartWidth * 0.56;
                        final rawTooltipLeft = flipLeft
                            ? activeX - tooltipWidth - 12
                            : activeX + 12;
                        final clampedTooltipLeft = rawTooltipLeft
                            .clamp(
                              8.0,
                              math.max(8.0, chartWidth - tooltipWidth - 8.0),
                            )
                            .toDouble();

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.precise,
                              onHover: (ev) => scrubAt(ev.localPosition.dx),
                              onExit: (_) => setState(() => _hoverIdx = null),
                              child: GestureDetector(
                                key: const Key('vyron-chart-canvas'),
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) =>
                                    commitOrToggleAt(details.localPosition.dx),
                                onHorizontalDragStart: (details) =>
                                    scrubAt(details.localPosition.dx),
                                onHorizontalDragUpdate: (details) =>
                                    scrubAt(details.localPosition.dx),
                                onHorizontalDragEnd: (_) {
                                  final idx = _hoverIdx;
                                  if (idx != null &&
                                      idx < points.length &&
                                      widget.onSelectPoint != null) {
                                    widget.onSelectPoint!(points[idx], idx);
                                  }
                                  setState(() => _hoverIdx = null);
                                },
                                onLongPressStart: (details) =>
                                    scrubAt(details.localPosition.dx),
                                onLongPressMoveUpdate: (details) =>
                                    scrubAt(details.localPosition.dx),
                                onLongPressEnd: (_) {
                                  final idx = _hoverIdx;
                                  if (idx != null &&
                                      idx < points.length &&
                                      widget.onSelectPoint != null) {
                                    widget.onSelectPoint!(points[idx], idx);
                                  }
                                  setState(() => _hoverIdx = null);
                                },
                                child: SizedBox(
                                  width: chartWidth,
                                  height: widget.height,
                                  child: CustomPaint(
                                    painter: _displayMode ==
                                            VyronChartDisplayMode.bar
                                        ? _VyronTimeSeriesBarPainter(
                                            geometry: geometry,
                                            activeIdx: activeIdx,
                                            selectedIdx: selectedIdx,
                                            palette: palette,
                                            isDark: isDark,
                                            formatYAxis: widget.formatYAxis ??
                                                widget.formatValue,
                                          )
                                        : _VyronTimeSeriesPainter(
                                            geometry: geometry,
                                            activeIdx: activeIdx,
                                            selectedIdx: selectedIdx,
                                            palette: palette,
                                            isDark: isDark,
                                            formatYAxis: widget.formatYAxis ??
                                                widget.formatValue,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            if (activePoint != null && chartWidth >= 480)
                              Positioned(
                                top: 8,
                                left: clampedTooltipLeft,
                                width: tooltipWidth,
                                child: IgnorePointer(
                                  child: _FloatingChartTooltip(
                                    point: activePoint,
                                    visibleSeries: visibleSeries,
                                    defaultFormatter: widget.formatValue,
                                    deltaText: deltaText,
                                    language: lang,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 10),
        // Barra inferior permanente de leitura (essencial para touch e acessibilidade)
        Container(
          key: const Key('vyron-chart-readout'),
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: palette.panelBorder),
            ),
          ),
          child: activePoint == null
              ? Text(
                  translate(lang, 'charts.hintInteract'),
                  style: TextStyle(
                    fontFamily: VyronTypography.sans,
                    fontSize: 11,
                    color: palette.textMuted,
                  ),
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${widget.selectedPointId == activePoint.id ? '${translate(lang, 'charts.pinnedLabel')}: ' : ''}'
                      '${activePoint.fullDateLabel ?? activePoint.label}',
                      style: TextStyle(
                        fontFamily: VyronTypography.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    for (final s in visibleSeries)
                      if (activePoint.values[s.id] != null &&
                          activePoint.values[s.id]!.isFinite)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${s.label}: ',
                              style: TextStyle(
                                fontFamily: VyronTypography.mono,
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                            Text(
                              (s.formatValue ?? widget.formatValue)(
                                activePoint.values[s.id]!,
                              ),
                              style: TextStyle(
                                fontFamily: VyronTypography.mono,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: palette.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                    if (deltaText != null)
                      Text(
                        translate(
                          lang,
                          'charts.deltaFromPrev',
                          {'delta': deltaText},
                        ),
                        style: TextStyle(
                          fontFamily: VyronTypography.mono,
                          fontSize: 10,
                          color: palette.textMuted,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChartModeButton extends StatelessWidget {
  const _ChartModeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? VyronColors.graphite : VyronColors.lightSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: active
              ? Border.all(
                  color: VyronColors.electricCobalt.withValues(alpha: 0.35),
                )
              : null,
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

class _SeriesLegendChip extends StatelessWidget {
  const _SeriesLegendChip({
    super.key,
    required this.config,
    required this.hidden,
    required this.onTap,
  });

  final VyronSeriesConfig config;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: hidden ? 0.45 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: hidden
                ? Colors.transparent
                : (isDark
                    ? VyronColors.obsidianBlack
                    : VyronColors.coolWhite.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: palette.panelBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 4,
                child: CustomPaint(
                  painter: _LegendSwatchPainter(
                    color: config.color,
                    dashed: config.dashed,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                config.label,
                style: TextStyle(
                  fontFamily: VyronTypography.sans,
                  fontSize: 11,
                  color: hidden ? palette.textMuted : palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendSwatchPainter extends CustomPainter {
  const _LegendSwatchPainter({
    required this.color,
    required this.dashed,
  });

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final cy = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
      return;
    }
    canvas.drawLine(Offset(0, cy), Offset(5, cy), paint);
    canvas.drawLine(Offset(8, cy), Offset(size.width, cy), paint);
  }

  @override
  bool shouldRepaint(covariant _LegendSwatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}

class _FloatingChartTooltip extends StatelessWidget {
  const _FloatingChartTooltip({
    required this.point,
    required this.visibleSeries,
    required this.defaultFormatter,
    required this.deltaText,
    required this.language,
  });

  final VyronTimeSeriesPoint point;
  final List<VyronSeriesConfig> visibleSeries;
  final VyronValueFormatter defaultFormatter;
  final String? deltaText;
  final UiLanguage language;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const Key('vyron-chart-tooltip'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? VyronColors.obsidianBlack : VyronColors.lightSurface)
            .withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 6),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.panelBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    point.fullDateLabel ?? point.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: VyronTypography.mono,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                if (point.isProjection || point.isEstimate) ...[
                  const SizedBox(width: 6),
                  Text(
                    translate(
                      language,
                      point.isProjection
                          ? 'charts.projectionBadge'
                          : 'charts.estimateBadge',
                    ),
                    style: TextStyle(
                      fontFamily: VyronTypography.mono,
                      fontSize: 10,
                      color: isDark
                          ? VyronColors.amberDarkText
                          : VyronColors.amberLightText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final s in visibleSeries)
            if (point.values[s.id] != null && point.values[s.id]!.isFinite)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: VyronTypography.sans,
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (s.formatValue ?? defaultFormatter)(point.values[s.id]!),
                      style: TextStyle(
                        fontFamily: VyronTypography.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          if (deltaText != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.panelBorder)),
              ),
              child: Text(
                translate(language, 'charts.deltaFromPrev', {'delta': deltaText}),
                style: TextStyle(
                  fontFamily: VyronTypography.mono,
                  fontSize: 10,
                  color: palette.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartDataTable extends StatelessWidget {
  const _ChartDataTable({
    super.key,
    required this.points,
    required this.visibleSeries,
    required this.selectedPointId,
    required this.formatValue,
    required this.language,
    required this.onSelectPoint,
  });

  final List<VyronTimeSeriesPoint> points;
  final List<VyronSeriesConfig> visibleSeries;
  final String? selectedPointId;
  final VyronValueFormatter formatValue;
  final UiLanguage language;
  final VyronPointSelectedCallback? onSelectPoint;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      key: const Key('vyron-chart-data-table'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.panelBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 42,
          horizontalMargin: 12,
          columnSpacing: 18,
          headingTextStyle: TextStyle(
            fontFamily: VyronTypography.sans,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.textMuted,
          ),
          columns: [
            DataColumn(label: Text(translate(language, 'charts.tableColPeriod'))),
            for (final s in visibleSeries)
              DataColumn(numeric: true, label: Text(s.label)),
          ],
          rows: [
            for (var i = 0; i < points.length; i++)
              DataRow(
                selected: selectedPointId == points[i].id,
                color: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return VyronColors.electricCobalt.withValues(alpha: 0.12);
                  }
                  return null;
                }),
                onSelectChanged: onSelectPoint == null
                    ? null
                    : (_) {
                        final isSel = selectedPointId == points[i].id;
                        onSelectPoint!(
                          isSel ? null : points[i],
                          isSel ? null : i,
                        );
                      },
                cells: [
                  DataCell(
                    Text(
                      '${points[i].fullDateLabel ?? points[i].label}'
                      '${points[i].isProjection ? ' · ${translate(language, 'charts.projectionBadge')}' : ''}',
                      style: TextStyle(
                        fontFamily: VyronTypography.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  for (final s in visibleSeries)
                    DataCell(
                      Text(
                        points[i].values[s.id] != null &&
                                points[i].values[s.id]!.isFinite
                            ? (s.formatValue ?? formatValue)(
                                points[i].values[s.id]!,
                              )
                            : '—',
                        style: TextStyle(
                          fontFamily: VyronTypography.mono,
                          fontSize: 11,
                          color: palette.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
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
}

void _paintYAxisAndGrid(
  Canvas canvas,
  Size size,
  TimeSeriesChartGeometry geometry,
  VyronPaletteExtension palette,
  bool isDark,
  VyronValueFormatter formatYAxis,
) {
  for (final tick in geometry.yTicks) {
    final linePaint = Paint()
      ..color = tick.ratio == 0
          ? (isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.16))
          : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06))
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(geometry.padLeft, tick.y),
      Offset(size.width - geometry.padRight, tick.y),
      linePaint,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: formatYAxis(tick.value),
        style: TextStyle(
          fontFamily: VyronTypography.mono,
          fontSize: 10,
          color: palette.textMuted,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: geometry.padLeft - 8);

    tp.paint(
      canvas,
      Offset(geometry.padLeft - 8 - tp.width, tick.y - tp.height / 2),
    );
  }
}

void _paintXAxisLabels(
  Canvas canvas,
  Size size,
  TimeSeriesChartGeometry geometry,
  int? activeIdx,
  VyronPaletteExtension palette,
) {
  final points = geometry.points;
  final visibleX = geometry.computeVisibleXIndices();
  for (var i = 0; i < points.length; i++) {
    if (!visibleX.contains(i)) continue;
    final cx = geometry.xAt(i);
    final isActive = activeIdx == i;
    final tp = TextPainter(
      text: TextSpan(
        text: points[i].label,
        style: TextStyle(
          fontFamily: VyronTypography.mono,
          fontSize: 10,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive ? palette.textPrimary : palette.textMuted,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    double labelX;
    if (i == 0 && points.length > 2) {
      labelX = cx;
    } else if (i == points.length - 1 && points.length > 2) {
      labelX = cx - tp.width;
    } else {
      labelX = cx - tp.width / 2;
    }
    labelX = labelX.clamp(0.0, math.max(0.0, size.width - tp.width));
    tp.paint(canvas, Offset(labelX, size.height - 16));
  }
}

void _drawDashedPath(
  Canvas canvas,
  Path source,
  Paint paint,
  double dashLength,
  double gapLength,
) {
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = math.min(distance + dashLength, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance += dashLength + gapLength;
    }
  }
}

class _VyronTimeSeriesPainter extends CustomPainter {
  const _VyronTimeSeriesPainter({
    required this.geometry,
    required this.activeIdx,
    required this.selectedIdx,
    required this.palette,
    required this.isDark,
    required this.formatYAxis,
  });

  final TimeSeriesChartGeometry geometry;
  final int? activeIdx;
  final int? selectedIdx;
  final VyronPaletteExtension palette;
  final bool isDark;
  final VyronValueFormatter formatYAxis;

  List<List<Offset>> _extractContiguousRuns(String seriesId) {
    final runs = <List<Offset>>[];
    var current = <Offset>[];
    for (var i = 0; i < geometry.points.length; i++) {
      final v = geometry.points[i].values[seriesId];
      if (v == null || !v.isFinite) {
        if (current.isNotEmpty) {
          runs.add(current);
          current = <Offset>[];
        }
        continue;
      }
      current.add(Offset(geometry.xAt(i), geometry.yAt(v)));
    }
    if (current.isNotEmpty) {
      runs.add(current);
    }
    return runs;
  }

  Path _buildMonotonePath(List<List<Offset>> runs) {
    final path = Path();
    for (final run in runs) {
      if (run.isEmpty) continue;
      path.moveTo(run.first.dx, run.first.dy);
      final segments = computeMonotoneCubicSegments(run);
      for (final seg in segments) {
        path.cubicTo(
          seg.cp1.dx,
          seg.cp1.dy,
          seg.cp2.dx,
          seg.cp2.dy,
          seg.p1.dx,
          seg.p1.dy,
        );
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final points = geometry.points;
    final visibleSeries = geometry.visibleSeries;
    if (points.isEmpty) return;

    _paintYAxisAndGrid(canvas, size, geometry, palette, isDark, formatYAxis);

    // Gradiente de área suavizado sob a série principal (respeitando runs contínuos)
    VyronSeriesConfig? primaryAreaSeries;
    for (final s in visibleSeries) {
      if (s.areaFill) {
        primaryAreaSeries = s;
        break;
      }
    }
    primaryAreaSeries ??= visibleSeries.isNotEmpty ? visibleSeries.first : null;

    if (primaryAreaSeries != null) {
      final areaRuns = _extractContiguousRuns(primaryAreaSeries.id);
      for (final run in areaRuns) {
        if (run.length < 2) continue;
        final areaPath = Path()..moveTo(run.first.dx, run.first.dy);
        for (final seg in computeMonotoneCubicSegments(run)) {
          areaPath.cubicTo(
            seg.cp1.dx,
            seg.cp1.dy,
            seg.cp2.dx,
            seg.cp2.dy,
            seg.p1.dx,
            seg.p1.dy,
          );
        }
        areaPath
          ..lineTo(run.last.dx, geometry.baselineY)
          ..lineTo(run.first.dx, geometry.baselineY)
          ..close();

        final areaPaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = ui.Gradient.linear(
            Offset(0, geometry.padTop),
            Offset(0, geometry.baselineY),
            [
              primaryAreaSeries.color.withValues(alpha: 0.24),
              primaryAreaSeries.color.withValues(alpha: 0.01),
            ],
          );
        canvas.drawPath(areaPath, areaPaint);
      }
    }

    // Curvas suavizadas sem overshoot (nunca interpolando através de null)
    for (final s in visibleSeries) {
      final runs = _extractContiguousRuns(s.id);
      if (runs.isEmpty) continue;
      final path = _buildMonotonePath(runs);

      final strokePaint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.strokeWidth ?? (s.dashed ? 1.85 : 2.35)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (s.dashed) {
        _drawDashedPath(canvas, path, strokePaint, 5.0, 4.0);
      } else {
        canvas.drawPath(path, strokePaint);
      }
    }

    // Crosshair vertical Cobalt no índice ativo
    if (activeIdx != null && activeIdx! < points.length) {
      final cx = geometry.xAt(activeIdx!);
      final crosshairPath = Path()
        ..moveTo(cx, geometry.padTop)
        ..lineTo(cx, geometry.padTop + geometry.innerHeight);
      final crosshairPaint = Paint()
        ..color = VyronColors.electricCobalt.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      _drawDashedPath(canvas, crosshairPath, crosshairPaint, 3.0, 3.0);
    }

    // Marcadores de ponto refinados + eixo X
    for (var i = 0; i < points.length; i++) {
      final cx = geometry.xAt(i);
      final isActive = activeIdx == i;
      final isPinned = selectedIdx == i;

      for (final s in visibleSeries) {
        final v = points[i].values[s.id];
        if (v == null || !v.isFinite) continue;
        final cy = geometry.yAt(v);
        final center = Offset(cx, cy);

        if (isActive || isPinned) {
          canvas.drawCircle(
            center,
            isPinned ? 7.5 : 6.5,
            Paint()..color = s.color.withValues(alpha: 0.2),
          );
        }

        final dotRadius = isActive
            ? 4.4
            : points.length > 16
                ? 2.0
                : 2.8;
        canvas.drawCircle(center, dotRadius, Paint()..color = s.color);
        if (isActive) {
          canvas.drawCircle(
            center,
            dotRadius,
            Paint()
              ..color = isDark ? VyronColors.obsidianBlack : Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }

    _paintXAxisLabels(canvas, size, geometry, activeIdx, palette);
  }

  @override
  bool shouldRepaint(covariant _VyronTimeSeriesPainter oldDelegate) {
    return oldDelegate.activeIdx != activeIdx ||
        oldDelegate.selectedIdx != selectedIdx ||
        oldDelegate.isDark != isDark ||
        oldDelegate.geometry.points != geometry.points ||
        oldDelegate.geometry.visibleSeries != geometry.visibleSeries ||
        oldDelegate.geometry.size != geometry.size;
  }
}

class _VyronTimeSeriesBarPainter extends CustomPainter {
  const _VyronTimeSeriesBarPainter({
    required this.geometry,
    required this.activeIdx,
    required this.selectedIdx,
    required this.palette,
    required this.isDark,
    required this.formatYAxis,
  });

  final TimeSeriesChartGeometry geometry;
  final int? activeIdx;
  final int? selectedIdx;
  final VyronPaletteExtension palette;
  final bool isDark;
  final VyronValueFormatter formatYAxis;

  @override
  void paint(Canvas canvas, Size size) {
    final points = geometry.points;
    final visibleSeries = geometry.visibleSeries;
    if (points.isEmpty || visibleSeries.isEmpty) return;

    _paintYAxisAndGrid(canvas, size, geometry, palette, isDark, formatYAxis);

    final slotWidth = points.length <= 1
        ? math.min(72.0, geometry.innerWidth * 0.45)
        : geometry.innerWidth / points.length;
    final groupWidth = (slotWidth * 0.72).clamp(8.0, 56.0);
    final seriesCount = visibleSeries.length;
    const barGap = 2.0;
    final singleBarWidth = math.max(
      3.0,
      (groupWidth - barGap * (seriesCount - 1)) / seriesCount,
    );

    if (activeIdx != null && activeIdx! < points.length) {
      final cx = geometry.xAt(activeIdx!);
      final highlightRect = Rect.fromLTWH(
        cx - slotWidth * 0.44,
        geometry.padTop,
        slotWidth * 0.88,
        geometry.innerHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(4)),
        Paint()..color = VyronColors.electricCobalt.withValues(alpha: 0.08),
      );
    }

    final baseLine = geometry.baselineY;
    for (var i = 0; i < points.length; i++) {
      final cx = geometry.xAt(i);
      final totalGroupW =
          singleBarWidth * seriesCount + barGap * (seriesCount - 1);
      final startX = cx - totalGroupW / 2.0;
      final isHighlighted = activeIdx == i || selectedIdx == i;

      for (var sIdx = 0; sIdx < seriesCount; sIdx++) {
        final s = visibleSeries[sIdx];
        final v = points[i].values[s.id];
        if (v == null || !v.isFinite) continue;

        final yVal = geometry.yAt(v);
        final top = math.min(yVal, baseLine);
        final height = math.max(2.0, (baseLine - yVal).abs());
        final x = startX + sIdx * (singleBarWidth + barGap);
        final rect = Rect.fromLTWH(x, top, singleBarWidth, height);
        final rrect = RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
          bottomLeft: v < 0 ? const Radius.circular(3) : Radius.zero,
          bottomRight: v < 0 ? const Radius.circular(3) : Radius.zero,
        );

        final opacity = (activeIdx == null || isHighlighted) ? 0.92 : 0.56;
        final paint = Paint()..color = s.color.withValues(alpha: opacity);
        canvas.drawRRect(rrect, paint);

        if (s.dashed || points[i].isProjection) {
          canvas.drawRRect(
            rrect,
            Paint()
              ..color = Colors.white.withValues(alpha: isDark ? 0.28 : 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0,
          );
        }
      }
    }

    _paintXAxisLabels(canvas, size, geometry, activeIdx, palette);
  }

  @override
  bool shouldRepaint(covariant _VyronTimeSeriesBarPainter oldDelegate) {
    return oldDelegate.activeIdx != activeIdx ||
        oldDelegate.selectedIdx != selectedIdx ||
        oldDelegate.isDark != isDark ||
        oldDelegate.geometry.points != geometry.points ||
        oldDelegate.geometry.visibleSeries != geometry.visibleSeries ||
        oldDelegate.geometry.size != geometry.size;
  }
}
