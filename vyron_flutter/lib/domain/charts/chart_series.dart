import 'package:flutter/foundation.dart';
import '../models/brand_product_models.dart';
import '../models/content_channel_finance_models.dart';
import '../models/vyron_enums.dart';
import '../rules/vyron_rules.dart';

enum ChartTimeRange { d7, d30, d90, m12, custom }

extension ChartTimeRangePeriod on PeriodFilter {
  ChartTimeRange get asChartRange => switch (this) {
        PeriodFilter.d7 => ChartTimeRange.d7,
        PeriodFilter.d30 => ChartTimeRange.d30,
        PeriodFilter.d90 => ChartTimeRange.d90,
        PeriodFilter.m12 => ChartTimeRange.m12,
      };
}

enum SeriesAggregationMode { cumulative, daily }

const String demoDataEarliestDate = '2026-10-28';
const String demoReferenceDate = '2026-11-18';

String _shiftIsoDate(String isoDate, int deltaDays) {
  final dt = DateTime.parse('${isoDate}T00:00:00Z');
  final shifted = dt.add(Duration(days: deltaDays));
  return shifted.toIso8601String().substring(0, 10);
}

int _diffDaysInclusive(String startIso, String endIso) {
  final startDt = DateTime.tryParse('${startIso}T00:00:00Z');
  final endDt = DateTime.tryParse('${endIso}T00:00:00Z');
  if (startDt == null || endDt == null || endDt.isBefore(startDt)) return 30;
  final days = endDt.difference(startDt).inDays + 1;
  return days < 1 ? 1 : days;
}

@immutable
class TimeWindowSpec {
  const TimeWindowSpec({
    required this.range,
    required this.startDate,
    required this.endDate,
    required this.prevStartDate,
    required this.prevEndDate,
    required this.days,
    required this.hasSparseCoverage,
  });

  final ChartTimeRange range;
  final String startDate;
  final String endDate;
  final String prevStartDate;
  final String prevEndDate;
  final int days;
  final bool hasSparseCoverage;
}

TimeWindowSpec resolveTimeWindow(
  ChartTimeRange range, {
  String? customStart,
  String? customEnd,
  String referenceDate = demoReferenceDate,
}) {
  if (range == ChartTimeRange.custom &&
      customStart != null &&
      customEnd != null &&
      customStart.isNotEmpty &&
      customEnd.isNotEmpty &&
      customStart.compareTo(customEnd) <= 0) {
    final days = _diffDaysInclusive(customStart, customEnd);
    final prevEndDate = _shiftIsoDate(customStart, -1);
    final prevStartDate = _shiftIsoDate(prevEndDate, -(days - 1));
    return TimeWindowSpec(
      range: range,
      startDate: customStart,
      endDate: customEnd,
      prevStartDate: prevStartDate,
      prevEndDate: prevEndDate,
      days: days,
      hasSparseCoverage: customStart.compareTo(demoDataEarliestDate) < 0 ||
          prevStartDate.compareTo(demoDataEarliestDate) < 0,
    );
  }

  final days = switch (range) {
    ChartTimeRange.d7 => 7,
    ChartTimeRange.d90 => 90,
    ChartTimeRange.m12 => 365,
    ChartTimeRange.d30 || ChartTimeRange.custom => 30,
  };
  final startDate = _shiftIsoDate(referenceDate, -(days - 1));
  final endDate = referenceDate;
  final prevEndDate = _shiftIsoDate(startDate, -1);
  final prevStartDate = _shiftIsoDate(prevEndDate, -(days - 1));

  return TimeWindowSpec(
    range: range == ChartTimeRange.custom ? ChartTimeRange.d30 : range,
    startDate: startDate,
    endDate: endDate,
    prevStartDate: prevStartDate,
    prevEndDate: prevEndDate,
    days: days,
    hasSparseCoverage: startDate.compareTo(demoDataEarliestDate) < 0 ||
        prevStartDate.compareTo(demoDataEarliestDate) < 0,
  );
}

@immutable
class OverviewFinancePoint {
  const OverviewFinancePoint({
    required this.id,
    required this.date,
    required this.isProjection,
    required this.confirmedCommercial,
    required this.receivedCash,
    required this.pendingCommissions,
    required this.projection,
    required this.previousConfirmed,
    required this.dailyConfirmedDelta,
    required this.dailyReceivedDelta,
    required this.dailyPendingDelta,
    required this.dailyOutflowDelta,
    required this.entryIds,
    required this.brandIds,
    required this.productIds,
  });

  final String id;
  final String date;
  final bool isProjection;
  final double? confirmedCommercial;
  final double? receivedCash;
  final double? pendingCommissions;
  final double? projection;
  final double? previousConfirmed;
  final double dailyConfirmedDelta;
  final double dailyReceivedDelta;
  final double dailyPendingDelta;
  final double dailyOutflowDelta;
  final List<String> entryIds;
  final List<String> brandIds;
  final List<String> productIds;

  OverviewFinancePoint copyWith({double? projection}) => OverviewFinancePoint(
        id: id,
        date: date,
        isProjection: isProjection,
        confirmedCommercial: confirmedCommercial,
        receivedCash: receivedCash,
        pendingCommissions: pendingCommissions,
        projection: projection ?? this.projection,
        previousConfirmed: previousConfirmed,
        dailyConfirmedDelta: dailyConfirmedDelta,
        dailyReceivedDelta: dailyReceivedDelta,
        dailyPendingDelta: dailyPendingDelta,
        dailyOutflowDelta: dailyOutflowDelta,
        entryIds: entryIds,
        brandIds: brandIds,
        productIds: productIds,
      );
}

class OverviewFinanceSeriesResult {
  const OverviewFinanceSeriesResult({
    required this.window,
    required this.points,
    required this.previousWindowEntriesCount,
    required this.currentWindowEntriesCount,
    required this.hasPreviousData,
  });

  final TimeWindowSpec window;
  final List<OverviewFinancePoint> points;
  final int previousWindowEntriesCount;
  final int currentWindowEntriesCount;
  final bool hasPreviousData;
}

OverviewFinanceSeriesResult buildOverviewFinanceSeries(
  List<FinanceEntry> entries,
  CurrencyCode currency, {
  String? brandId,
  required ChartTimeRange range,
  String? customStart,
  String? customEnd,
  bool excludeTest = true,
  bool includeProjection = true,
  SeriesAggregationMode mode = SeriesAggregationMode.cumulative,
  String referenceDate = demoReferenceDate,
}) {
  final window = resolveTimeWindow(
    range,
    customStart: customStart,
    customEnd: customEnd,
    referenceDate: referenceDate,
  );

  final scoped = entries.where((e) {
    if (excludeTest && e.isTest) return false;
    if (brandId != null && brandId != 'all' && e.brandId != brandId) {
      return false;
    }
    return true;
  }).toList();

  final currentReal = scoped
      .where(
        (e) =>
            !e.isProjection &&
            e.date.compareTo(window.startDate) >= 0 &&
            e.date.compareTo(window.endDate) <= 0,
      )
      .toList();
  final previousReal = scoped
      .where(
        (e) =>
            !e.isProjection &&
            e.date.compareTo(window.prevStartDate) >= 0 &&
            e.date.compareTo(window.prevEndDate) <= 0,
      )
      .toList();
  final projections = scoped.where((e) => e.isProjection).toList();

  final prevByDate = <String, List<FinanceEntry>>{};
  for (final e in previousReal) {
    prevByDate.putIfAbsent(e.date, () => []).add(e);
  }
  final prevSortedDates = prevByDate.keys.toList()..sort();
  var prevRunningConfirmed = 0.0;
  final prevCheckpoints = <double>[];
  for (final d in prevSortedDates) {
    final dayConfirmed = (prevByDate[d] ?? const <FinanceEntry>[])
        .where(
          (e) =>
              (e.type == FinanceEntryType.commission ||
                  e.type == FinanceEntryType.directRevenue) &&
              (e.stage == CommissionStage.confirmed ||
                  e.stage == CommissionStage.received),
        )
        .fold<double>(
          0.0,
          (acc, e) => acc + convertCurrency(e.amount, e.currency, currency),
        );
    prevRunningConfirmed += dayConfirmed;
    prevCheckpoints.add(
      mode == SeriesAggregationMode.cumulative
          ? prevRunningConfirmed
          : dayConfirmed,
    );
  }

  final byDate = <String, List<FinanceEntry>>{};
  for (final e in currentReal) {
    byDate.putIfAbsent(e.date, () => []).add(e);
  }
  final sortedDates = byDate.keys.toList()..sort();

  var runConfirmed = 0.0;
  var runReceived = 0.0;
  var runPending = 0.0;

  final points = <OverviewFinancePoint>[];
  for (var idx = 0; idx < sortedDates.length; idx++) {
    final date = sortedDates[idx];
    final dayEntries = byDate[date] ?? const <FinanceEntry>[];
    var dayConf = 0.0;
    var dayRec = 0.0;
    var dayPend = 0.0;
    var dayOut = 0.0;
    final brandSet = <String>{};
    final prodSet = <String>{};

    for (final e in dayEntries) {
      final val = convertCurrency(e.amount, e.currency, currency);
      brandSet.add(e.brandId);
      if (e.productId != null && e.productId!.isNotEmpty) {
        prodSet.add(e.productId!);
      }

      if (e.type == FinanceEntryType.commission ||
          e.type == FinanceEntryType.directRevenue) {
        if (e.stage == CommissionStage.pending) {
          dayPend += val;
        } else if (e.stage == CommissionStage.confirmed) {
          dayConf += val;
        } else if (e.stage == CommissionStage.received) {
          dayConf += val;
          dayRec += val;
        }
      } else if (e.type == FinanceEntryType.expense ||
          e.type == FinanceEntryType.reinvestment) {
        dayOut += val;
      }
    }

    runConfirmed += dayConf;
    runReceived += dayRec;
    runPending += dayPend;

    final prevValue = previousReal.isEmpty
        ? null
        : idx < prevCheckpoints.length
            ? prevCheckpoints[idx]
            : (prevCheckpoints.isNotEmpty ? prevCheckpoints.last : 0.0);

    points.add(
      OverviewFinancePoint(
        id: 'pt-$date',
        date: date,
        isProjection: false,
        confirmedCommercial:
            mode == SeriesAggregationMode.cumulative ? runConfirmed : dayConf,
        receivedCash:
            mode == SeriesAggregationMode.cumulative ? runReceived : dayRec,
        pendingCommissions:
            mode == SeriesAggregationMode.cumulative ? runPending : dayPend,
        projection: null,
        previousConfirmed: prevValue,
        dailyConfirmedDelta: dayConf,
        dailyReceivedDelta: dayRec,
        dailyPendingDelta: dayPend,
        dailyOutflowDelta: dayOut,
        entryIds: dayEntries.map((e) => e.id).toList(),
        brandIds: brandSet.toList(),
        productIds: prodSet.toList(),
      ),
    );
  }

  if (includeProjection && projections.isNotEmpty && points.isNotEmpty) {
    final projectedSum = projections.fold<double>(
      0.0,
      (acc, e) => acc + convertCurrency(e.amount, e.currency, currency),
    );
    final lastReal = points.last;
    points[points.length - 1] =
        lastReal.copyWith(projection: lastReal.confirmedCommercial);

    final projDates = projections.map((p) => p.date).toList()..sort();
    final projDate =
        projDates.isNotEmpty ? projDates.last : '2026-12-15';
    points.add(
      OverviewFinancePoint(
        id: 'pt-proj-$projDate',
        date: projDate,
        isProjection: true,
        confirmedCommercial: null,
        receivedCash: null,
        pendingCommissions: null,
        projection: (lastReal.confirmedCommercial ?? 0.0) + projectedSum,
        previousConfirmed: null,
        dailyConfirmedDelta: 0,
        dailyReceivedDelta: 0,
        dailyPendingDelta: 0,
        dailyOutflowDelta: projectedSum,
        entryIds: projections.map((p) => p.id).toList(),
        brandIds: projections.map((p) => p.brandId).toSet().toList(),
        productIds: projections
            .map((p) => p.productId)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList(),
      ),
    );
  }

  return OverviewFinanceSeriesResult(
    window: window,
    points: points,
    previousWindowEntriesCount: previousReal.length,
    currentWindowEntriesCount: currentReal.length,
    hasPreviousData: previousReal.isNotEmpty,
  );
}

@immutable
class FinanceCashflowPoint {
  const FinanceCashflowPoint({
    required this.id,
    required this.date,
    required this.isProjection,
    required this.receivedInflow,
    required this.confirmedCommercial,
    required this.pendingCommissions,
    required this.outflows,
    required this.projection,
    required this.previousReceived,
    required this.entryIds,
  });

  final String id;
  final String date;
  final bool isProjection;
  final double? receivedInflow;
  final double? confirmedCommercial;
  final double? pendingCommissions;
  final double? outflows;
  final double? projection;
  final double? previousReceived;
  final List<String> entryIds;

  FinanceCashflowPoint copyWith({double? projection}) => FinanceCashflowPoint(
        id: id,
        date: date,
        isProjection: isProjection,
        receivedInflow: receivedInflow,
        confirmedCommercial: confirmedCommercial,
        pendingCommissions: pendingCommissions,
        outflows: outflows,
        projection: projection ?? this.projection,
        previousReceived: previousReceived,
        entryIds: entryIds,
      );
}

class FinanceCashflowSeriesResult {
  const FinanceCashflowSeriesResult({
    required this.window,
    required this.points,
    required this.hasPreviousData,
  });

  final TimeWindowSpec window;
  final List<FinanceCashflowPoint> points;
  final bool hasPreviousData;
}

FinanceCashflowSeriesResult buildFinanceCashflowSeries(
  List<FinanceEntry> entries,
  CurrencyCode currency, {
  String? brandId,
  required ChartTimeRange range,
  String? customStart,
  String? customEnd,
  bool excludeTest = true,
  bool includeProjections = true,
  SeriesAggregationMode mode = SeriesAggregationMode.daily,
  String referenceDate = demoReferenceDate,
}) {
  final window = resolveTimeWindow(
    range,
    customStart: customStart,
    customEnd: customEnd,
    referenceDate: referenceDate,
  );

  final scoped = entries.where((e) {
    if (excludeTest && e.isTest) return false;
    if (brandId != null && brandId != 'all' && e.brandId != brandId) {
      return false;
    }
    return true;
  }).toList();

  final currentReal = scoped
      .where(
        (e) =>
            !e.isProjection &&
            e.date.compareTo(window.startDate) >= 0 &&
            e.date.compareTo(window.endDate) <= 0,
      )
      .toList();
  final previousReal = scoped
      .where(
        (e) =>
            !e.isProjection &&
            e.date.compareTo(window.prevStartDate) >= 0 &&
            e.date.compareTo(window.prevEndDate) <= 0,
      )
      .toList();
  final projections = includeProjections
      ? scoped.where((e) => e.isProjection).toList()
      : const <FinanceEntry>[];

  final byDate = <String, List<FinanceEntry>>{};
  for (final e in currentReal) {
    byDate.putIfAbsent(e.date, () => []).add(e);
  }
  final sortedDates = byDate.keys.toList()..sort();

  final prevByDate = <String, List<FinanceEntry>>{};
  for (final e in previousReal) {
    prevByDate.putIfAbsent(e.date, () => []).add(e);
  }
  final prevSorted = prevByDate.keys.toList()..sort();
  var prevRunRec = 0.0;
  final prevCheckpoints = prevSorted.map((d) {
    final dayRec = (prevByDate[d] ?? const <FinanceEntry>[])
        .where(
          (e) =>
              (e.type == FinanceEntryType.commission ||
                  e.type == FinanceEntryType.directRevenue) &&
              e.stage == CommissionStage.received,
        )
        .fold<double>(
          0.0,
          (acc, e) => acc + convertCurrency(e.amount, e.currency, currency),
        );
    prevRunRec += dayRec;
    return mode == SeriesAggregationMode.cumulative ? prevRunRec : dayRec;
  }).toList();

  var runRec = 0.0;
  var runConf = 0.0;
  var runPend = 0.0;
  var runOut = 0.0;

  final points = <FinanceCashflowPoint>[];
  for (var idx = 0; idx < sortedDates.length; idx++) {
    final date = sortedDates[idx];
    final dayEntries = byDate[date] ?? const <FinanceEntry>[];
    var dayRec = 0.0;
    var dayConf = 0.0;
    var dayPend = 0.0;
    var dayOut = 0.0;

    for (final e in dayEntries) {
      final val = convertCurrency(e.amount, e.currency, currency);
      if (e.type == FinanceEntryType.commission ||
          e.type == FinanceEntryType.directRevenue) {
        if (e.stage == CommissionStage.received) {
          dayRec += val;
          dayConf += val;
        } else if (e.stage == CommissionStage.confirmed) {
          dayConf += val;
        } else {
          dayPend += val;
        }
      } else {
        dayOut += val;
      }
    }

    runRec += dayRec;
    runConf += dayConf;
    runPend += dayPend;
    runOut += dayOut;

    points.add(
      FinanceCashflowPoint(
        id: 'fin-pt-$date',
        date: date,
        isProjection: false,
        receivedInflow:
            mode == SeriesAggregationMode.cumulative ? runRec : dayRec,
        confirmedCommercial:
            mode == SeriesAggregationMode.cumulative ? runConf : dayConf,
        pendingCommissions:
            mode == SeriesAggregationMode.cumulative ? runPend : dayPend,
        outflows:
            mode == SeriesAggregationMode.cumulative ? runOut : dayOut,
        projection: null,
        previousReceived: previousReal.isEmpty
            ? null
            : idx < prevCheckpoints.length
                ? prevCheckpoints[idx]
                : (prevCheckpoints.isNotEmpty ? prevCheckpoints.last : 0.0),
        entryIds: dayEntries.map((e) => e.id).toList(),
      ),
    );
  }

  if (projections.isNotEmpty && points.isNotEmpty) {
    final projAmount = projections.fold<double>(
      0.0,
      (acc, e) => acc + convertCurrency(e.amount, e.currency, currency),
    );
    final last = points.last;
    points[points.length - 1] = last.copyWith(
      projection: mode == SeriesAggregationMode.cumulative
          ? last.confirmedCommercial
          : projAmount,
    );
    final projDates = projections.map((p) => p.date).toList()..sort();
    final projDate =
        projDates.isNotEmpty ? projDates.last : '2026-12-15';
    points.add(
      FinanceCashflowPoint(
        id: 'fin-pt-proj-$projDate',
        date: projDate,
        isProjection: true,
        receivedInflow: null,
        confirmedCommercial: null,
        pendingCommissions: null,
        outflows: null,
        projection: mode == SeriesAggregationMode.cumulative
            ? (last.confirmedCommercial ?? 0.0) + projAmount
            : projAmount,
        previousReceived: null,
        entryIds: projections.map((p) => p.id).toList(),
      ),
    );
  }

  return FinanceCashflowSeriesResult(
    window: window,
    points: points,
    hasPreviousData: previousReal.isNotEmpty,
  );
}

enum AnalyticsMetricKey { views, clicks, conversions, ctr, epc, revenue }

@immutable
class AnalyticsContentPoint {
  const AnalyticsContentPoint({
    required this.id,
    required this.date,
    required this.contentId,
    required this.brandId,
    required this.channelId,
    required this.title,
    required this.views,
    required this.clicks,
    required this.conversions,
    required this.ctrPct,
    required this.epc,
    required this.revenue,
    required this.retention30sPct,
    required this.trackingSrc,
    required this.attributionStatus,
    required this.isEstimate,
  });

  final String id;
  final String date;
  final String contentId;
  final String brandId;
  final String channelId;
  final String title;
  final int views;
  final int clicks;
  final int conversions;
  final double ctrPct;
  final double epc;
  final double revenue;
  final double retention30sPct;
  final String trackingSrc;
  final AttributionStatus attributionStatus;
  final bool isEstimate;
}

class AnalyticsContentSeriesResult {
  const AnalyticsContentSeriesResult({
    required this.window,
    required this.items,
    required this.previousCount,
  });

  final TimeWindowSpec window;
  final List<AnalyticsContentPoint> items;
  final int previousCount;
}

AnalyticsContentSeriesResult buildAnalyticsContentPoints(
  List<ContentItem> contents,
  CurrencyCode currency, {
  String? brandId,
  String? channelId,
  ContentCategory? category,
  required ChartTimeRange range,
  String? customStart,
  String? customEnd,
  String referenceDate = demoReferenceDate,
}) {
  final window = resolveTimeWindow(
    range,
    customStart: customStart,
    customEnd: customEnd,
    referenceDate: referenceDate,
  );

  final withMetrics = contents.where((c) {
    if (c.metrics == null) return false;
    if (brandId != null && brandId != 'all' && c.brandId != brandId) {
      return false;
    }
    if (channelId != null && channelId != 'all' && c.channelId != channelId) {
      return false;
    }
    if (category != null && c.category != category) return false;
    return true;
  }).toList();

  final inWindow = withMetrics.where((c) {
    final d = c.publishedAt ?? c.scheduledDate;
    return d.compareTo(window.startDate) >= 0 &&
        d.compareTo(window.endDate) <= 0;
  }).toList()
    ..sort((a, b) {
      final da = a.publishedAt ?? a.scheduledDate;
      final db = b.publishedAt ?? b.scheduledDate;
      return da.compareTo(db);
    });

  final previousCount = withMetrics.where((c) {
    final d = c.publishedAt ?? c.scheduledDate;
    return d.compareTo(window.prevStartDate) >= 0 &&
        d.compareTo(window.prevEndDate) <= 0;
  }).length;

  final items = inWindow.map((c) {
    final m = c.metrics!;
    final rev = convertCurrency(m.revenueGenerated, m.currency, currency);
    final ctrPct = m.views > 0 ? (m.clicks / m.views) * 100.0 : 0.0;
    final epc = m.clicks > 0 ? rev / m.clicks : 0.0;
    return AnalyticsContentPoint(
      id: 'an-${c.id}',
      date: c.publishedAt ?? c.scheduledDate,
      contentId: c.id,
      brandId: c.brandId,
      channelId: c.channelId,
      title: c.title,
      views: m.views,
      clicks: m.clicks,
      conversions: m.conversions,
      ctrPct: ctrPct,
      epc: epc,
      revenue: rev,
      retention30sPct: m.retention30sPct,
      trackingSrc: m.trackingSrc,
      attributionStatus: m.attributionStatus,
      isEstimate: m.attributionStatus != AttributionStatus.confirmadaMarca,
    );
  }).toList();

  return AnalyticsContentSeriesResult(
    window: window,
    items: items,
    previousCount: previousCount,
  );
}

enum ChannelChartMetric {
  views30d,
  reach30d,
  followers,
  engagementRatePct,
  growthPct30d,
}

class ChannelComparisonItem {
  const ChannelComparisonItem({
    required this.channel,
    required this.brandName,
    required this.rawValue,
    required this.accentColor,
  });

  final Channel channel;
  final String brandName;
  final double rawValue;
  final String accentColor;
}

List<ChannelComparisonItem> buildChannelComparisonItems(
  List<Channel> channels,
  List<Brand> brands, {
  String? brandId,
  ChannelPlatform? platform,
  required ChannelChartMetric metric,
}) {
  return channels.where((ch) {
    if (brandId != null && brandId != 'all' && ch.brandId != brandId) {
      return false;
    }
    if (platform != null && ch.platform != platform) return false;
    return true;
  }).map((ch) {
    Brand? brand;
    for (final b in brands) {
      if (b.id == ch.brandId) {
        brand = b;
        break;
      }
    }
    final rawValue = switch (metric) {
      ChannelChartMetric.views30d => ch.views30d.toDouble(),
      ChannelChartMetric.reach30d => ch.reach30d.toDouble(),
      ChannelChartMetric.followers => ch.followers.toDouble(),
      ChannelChartMetric.engagementRatePct => ch.engagementRatePct,
      ChannelChartMetric.growthPct30d => ch.growthPct30d,
    };
    return ChannelComparisonItem(
      channel: ch,
      brandName: brand?.name ?? ch.brandId,
      rawValue: rawValue,
      accentColor: brand?.accentColor ?? '#315FEA',
    );
  }).toList()
    ..sort((a, b) => b.rawValue.compareTo(a.rawValue));
}

enum ProductChartMetric {
  opportunityScore,
  epcValue,
  commissionRatePct,
  demandTrendPct,
}

class ProductCurrencyChartItem {
  const ProductCurrencyChartItem({
    required this.product,
    required this.value,
    required this.missingData,
  });

  final Product product;
  final double? value;
  final bool missingData;
}

/// Strictly compares products WITHIN a single native currency.
/// Preserves null strictly — NEVER coerces missing fields to 0.
List<ProductCurrencyChartItem> buildProductNativeCurrencyComparison(
  List<Product> products,
  CurrencyCode nativeCurrency,
  ProductChartMetric metric, {
  bool excludeTest = true,
  String? brandId,
}) {
  final scoped = products.where((p) {
    if (excludeTest && p.isTest) return false;
    if (p.currency != nativeCurrency) return false;
    if (brandId != null &&
        brandId != 'all' &&
        p.brandId != brandId &&
        !p.linkedBrandIds.contains(brandId)) {
      return false;
    }
    return true;
  });

  final mapped = scoped.map((p) {
    final val = switch (metric) {
      ProductChartMetric.opportunityScore => p.opportunityScore?.toDouble(),
      ProductChartMetric.epcValue => p.epcValue,
      ProductChartMetric.commissionRatePct => p.commissionRatePct,
      ProductChartMetric.demandTrendPct => p.demandTrendPct,
    };
    return ProductCurrencyChartItem(
      product: p,
      value: val,
      missingData: val == null,
    );
  }).toList()
    ..sort((a, b) {
      if (a.value == null && b.value == null) return 0;
      if (a.value == null) return 1;
      if (b.value == null) return -1;
      return b.value!.compareTo(a.value!);
    });

  return mapped;
}
