import {
  Brand,
  Channel,
  ContentCategory,
  ContentItem,
  CurrencyCode,
  FinanceEntry,
  PeriodFilter,
  Product,
} from '../types/vyron';
import { convertCurrency } from './vyronRules';

export type ChartTimeRange = PeriodFilter | 'custom';

export interface TimeWindowSpec {
  range: ChartTimeRange;
  startDate: string;
  endDate: string;
  prevStartDate: string;
  prevEndDate: string;
  days: number;
  hasSparseCoverage: boolean;
}

export const DEMO_DATA_EARLIEST_DATE = '2026-10-28';
export const DEMO_REFERENCE_DATE = '2026-11-18';

function shiftIsoDate(isoDate: string, deltaDays: number): string {
  const dt = new Date(`${isoDate}T00:00:00Z`);
  dt.setUTCDate(dt.getUTCDate() + deltaDays);
  return dt.toISOString().slice(0, 10);
}

function diffDaysInclusive(startIso: string, endIso: string): number {
  const startMs = Date.parse(`${startIso}T00:00:00Z`);
  const endMs = Date.parse(`${endIso}T00:00:00Z`);
  if (!Number.isFinite(startMs) || !Number.isFinite(endMs) || endMs < startMs) return 30;
  return Math.max(1, Math.round((endMs - startMs) / (24 * 60 * 60 * 1000)) + 1);
}

export function resolveTimeWindow(
  range: ChartTimeRange,
  customStart?: string,
  customEnd?: string,
  referenceDate = DEMO_REFERENCE_DATE
): TimeWindowSpec {
  if (range === 'custom' && customStart && customEnd && customStart <= customEnd) {
    const days = diffDaysInclusive(customStart, customEnd);
    const prevEndDate = shiftIsoDate(customStart, -1);
    const prevStartDate = shiftIsoDate(prevEndDate, -(days - 1));
    return {
      range,
      startDate: customStart,
      endDate: customEnd,
      prevStartDate,
      prevEndDate,
      days,
      hasSparseCoverage: customStart < DEMO_DATA_EARLIEST_DATE || prevStartDate < DEMO_DATA_EARLIEST_DATE,
    };
  }

  const days = range === '7d' ? 7 : range === '90d' ? 90 : range === '12m' ? 365 : 30;
  const startDate = shiftIsoDate(referenceDate, -(days - 1));
  const endDate = referenceDate;
  const prevEndDate = shiftIsoDate(startDate, -1);
  const prevStartDate = shiftIsoDate(prevEndDate, -(days - 1));

  return {
    range: range === 'custom' ? '30d' : range,
    startDate,
    endDate,
    prevStartDate,
    prevEndDate,
    days,
    hasSparseCoverage: startDate < DEMO_DATA_EARLIEST_DATE || prevStartDate < DEMO_DATA_EARLIEST_DATE,
  };
}

export interface OverviewFinancePoint {
  id: string;
  date: string;
  isProjection: boolean;
  confirmedCommercial: number | null;
  receivedCash: number | null;
  pendingCommissions: number | null;
  projection: number | null;
  previousConfirmed: number | null;
  dailyConfirmedDelta: number;
  dailyReceivedDelta: number;
  dailyPendingDelta: number;
  dailyOutflowDelta: number;
  entryIds: string[];
  brandIds: string[];
  productIds: string[];
}

export interface OverviewFinanceSeriesResult {
  window: TimeWindowSpec;
  points: OverviewFinancePoint[];
  previousWindowEntriesCount: number;
  currentWindowEntriesCount: number;
  hasPreviousData: boolean;
}

/**
 * Builds chronological financial series strictly from `financeEntries`:
 * - Pending commissions are ALWAYS kept in their own separate field (`pendingCommissions`)
 *   and NEVER merged into `confirmedCommercial` or `receivedCash`.
 * - Test records (`isTest`) are excluded when `excludeTest !== false`.
 * - Future projections (`isProjection`) sit strictly on an isolated projection point.
 * - Never invents synthetic transactions for empty days or missing prior periods.
 */
export function buildOverviewFinanceSeries(
  entries: FinanceEntry[],
  currency: CurrencyCode,
  options: {
    brandId?: string;
    range: ChartTimeRange;
    customStart?: string;
    customEnd?: string;
    excludeTest?: boolean;
    includeProjection?: boolean;
    mode?: 'cumulative' | 'daily';
    referenceDate?: string;
  }
): OverviewFinanceSeriesResult {
  const excludeTest = options.excludeTest ?? true;
  const includeProjection = options.includeProjection ?? true;
  const mode = options.mode ?? 'cumulative';
  const window = resolveTimeWindow(
    options.range,
    options.customStart,
    options.customEnd,
    options.referenceDate
  );

  const scoped = entries.filter((e) => {
    if (excludeTest && e.isTest) return false;
    if (options.brandId && options.brandId !== 'all' && e.brandId !== options.brandId) return false;
    return true;
  });

  const currentReal = scoped.filter(
    (e) => !e.isProjection && e.date >= window.startDate && e.date <= window.endDate
  );
  const previousReal = scoped.filter(
    (e) => !e.isProjection && e.date >= window.prevStartDate && e.date <= window.prevEndDate
  );
  const projections = scoped.filter((e) => Boolean(e.isProjection));

  // Compute previous window total & chronological checkpoints (strictly from real prior entries)
  const prevByDate = new Map<string, FinanceEntry[]>();
  for (const e of previousReal) {
    const arr = prevByDate.get(e.date) ?? [];
    arr.push(e);
    prevByDate.set(e.date, arr);
  }
  const prevSortedDates = Array.from(prevByDate.keys()).sort();
  let prevRunningConfirmed = 0;
  const prevCheckpoints: number[] = [];
  for (const d of prevSortedDates) {
    const dayConfirmed = (prevByDate.get(d) ?? [])
      .filter(
        (e) =>
          (e.type === 'Commission' || e.type === 'DirectRevenue') &&
          (e.stage === 'Confirmed' || e.stage === 'Received')
      )
      .reduce((acc, e) => acc + convertCurrency(e.amount, e.currency, currency), 0);
    prevRunningConfirmed += dayConfirmed;
    prevCheckpoints.push(mode === 'cumulative' ? prevRunningConfirmed : dayConfirmed);
  }

  const byDate = new Map<string, FinanceEntry[]>();
  for (const e of currentReal) {
    const arr = byDate.get(e.date) ?? [];
    arr.push(e);
    byDate.set(e.date, arr);
  }
  const sortedDates = Array.from(byDate.keys()).sort();

  let runConfirmed = 0;
  let runReceived = 0;
  let runPending = 0;

  const points: OverviewFinancePoint[] = sortedDates.map((date, idx) => {
    const dayEntries = byDate.get(date) ?? [];
    let dayConf = 0;
    let dayRec = 0;
    let dayPend = 0;
    let dayOut = 0;
    const brandSet = new Set<string>();
    const prodSet = new Set<string>();

    for (const e of dayEntries) {
      const val = convertCurrency(e.amount, e.currency, currency);
      brandSet.add(e.brandId);
      if (e.productId) prodSet.add(e.productId);

      if (e.type === 'Commission' || e.type === 'DirectRevenue') {
        if (e.stage === 'Pending') {
          dayPend += val;
        } else if (e.stage === 'Confirmed') {
          dayConf += val;
        } else if (e.stage === 'Received') {
          dayConf += val;
          dayRec += val;
        }
      } else if (e.type === 'Expense' || e.type === 'Reinvestment') {
        dayOut += val;
      }
    }

    runConfirmed += dayConf;
    runReceived += dayRec;
    runPending += dayPend;

    const prevValue =
      previousReal.length === 0
        ? null
        : idx < prevCheckpoints.length
        ? prevCheckpoints[idx]
        : prevCheckpoints[prevCheckpoints.length - 1] ?? 0;

    return {
      id: `pt-${date}`,
      date,
      isProjection: false,
      confirmedCommercial: mode === 'cumulative' ? runConfirmed : dayConf,
      receivedCash: mode === 'cumulative' ? runReceived : dayRec,
      pendingCommissions: mode === 'cumulative' ? runPending : dayPend,
      projection: null,
      previousConfirmed: prevValue,
      dailyConfirmedDelta: dayConf,
      dailyReceivedDelta: dayRec,
      dailyPendingDelta: dayPend,
      dailyOutflowDelta: dayOut,
      entryIds: dayEntries.map((e) => e.id),
      brandIds: Array.from(brandSet),
      productIds: Array.from(prodSet),
    };
  });

  if (includeProjection && projections.length > 0 && points.length > 0) {
    const projectedSum = projections.reduce(
      (acc, e) => acc + convertCurrency(e.amount, e.currency, currency),
      0
    );
    const lastReal = points[points.length - 1];
    lastReal.projection = lastReal.confirmedCommercial;

    const projDates = projections.map((p) => p.date).sort();
    const projDate = projDates[projDates.length - 1] ?? '2026-12-15';
    points.push({
      id: `pt-proj-${projDate}`,
      date: projDate,
      isProjection: true,
      confirmedCommercial: null,
      receivedCash: null,
      pendingCommissions: null,
      projection: (lastReal.confirmedCommercial ?? 0) + projectedSum,
      previousConfirmed: null,
      dailyConfirmedDelta: 0,
      dailyReceivedDelta: 0,
      dailyPendingDelta: 0,
      dailyOutflowDelta: projectedSum,
      entryIds: projections.map((p) => p.id),
      brandIds: Array.from(new Set(projections.map((p) => p.brandId))),
      productIds: projections.map((p) => p.productId).filter((x): x is string => Boolean(x)),
    });
  }

  return {
    window,
    points,
    previousWindowEntriesCount: previousReal.length,
    currentWindowEntriesCount: currentReal.length,
    hasPreviousData: previousReal.length > 0,
  };
}

export interface FinanceCashflowPoint {
  id: string;
  date: string;
  isProjection: boolean;
  receivedInflow: number | null;
  confirmedCommercial: number | null;
  pendingCommissions: number | null;
  outflows: number | null;
  projection: number | null;
  previousReceived: number | null;
  entryIds: string[];
}

export function buildFinanceCashflowSeries(
  entries: FinanceEntry[],
  currency: CurrencyCode,
  options: {
    brandId?: string;
    range: ChartTimeRange;
    customStart?: string;
    customEnd?: string;
    excludeTest?: boolean;
    includeProjections?: boolean;
    mode?: 'daily' | 'cumulative';
    referenceDate?: string;
  }
): {
  window: TimeWindowSpec;
  points: FinanceCashflowPoint[];
  hasPreviousData: boolean;
} {
  const excludeTest = options.excludeTest ?? true;
  const includeProjections = options.includeProjections ?? true;
  const mode = options.mode ?? 'daily';
  const window = resolveTimeWindow(
    options.range,
    options.customStart,
    options.customEnd,
    options.referenceDate
  );

  const scoped = entries.filter((e) => {
    if (excludeTest && e.isTest) return false;
    if (options.brandId && options.brandId !== 'all' && e.brandId !== options.brandId) return false;
    return true;
  });

  const currentReal = scoped.filter(
    (e) => !e.isProjection && e.date >= window.startDate && e.date <= window.endDate
  );
  const previousReal = scoped.filter(
    (e) => !e.isProjection && e.date >= window.prevStartDate && e.date <= window.prevEndDate
  );
  const projections = includeProjections ? scoped.filter((e) => Boolean(e.isProjection)) : [];

  const byDate = new Map<string, FinanceEntry[]>();
  for (const e of currentReal) {
    const arr = byDate.get(e.date) ?? [];
    arr.push(e);
    byDate.set(e.date, arr);
  }
  const sortedDates = Array.from(byDate.keys()).sort();

  const prevByDate = new Map<string, FinanceEntry[]>();
  for (const e of previousReal) {
    const arr = prevByDate.get(e.date) ?? [];
    arr.push(e);
    prevByDate.set(e.date, arr);
  }
  const prevSorted = Array.from(prevByDate.keys()).sort();
  let prevRunRec = 0;
  const prevCheckpoints = prevSorted.map((d) => {
    const dayRec = (prevByDate.get(d) ?? [])
      .filter((e) => (e.type === 'Commission' || e.type === 'DirectRevenue') && e.stage === 'Received')
      .reduce((acc, e) => acc + convertCurrency(e.amount, e.currency, currency), 0);
    prevRunRec += dayRec;
    return mode === 'cumulative' ? prevRunRec : dayRec;
  });

  let runRec = 0;
  let runConf = 0;
  let runPend = 0;
  let runOut = 0;

  const points: FinanceCashflowPoint[] = sortedDates.map((date, idx) => {
    const dayEntries = byDate.get(date) ?? [];
    let dayRec = 0;
    let dayConf = 0;
    let dayPend = 0;
    let dayOut = 0;

    for (const e of dayEntries) {
      const val = convertCurrency(e.amount, e.currency, currency);
      if (e.type === 'Commission' || e.type === 'DirectRevenue') {
        if (e.stage === 'Received') {
          dayRec += val;
          dayConf += val;
        } else if (e.stage === 'Confirmed') {
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

    return {
      id: `fin-pt-${date}`,
      date,
      isProjection: false,
      receivedInflow: mode === 'cumulative' ? runRec : dayRec,
      confirmedCommercial: mode === 'cumulative' ? runConf : dayConf,
      pendingCommissions: mode === 'cumulative' ? runPend : dayPend,
      outflows: mode === 'cumulative' ? runOut : dayOut,
      projection: null,
      previousReceived:
        previousReal.length === 0
          ? null
          : idx < prevCheckpoints.length
          ? prevCheckpoints[idx]
          : prevCheckpoints[prevCheckpoints.length - 1] ?? 0,
      entryIds: dayEntries.map((e) => e.id),
    };
  });

  if (projections.length > 0 && points.length > 0) {
    const projAmount = projections.reduce(
      (acc, e) => acc + convertCurrency(e.amount, e.currency, currency),
      0
    );
    const last = points[points.length - 1];
    last.projection = mode === 'cumulative' ? last.confirmedCommercial : projAmount;
    const projDate = projections.map((p) => p.date).sort()[projections.length - 1] ?? '2026-12-15';
    points.push({
      id: `fin-pt-proj-${projDate}`,
      date: projDate,
      isProjection: true,
      receivedInflow: null,
      confirmedCommercial: null,
      pendingCommissions: null,
      outflows: null,
      projection:
        mode === 'cumulative' ? (last.confirmedCommercial ?? 0) + projAmount : projAmount,
      previousReceived: null,
      entryIds: projections.map((p) => p.id),
    });
  }

  return {
    window,
    points,
    hasPreviousData: previousReal.length > 0,
  };
}

export type AnalyticsMetricKey = 'views' | 'clicks' | 'conversions' | 'ctr' | 'epc' | 'revenue';

export interface AnalyticsContentPoint {
  id: string;
  date: string;
  contentId: string;
  brandId: string;
  channelId: string;
  title: string;
  views: number;
  clicks: number;
  conversions: number; // Always labeled as Estimate
  ctrPct: number;
  epc: number;
  revenue: number;
  retention30sPct: number;
  trackingSrc: string;
  attributionStatus: string;
  isEstimate: boolean;
}

export function buildAnalyticsContentPoints(
  contents: ContentItem[],
  currency: CurrencyCode,
  options: {
    brandId?: string;
    channelId?: string;
    category?: 'all' | ContentCategory;
    range: ChartTimeRange;
    customStart?: string;
    customEnd?: string;
    referenceDate?: string;
  }
): {
  window: TimeWindowSpec;
  items: AnalyticsContentPoint[];
  previousCount: number;
} {
  const window = resolveTimeWindow(
    options.range,
    options.customStart,
    options.customEnd,
    options.referenceDate
  );

  const withMetrics = contents.filter((c) => {
    if (!c.metrics) return false;
    if (options.brandId && options.brandId !== 'all' && c.brandId !== options.brandId) return false;
    if (options.channelId && options.channelId !== 'all' && c.channelId !== options.channelId)
      return false;
    if (options.category && options.category !== 'all' && c.category !== options.category)
      return false;
    return true;
  });

  const inWindow = withMetrics
    .filter((c) => {
      const d = c.publishedAt ?? c.scheduledDate;
      return d >= window.startDate && d <= window.endDate;
    })
    .sort((a, b) => (a.publishedAt ?? a.scheduledDate).localeCompare(b.publishedAt ?? b.scheduledDate));

  const previousCount = withMetrics.filter((c) => {
    const d = c.publishedAt ?? c.scheduledDate;
    return d >= window.prevStartDate && d <= window.prevEndDate;
  }).length;

  const items: AnalyticsContentPoint[] = inWindow.map((c) => {
    const m = c.metrics!;
    const rev = convertCurrency(m.revenueGenerated, m.currency, currency);
    const ctrPct = m.views > 0 ? (m.clicks / m.views) * 100 : 0;
    const epc = m.clicks > 0 ? rev / m.clicks : 0;
    return {
      id: `an-${c.id}`,
      date: c.publishedAt ?? c.scheduledDate,
      contentId: c.id,
      brandId: c.brandId,
      channelId: c.channelId,
      title: c.title,
      views: m.views,
      clicks: m.clicks,
      conversions: m.conversions,
      ctrPct,
      epc,
      revenue: rev,
      retention30sPct: m.retention30sPct,
      trackingSrc: m.trackingSrc,
      attributionStatus: m.attributionStatus,
      isEstimate: m.attributionStatus !== 'Confirmada (Marca)',
    };
  });

  return { window, items, previousCount };
}

export type ChannelChartMetric = 'views30d' | 'reach30d' | 'followers' | 'engagementRatePct' | 'growthPct30d';

export function buildChannelComparisonItems(
  channels: Channel[],
  brands: Brand[],
  options: {
    brandId?: string;
    platform?: string;
    metric: ChannelChartMetric;
  }
) {
  return channels
    .filter((ch) => {
      if (options.brandId && options.brandId !== 'all' && ch.brandId !== options.brandId) return false;
      if (options.platform && options.platform !== 'all' && ch.platform !== options.platform)
        return false;
      return true;
    })
    .map((ch) => {
      const brand = brands.find((b) => b.id === ch.brandId);
      const rawValue =
        options.metric === 'views30d'
          ? ch.views30d
          : options.metric === 'reach30d'
          ? ch.reach30d
          : options.metric === 'followers'
          ? ch.followers
          : options.metric === 'engagementRatePct'
          ? ch.engagementRatePct
          : ch.growthPct30d;
      return {
        channel: ch,
        brandName: brand?.name ?? ch.brandId,
        rawValue,
        accentColor: brand?.accentColor ?? '#315FEA',
      };
    })
    .sort((a, b) => b.rawValue - a.rawValue);
}

export type ProductChartMetric = 'opportunityScore' | 'epcValue' | 'commissionRatePct' | 'demandTrendPct';

export interface ProductCurrencyChartItem {
  product: Product;
  value: number | null; // Preserves null strictly — NEVER coerces missing fields to 0
  missingData: boolean;
}

/**
 * Strictly groups and compares products WITHIN a single native currency.
 * Never mixes BRL, USD, and EUR in the same comparison or converts `null` to `0`.
 */
export function buildProductNativeCurrencyComparison(
  products: Product[],
  nativeCurrency: CurrencyCode,
  metric: ProductChartMetric,
  options?: { excludeTest?: boolean; brandId?: string }
): ProductCurrencyChartItem[] {
  const excludeTest = options?.excludeTest ?? true;
  const scoped = products.filter((p) => {
    if (excludeTest && p.isTest) return false;
    if (p.currency !== nativeCurrency) return false;
    if (
      options?.brandId &&
      options.brandId !== 'all' &&
      p.brandId !== options.brandId &&
      !p.linkedBrandIds.includes(options.brandId)
    ) {
      return false;
    }
    return true;
  });

  const mapped: ProductCurrencyChartItem[] = scoped.map((p) => {
    const val =
      metric === 'opportunityScore'
        ? p.opportunityScore
        : metric === 'epcValue'
        ? p.epcValue
        : metric === 'commissionRatePct'
        ? p.commissionRatePct
        : p.demandTrendPct;
    return {
      product: p,
      value: val,
      missingData: val === null,
    };
  });

  return mapped.sort((a, b) => {
    if (a.value === null && b.value === null) return 0;
    if (a.value === null) return 1;
    if (b.value === null) return -1;
    return b.value - a.value;
  });
}
