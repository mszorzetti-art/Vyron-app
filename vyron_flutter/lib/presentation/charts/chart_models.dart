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

enum VyronChartDisplayMode {
  line,
  bar,
  table,
}

@immutable
class MonotoneCubicSegment {
  const MonotoneCubicSegment({
    required this.p0,
    required this.cp1,
    required this.cp2,
    required this.p1,
  });

  final Offset p0;
  final Offset cp1;
  final Offset cp2;
  final Offset p1;
}

/// Computes Fritsch-Carlson monotone cubic Hermite segments for ordered points.
/// Passes exactly through every data coordinate and prevents spline overshoot
/// above peaks or below flat segments/zero baselines.
List<MonotoneCubicSegment> computeMonotoneCubicSegments(List<Offset> points) {
  final n = points.length;
  if (n < 2) return const [];
  if (n == 2) {
    final p0 = points[0];
    final p1 = points[1];
    final dx = (p1.dx - p0.dx) / 3.0;
    return [
      MonotoneCubicSegment(
        p0: p0,
        cp1: Offset(p0.dx + dx, p0.dy + (p1.dy - p0.dy) / 3.0),
        cp2: Offset(p1.dx - dx, p1.dy - (p1.dy - p0.dy) / 3.0),
        p1: p1,
      ),
    ];
  }

  final dxs = List<double>.filled(n - 1, 0.0);
  final slopes = List<double>.filled(n - 1, 0.0);
  for (var i = 0; i < n - 1; i++) {
    final dx = points[i + 1].dx - points[i].dx;
    dxs[i] = dx;
    slopes[i] = dx.abs() < 1e-6 ? 0.0 : (points[i + 1].dy - points[i].dy) / dx;
  }

  final tangents = List<double>.filled(n, 0.0);
  tangents[0] = slopes[0];
  tangents[n - 1] = slopes[n - 2];

  for (var i = 1; i < n - 1; i++) {
    final prev = slopes[i - 1];
    final next = slopes[i];
    if (prev == 0.0 || next == 0.0 || (prev > 0) != (next > 0)) {
      tangents[i] = 0.0;
    } else {
      tangents[i] = (prev + next) * 0.5;
    }
  }

  // Enforce monotonicity constraint (alpha^2 + beta^2 <= 9)
  for (var i = 0; i < n - 1; i++) {
    final d = slopes[i];
    if (d.abs() < 1e-9) {
      tangents[i] = 0.0;
      tangents[i + 1] = 0.0;
      continue;
    }
    final alpha = tangents[i] / d;
    final beta = tangents[i + 1] / d;
    final magSq = alpha * alpha + beta * beta;
    if (magSq > 9.0) {
      final tau = 3.0 / math.sqrt(magSq);
      tangents[i] = tau * alpha * d;
      tangents[i + 1] = tau * beta * d;
    }
  }

  final segments = <MonotoneCubicSegment>[];
  for (var i = 0; i < n - 1; i++) {
    final p0 = points[i];
    final p1 = points[i + 1];
    final h = dxs[i] / 3.0;
    segments.add(
      MonotoneCubicSegment(
        p0: p0,
        cp1: Offset(p0.dx + h, p0.dy + tangents[i] * h),
        cp2: Offset(p1.dx - h, p1.dy - tangents[i + 1] * h),
        p1: p1,
      ),
    );
  }
  return segments;
}

