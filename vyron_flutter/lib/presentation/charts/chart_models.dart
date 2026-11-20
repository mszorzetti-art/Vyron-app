import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/i18n/formatters.dart';
import '../../domain/models/vyron_enums.dart';

typedef VyronValueFormatter = String Function(double value);

@immutable
class VyronSeriesConfig {
  const VyronSeriesConfig({
    required this.id,
    required this.label,
    required this.color,
    this.dashed = false,
    this.areaFill = false,
    this.strokeWidth,
    this.defaultHidden = false,
    this.isEstimate = false,
    this.isProjection = false,
    this.formatValue,
  });

  final String id;
  final String label;
  final Color color;
  final bool dashed;
  final bool areaFill;
  final double? strokeWidth;
  final bool defaultHidden;
  final bool isEstimate;
  final bool isProjection;
  final VyronValueFormatter? formatValue;
}

@immutable
class VyronTimeSeriesPoint {
  const VyronTimeSeriesPoint({
    required this.id,
    required this.label,
    this.fullDateLabel,
    this.isProjection = false,
    this.isEstimate = false,
    required this.values,
  });

  final String id;
  final String label;
  final String? fullDateLabel;
  final bool isProjection;
  final bool isEstimate;
  final Map<String, double?> values;
}

@immutable
class VyronComparisonBarItem {
  const VyronComparisonBarItem({
    required this.id,
    required this.label,
    this.sublabel,
    required this.value,
    required this.formattedValue,
    this.color,
    this.badge,
    this.isMissing = false,
  });

  final String id;
  final String label;
  final String? sublabel;
  final double? value;
  final String formattedValue;
  final Color? color;
  final String? badge;
  final bool isMissing;
}

@immutable
class ChartYTick {
  const ChartYTick({
    required this.ratio,
    required this.value,
    required this.y,
  });

  final double ratio;
  final double value;
  final double y;
}

/// Pure geometric solver shared between CustomPainter and touch hit-testing
/// so crosshair snapping, axis bounds, and label collision checks stay 100% deterministic.
class TimeSeriesChartGeometry {
  TimeSeriesChartGeometry({
    required this.size,
    required this.points,
    required this.visibleSeries,
    this.padLeft = 64.0,
    this.padRight = 18.0,
    this.padTop = 18.0,
    this.padBottom = 28.0,
  })  : innerWidth = math.max(1.0, size.width - padLeft - padRight),
        innerHeight = math.max(1.0, size.height - padTop - padBottom) {
    final allValues = <double>[];
    for (final pt in points) {
      for (final s in visibleSeries) {
        final v = pt.values[s.id];
        if (v != null && v.isFinite) {
          allValues.add(v);
        }
      }
    }

    final rawMin = allValues.isEmpty ? 0.0 : math.min(0.0, allValues.reduce(math.min));
    final rawMax = allValues.isEmpty
        ? 100.0
        : math.max(1.0, allValues.reduce(math.max));
    final span = math.max(rawMax - rawMin, 1.0);
    yMin = rawMin < 0 ? rawMin - span * 0.08 : 0.0;
    yMax = rawMax + span * 0.12;
    yRange = math.max(yMax - yMin, 1.0);
  }

  final Size size;
  final List<VyronTimeSeriesPoint> points;
  final List<VyronSeriesConfig> visibleSeries;
  final double padLeft;
  final double padRight;
  final double padTop;
  final double padBottom;
  final double innerWidth;
  final double innerHeight;

  late final double yMin;
  late final double yMax;
  late final double yRange;

  double xAt(int index) {
    if (points.length <= 1) {
      return padLeft + innerWidth / 2.0;
    }
    return padLeft + (index / (points.length - 1)) * innerWidth;
  }

  double yAt(double value) {
    return padTop + innerHeight - ((value - yMin) / yRange) * innerHeight;
  }

  double get baselineY => yAt(math.max(yMin, 0.0));

  List<ChartYTick> get yTicks {
    const ratios = [0.0, 0.25, 0.5, 0.75, 1.0];
    return [
      for (final r in ratios)
        ChartYTick(
          ratio: r,
          value: yMin + yRange * r,
          y: yAt(yMin + yRange * r),
        ),
    ];
  }

  /// Mirrors SVG findNearestIndex from Charts.tsx: clamps localX into plot bounds
  /// and snaps to the nearest data point index.
  int? findNearestIndex(double localX) {
    if (points.isEmpty) return null;
    if (points.length == 1) return 0;
    final clampedX = localX.clamp(padLeft, padLeft + innerWidth);
    final ratio = (clampedX - padLeft) / innerWidth;
    final raw = (ratio * (points.length - 1)).round();
    return raw.clamp(0, points.length - 1);
  }

  /// Width-aware X-axis label placement so adjacent or projection labels never collide.
  Set<int> computeVisibleXIndices() {
    final chosen = <int>{};
    if (points.isEmpty) return chosen;
    if (points.length == 1) {
      chosen.add(0);
      return chosen;
    }

    double estWidth(String text) => math.max(28.0, text.length * 6.4);

    final lastIdx = points.length - 1;
    final firstRightEdge = xAt(0) + estWidth(points[0].label);
    final lastLeftEdge = xAt(lastIdx) - estWidth(points[lastIdx].label);

    chosen.add(0);
    if (lastLeftEdge > firstRightEdge + 12.0) {
      chosen.add(lastIdx);
    }

    var prevRightEdge = firstRightEdge;
    for (var i = 1; i < lastIdx; i++) {
      final halfW = estWidth(points[i].label) / 2.0;
      final cx = xAt(i);
      final leftEdge = cx - halfW;
      final rightEdge = cx + halfW;
      if (leftEdge >= prevRightEdge + 16.0 &&
          rightEdge + 16.0 <= lastLeftEdge) {
        chosen.add(i);
        prevRightEdge = rightEdge;
      }
    }
    return chosen;
  }
}

/// Computes delta text relative to previous point for the active primary series.
String? computePointDeltaText({
  required List<VyronTimeSeriesPoint> points,
  required List<VyronSeriesConfig> visibleSeries,
  required int? activeIdx,
  required VyronValueFormatter defaultFormatter,
  required UiLanguage language,
}) {
  if (activeIdx == null ||
      activeIdx <= 0 ||
      activeIdx >= points.length ||
      visibleSeries.isEmpty) {
    return null;
  }

  final activePoint = points[activeIdx];
  VyronSeriesConfig? primarySeries;
  for (final s in visibleSeries) {
    final val = activePoint.values[s.id];
    if (val != null && val.isFinite) {
      primarySeries = s;
      break;
    }
  }
  primarySeries ??= visibleSeries.first;

  final currVal = activePoint.values[primarySeries.id];
  final prevVal = points[activeIdx - 1].values[primarySeries.id];
  if (currVal == null ||
      prevVal == null ||
      !currVal.isFinite ||
      !prevVal.isFinite) {
    return null;
  }

  final diff = currVal - prevVal;
  final pctStr = prevVal != 0
      ? ' (${diff >= 0 ? '+' : ''}${formatNumberForLang((diff / prevVal.abs()) * 100.0, language, 1)}%)'
      : '';
  final fmt = primarySeries.formatValue ?? defaultFormatter;
  final sign = diff > 0 ? '+' : (diff < 0 ? '-' : '');
  return '$sign${fmt(diff.abs())}$pctStr';
}
