import test from 'node:test';
import assert from 'node:assert/strict';
import { INITIAL_VYRON_STATE } from '../data/seedData';
import {
  buildAnalyticsContentPoints,
  buildFinanceCashflowSeries,
  buildOverviewFinanceSeries,
  buildProductNativeCurrencyComparison,
  resolveTimeWindow,
} from './chartSeries';

test('resolveTimeWindow computes 7d, 30d, and custom ranges deterministically', () => {
  const w7 = resolveTimeWindow('7d');
  assert.equal(w7.startDate, '2026-11-12');
  assert.equal(w7.endDate, '2026-11-18');
  assert.equal(w7.days, 7);
  assert.equal(w7.prevEndDate, '2026-11-11');
  assert.equal(w7.prevStartDate, '2026-11-05');

  const wCustom = resolveTimeWindow('custom', '2026-11-10', '2026-11-15');
  assert.equal(wCustom.days, 6);
  assert.equal(wCustom.prevStartDate, '2026-11-04');
  assert.equal(wCustom.prevEndDate, '2026-11-09');
});

test('buildOverviewFinanceSeries keeps Pending, Confirmed, Received, and Projections strictly separated and responds to 7d vs 30d', () => {
  const res30 = buildOverviewFinanceSeries(INITIAL_VYRON_STATE.financeEntries, 'BRL', {
    range: '30d',
    excludeTest: true,
    includeProjection: true,
  });
  const res7 = buildOverviewFinanceSeries(INITIAL_VYRON_STATE.financeEntries, 'BRL', {
    range: '7d',
    excludeTest: true,
    includeProjection: true,
  });

  const real30 = res30.points.filter((p) => !p.isProjection);
  const real7 = res7.points.filter((p) => !p.isProjection);
  assert.ok(real30.length > real7.length);

  // Confirm fin-test-1 (2026-11-14, 15000 BRL isTest) is excluded
  assert.equal(
    real30.some((p) => p.entryIds.includes('fin-test-1')),
    false
  );

  // Last real point on 2026-11-18: confirmedCommercial > receivedCash, and pendingCommissions stays isolated
  const lastReal = real30[real30.length - 1];
  assert.equal(lastReal.date, '2026-11-18');
  assert.ok((lastReal.confirmedCommercial ?? 0) > (lastReal.receivedCash ?? 0));
  assert.ok((lastReal.pendingCommissions ?? 0) > 0);

  // Projection sits strictly on its own isolated point (2026-12-15) with null realized fields
  const projPoint = res30.points[res30.points.length - 1];
  assert.equal(projPoint.isProjection, true);
  assert.equal(projPoint.confirmedCommercial, null);
  assert.equal(projPoint.receivedCash, null);
  assert.equal(projPoint.pendingCommissions, null);
  assert.ok((projPoint.projection ?? 0) > (lastReal.confirmedCommercial ?? 0));

  // Previous window on 7d (2026-11-05..2026-11-11) actually contains real entries (fin-1..fin-3, fin-10)
  assert.equal(res7.hasPreviousData, true);
  // Previous window on 30d (before 2026-10-20) honestly reports no prior demo entries
  assert.equal(res30.hasPreviousData, false);
  assert.equal(real30[0].previousConfirmed, null);
});

test('buildFinanceCashflowSeries filters by brand and preserves outflows vs inflows', () => {
  const apexDaily = buildFinanceCashflowSeries(INITIAL_VYRON_STATE.financeEntries, 'BRL', {
    brandId: 'brand-apex',
    range: '30d',
    mode: 'daily',
    excludeTest: true,
    includeProjections: false,
  });

  const nov04 = apexDaily.points.find((p) => p.date === '2026-11-04');
  assert.ok(nov04);
  assert.equal(nov04.outflows, 3200);
  assert.equal(nov04.receivedInflow, 0);

  const nov05 = apexDaily.points.find((p) => p.date === '2026-11-05');
  assert.ok(nov05);
  assert.equal(nov05.receivedInflow, 9420.5);
});

test('buildAnalyticsContentPoints filters by period and channel without inventing missing content metrics', () => {
  const res30 = buildAnalyticsContentPoints(INITIAL_VYRON_STATE.contents, 'BRL', {
    range: '30d',
  });
  assert.equal(res30.items.length, 2);
  assert.equal(res30.items[0].contentId, 'cnt-1');
  assert.equal(res30.items[1].contentId, 'cnt-4');
  assert.equal(res30.items[0].isEstimate, true);

  // 7d window (2026-11-12..2026-11-18) has 0 published metrics items in seed, and 2 in previous window (11-05..11-11)
  const res7 = buildAnalyticsContentPoints(INITIAL_VYRON_STATE.contents, 'BRL', {
    range: '7d',
  });
  assert.equal(res7.items.length, 0);
  assert.equal(res7.previousCount, 2);
});

test('buildProductNativeCurrencyComparison isolates native currency and preserves null without coercing to 0', () => {
  const eurItems = buildProductNativeCurrencyComparison(
    INITIAL_VYRON_STATE.products,
    'EUR',
    'opportunityScore',
    { excludeTest: true }
  );
  assert.ok(eurItems.every((i) => i.product.currency === 'EUR'));
  const missing = eurItems.find((i) => i.product.id === 'prod-unknown-epc');
  assert.ok(missing);
  assert.equal(missing.value, null);
  assert.equal(missing.missingData, true);
  // Missing-data items sort after scored items
  assert.equal(eurItems[eurItems.length - 1].product.id, 'prod-unknown-epc');

  // Test products excluded by default
  const brlItems = buildProductNativeCurrencyComparison(
    INITIAL_VYRON_STATE.products,
    'BRL',
    'opportunityScore',
    { excludeTest: true }
  );
  assert.equal(
    brlItems.some((i) => i.product.isTest),
    false
  );
});
