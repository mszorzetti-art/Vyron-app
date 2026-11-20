import React, { useId, useMemo, useRef, useState } from 'react';
import { Calendar, GitCompare, Table2, TrendingUp, X } from 'lucide-react';
import { useI18n } from '../i18n/useI18n';
import { ChartTimeRange } from '../utils/chartSeries';

export interface InteractiveSeriesConfig {
  id: string;
  label: string;
  color: string;
  dashed?: boolean;
  areaFill?: boolean;
  strokeWidth?: number;
  defaultHidden?: boolean;
  isEstimate?: boolean;
  isProjection?: boolean;
  formatValue?: (v: number) => string;
}

export interface InteractiveTimeSeriesPoint {
  id: string;
  label: string;
  fullDateLabel?: string;
  isProjection?: boolean;
  isEstimate?: boolean;
  values: Record<string, number | null | undefined>;
}

export interface ComparisonBarItem {
  id: string;
  label: string;
  sublabel?: string;
  value: number | null;
  formattedValue: string;
  color?: string;
  badge?: string;
  isMissing?: boolean;
}

export const ChartTimeframeToolbar: React.FC<{
  range: ChartTimeRange;
  onRangeChange: (next: ChartTimeRange) => void;
  customStart: string;
  customEnd: string;
  onCustomStartChange: (date: string) => void;
  onCustomEndChange: (date: string) => void;
  comparePrevious?: boolean;
  onToggleComparePrevious?: () => void;
  hasPreviousData?: boolean;
  coverageNote?: string;
  extraControls?: React.ReactNode;
}> = ({
  range,
  onRangeChange,
  customStart,
  customEnd,
  onCustomStartChange,
  onCustomEndChange,
  comparePrevious = false,
  onToggleComparePrevious,
  hasPreviousData = true,
  coverageNote,
  extraControls,
}) => {
  const { t } = useI18n();

  const ranges: Array<{ value: ChartTimeRange; label: string }> = [
    { value: '7d', label: t('charts.range7d') },
    { value: '30d', label: t('charts.range30d') },
    { value: '90d', label: t('charts.range90d') },
    { value: '12m', label: t('charts.range12m') },
    { value: 'custom', label: t('charts.rangeCustom') },
  ];

  return (
    <div className="space-y-2 mb-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <div
            role="tablist"
            aria-label={t('charts.rangeAria')}
            className="inline-flex flex-wrap items-center gap-0.5 p-0.5 rounded-md bg-[#E6E9ED] dark:bg-[#101216] border border-black/10 dark:border-white/10"
          >
            {ranges.map((r) => {
              const active = range === r.value;
              return (
                <button
                  key={r.value}
                  type="button"
                  role="tab"
                  aria-selected={active}
                  onClick={() => onRangeChange(r.value)}
                  className={`px-2.5 py-1 text-[11px] font-medium rounded whitespace-nowrap shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] ${
                    active
                      ? 'bg-white dark:bg-[#292E36] text-[#101216] dark:text-[#F1F2F3] shadow-xs'
                      : 'text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]'
                  }`}
                >
                  {r.label}
                </button>
              );
            })}
          </div>

          {onToggleComparePrevious && (
            <button
              type="button"
              aria-pressed={comparePrevious}
              onClick={onToggleComparePrevious}
              className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-medium rounded-md border whitespace-nowrap shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] ${
                comparePrevious
                  ? 'border-[#315FEA] bg-[#315FEA]/12 text-[#315FEA] dark:text-[#7FA0FF]'
                  : 'border-black/10 dark:border-white/10 bg-white dark:bg-[#101216] text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3]'
              }`}
            >
              <GitCompare className="w-3 h-3 shrink-0" aria-hidden="true" />
              <span>{comparePrevious ? t('charts.compareActive') : t('charts.comparePrev')}</span>
            </button>
          )}
        </div>

        {extraControls && <div className="flex flex-wrap items-center gap-2">{extraControls}</div>}
      </div>

      {range === 'custom' && (
        <div className="flex flex-wrap items-center gap-2 text-[11px]">
          <Calendar className="w-3.5 h-3.5 text-[#525B68] dark:text-[#AEB7C2] shrink-0" aria-hidden="true" />
          <input
            type="date"
            aria-label={t('charts.customStartAria')}
            value={customStart}
            onChange={(e) => onCustomStartChange(e.target.value)}
            className="h-7 px-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#101216] font-mono text-[11px] text-[#101216] dark:text-[#F1F2F3]"
          />
          <span className="text-[#525B68] dark:text-[#AEB7C2]">—</span>
          <input
            type="date"
            aria-label={t('charts.customEndAria')}
            value={customEnd}
            onChange={(e) => onCustomEndChange(e.target.value)}
            className="h-7 px-2 rounded border border-black/15 dark:border-white/15 bg-white dark:bg-[#101216] font-mono text-[11px] text-[#101216] dark:text-[#F1F2F3]"
          />
        </div>
      )}

      {comparePrevious && !hasPreviousData && (
        <p className="text-[11px] text-amber-700 dark:text-amber-400">
          {t('charts.prevNoDataNote')}
        </p>
      )}
      {(!comparePrevious || hasPreviousData) && coverageNote && (
        <p className="text-[11px] text-[#525B68] dark:text-[#AEB7C2]">{coverageNote}</p>
      )}
    </div>
  );
};

export const InteractiveTimeSeriesChart: React.FC<{
  points: InteractiveTimeSeriesPoint[];
  series: InteractiveSeriesConfig[];
  formatValue: (v: number) => string;
  formatYAxis?: (v: number) => string;
  height?: number;
  ariaLabel: string;
  selectedPointId?: string | null;
  onSelectPoint?: (point: InteractiveTimeSeriesPoint | null, index: number | null) => void;
  emptyMessage?: string;
}> = ({
  points,
  series,
  formatValue,
  formatYAxis,
  height = 250,
  ariaLabel,
  selectedPointId = null,
  onSelectPoint,
  emptyMessage,
}) => {
  const { t, fmtNumber } = useI18n();
  const gradId = useId().replace(/:/g, '');
  const svgRef = useRef<SVGSVGElement | null>(null);

  const [hoverIdx, setHoverIdx] = useState<number | null>(null);
  const [showTable, setShowTable] = useState(false);
  const [hiddenSeriesIds, setHiddenSeriesIds] = useState<Record<string, boolean>>(() => {
    const initial: Record<string, boolean> = {};
    for (const s of series) {
      if (s.defaultHidden) initial[s.id] = true;
    }
    return initial;
  });

  const visibleSeries = useMemo(
    () => series.filter((s) => !hiddenSeriesIds[s.id]),
    [series, hiddenSeriesIds]
  );

  const selectedIdx = useMemo(() => {
    if (!selectedPointId) return null;
    const found = points.findIndex((p) => p.id === selectedPointId);
    return found >= 0 ? found : null;
  }, [points, selectedPointId]);

  const activeIdx = hoverIdx !== null ? hoverIdx : selectedIdx;
  const activePoint = activeIdx !== null && points[activeIdx] ? points[activeIdx] : null;

  const toggleSeries = (id: string) => {
    setHiddenSeriesIds((prev) => {
      const next = { ...prev, [id]: !prev[id] };
      const remaining = series.filter((s) => !next[s.id]);
      if (remaining.length === 0) return prev; // keep at least 1 active series
      return next;
    });
  };

  if (points.length === 0) {
    return (
      <div className="py-10 px-4 text-center rounded-md border border-dashed border-black/15 dark:border-white/15 bg-[#F1F2F3]/50 dark:bg-[#101216]/50">
        <TrendingUp className="w-5 h-5 mx-auto text-[#AEB7C2] mb-2" aria-hidden="true" />
        <p className="text-xs text-[#525B68] dark:text-[#AEB7C2]">
          {emptyMessage ?? t('charts.emptyPeriod')}
        </p>
      </div>
    );
  }

  const width = 680;
  const padL = 62;
  const padR = 18;
  const padT = 18;
  const padB = 30;
  const innerW = width - padL - padR;
  const innerH = height - padT - padB;

  const allValues: number[] = [];
  for (const p of points) {
    for (const s of visibleSeries) {
      const v = p.values[s.id];
      if (typeof v === 'number' && Number.isFinite(v)) {
        allValues.push(v);
      }
    }
  }

  const rawMin = allValues.length > 0 ? Math.min(0, ...allValues) : 0;
  const rawMax = allValues.length > 0 ? Math.max(...allValues, 1) : 100;
  const span = Math.max(rawMax - rawMin, 1);
  const yMin = rawMin < 0 ? rawMin - span * 0.08 : 0;
  const yMax = rawMax + span * 0.12;
  const yRange = Math.max(yMax - yMin, 1);

  const xAt = (i: number) =>
    padL + (points.length === 1 ? innerW / 2 : (i / (points.length - 1)) * innerW);
  const yAt = (v: number) => padT + innerH - ((v - yMin) / yRange) * innerH;

  const buildSegmentedPath = (seriesId: string) => {
    let path = '';
    let started = false;
    points.forEach((pt, i) => {
      const v = pt.values[seriesId];
      if (v === null || v === undefined || !Number.isFinite(v)) {
        started = false;
        return;
      }
      const cmd = started ? 'L' : 'M';
      path += `${cmd} ${xAt(i).toFixed(1)} ${yAt(v).toFixed(1)} `;
      started = true;
    });
    return path.trim();
  };

  const primaryAreaSeries = visibleSeries.find((s) => s.areaFill) ?? visibleSeries[0];
  const primaryAreaPts = primaryAreaSeries
    ? points
        .map((p, i) => ({ v: p.values[primaryAreaSeries.id], i }))
        .filter((x) => typeof x.v === 'number' && Number.isFinite(x.v))
    : [];
  const primaryAreaLine = primaryAreaSeries ? buildSegmentedPath(primaryAreaSeries.id) : '';
  const baselineY = yAt(Math.max(yMin, 0));
  const areaPath =
    primaryAreaPts.length >= 2 && primaryAreaLine
      ? `${primaryAreaLine} L ${xAt(primaryAreaPts[primaryAreaPts.length - 1].i).toFixed(1)} ${baselineY.toFixed(1)} L ${xAt(primaryAreaPts[0].i).toFixed(1)} ${baselineY.toFixed(1)} Z`
      : '';

  const yTicks = [0, 0.25, 0.5, 0.75, 1].map((ratio) => {
    const val = yMin + yRange * ratio;
    return { ratio, val, y: yAt(val) };
  });

  // Width-aware X-axis label placement so adjacent or projection labels never collide
  const visibleXIndices = (() => {
    const chosen = new Set<number>();
    if (points.length === 0) return chosen;
    if (points.length === 1) {
      chosen.add(0);
      return chosen;
    }
    const estWidth = (text: string) => Math.max(28, text.length * 6.4);
    const lastIdx = points.length - 1;
    const firstRightEdge = xAt(0) + estWidth(points[0].label);
    const lastLeftEdge = xAt(lastIdx) - estWidth(points[lastIdx].label);

    chosen.add(0);
    if (lastLeftEdge > firstRightEdge + 12) {
      chosen.add(lastIdx);
    }

    let prevRightEdge = firstRightEdge;
    for (let i = 1; i < lastIdx; i++) {
      const halfW = estWidth(points[i].label) / 2;
      const cx = xAt(i);
      const leftEdge = cx - halfW;
      const rightEdge = cx + halfW;
      if (leftEdge >= prevRightEdge + 16 && rightEdge + 16 <= lastLeftEdge) {
        chosen.add(i);
        prevRightEdge = rightEdge;
      }
    }
    return chosen;
  })();
  const shouldShowXLabel = (idx: number) => visibleXIndices.has(idx);

  const findNearestIndex = (clientX: number): number | null => {
    const svg = svgRef.current;
    if (!svg || points.length === 0) return null;
    const rect = svg.getBoundingClientRect();
    if (rect.width <= 0) return null;
    const svgX = ((clientX - rect.left) / rect.width) * width;
    if (points.length === 1) return 0;
    const clampedX = Math.max(padL, Math.min(width - padR, svgX));
    const ratio = (clampedX - padL) / innerW;
    return Math.max(0, Math.min(points.length - 1, Math.round(ratio * (points.length - 1))));
  };

  const handlePointerMove = (e: React.PointerEvent<SVGSVGElement>) => {
    const idx = findNearestIndex(e.clientX);
    if (idx !== null) setHoverIdx(idx);
  };

  const handlePointerDown = (e: React.PointerEvent<SVGSVGElement>) => {
    const idx = findNearestIndex(e.clientX);
    if (idx === null) return;
    setHoverIdx(idx);
    if (e.pointerType === 'touch' && onSelectPoint) {
      const pt = points[idx];
      onSelectPoint(pt, idx);
    }
  };

  const handleSvgClick = (e: React.MouseEvent<SVGSVGElement>) => {
    if (!onSelectPoint) return;
    const idx = findNearestIndex(e.clientX);
    if (idx === null) return;
    const pt = points[idx];
    if (selectedPointId === pt.id) {
      onSelectPoint(null, null);
    } else {
      onSelectPoint(pt, idx);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLDivElement>) => {
    if (points.length === 0) return;
    const cur = activeIdx ?? 0;
    if (e.key === 'ArrowRight') {
      e.preventDefault();
      const next = Math.min(points.length - 1, cur + 1);
      setHoverIdx(next);
      onSelectPoint?.(points[next], next);
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault();
      const prev = Math.max(0, cur - 1);
      setHoverIdx(prev);
      onSelectPoint?.(points[prev], prev);
    } else if (e.key === 'Home') {
      e.preventDefault();
      setHoverIdx(0);
      onSelectPoint?.(points[0], 0);
    } else if (e.key === 'End') {
      e.preventDefault();
      const last = points.length - 1;
      setHoverIdx(last);
      onSelectPoint?.(points[last], last);
    } else if (e.key === 'Escape') {
      setHoverIdx(null);
      onSelectPoint?.(null, null);
    }
  };

  // Calculate delta vs previous point on the first visible series with data at activeIdx
  let deltaText: string | null = null;
  if (activePoint && activeIdx !== null && activeIdx > 0) {
    const primaryS =
      visibleSeries.find((s) => typeof activePoint.values[s.id] === 'number') ?? visibleSeries[0];
    if (primaryS) {
      const currVal = activePoint.values[primaryS.id];
      const prevVal = points[activeIdx - 1]?.values[primaryS.id];
      if (
        typeof currVal === 'number' &&
        typeof prevVal === 'number' &&
        Number.isFinite(currVal) &&
        Number.isFinite(prevVal)
      ) {
        const diff = currVal - prevVal;
        const pctStr =
          prevVal !== 0 ? ` (${diff >= 0 ? '+' : ''}${fmtNumber((diff / Math.abs(prevVal)) * 100, 1)}%)` : '';
        const fmt = primaryS.formatValue ?? formatValue;
        const sign = diff > 0 ? '+' : diff < 0 ? '-' : '';
        deltaText = `${sign}${fmt(Math.abs(diff))}${pctStr}`;
      }
    }
  }

  const activeXPct = activeIdx !== null ? (xAt(activeIdx) / width) * 100 : 50;
  const flipTooltipLeft = activeXPct > 56;

  return (
    <div className="space-y-3">
      {/* Series legend toggles + Table toggle */}
      <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
        <div className="flex flex-wrap items-center gap-1.5">
          {series.map((s) => {
            const hidden = Boolean(hiddenSeriesIds[s.id]);
            return (
              <button
                key={s.id}
                type="button"
                aria-pressed={!hidden}
                aria-label={t('charts.legendToggleAria', { label: s.label })}
                onClick={() => toggleSeries(s.id)}
                className={`inline-flex items-center gap-1.5 px-2 py-1 rounded border text-[11px] transition-opacity focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] ${
                  hidden
                    ? 'opacity-45 border-black/10 dark:border-white/10 text-[#525B68] dark:text-[#AEB7C2]'
                    : 'border-black/10 dark:border-white/10 bg-[#F1F2F3]/70 dark:bg-[#101216] text-[#101216] dark:text-[#F1F2F3]'
                }`}
              >
                <span
                  className="w-3 h-0.5 inline-block shrink-0"
                  style={{
                    backgroundColor: s.dashed ? 'transparent' : s.color,
                    borderBottom: s.dashed ? `2px dashed ${s.color}` : undefined,
                  }}
                />
                <span>{s.label}</span>
              </button>
            );
          })}
        </div>

        <div className="flex items-center gap-2 shrink-0">
          {selectedPointId && onSelectPoint && (
            <button
              type="button"
              onClick={() => onSelectPoint(null, null)}
              className="inline-flex items-center gap-1 px-2 py-1 rounded border border-[#315FEA]/40 text-[11px] text-[#315FEA] dark:text-[#7FA0FF] hover:bg-[#315FEA]/10 whitespace-nowrap"
            >
              <X className="w-3 h-3" aria-hidden="true" />
              <span>{t('charts.clearPin')}</span>
            </button>
          )}
          <button
            type="button"
            aria-expanded={showTable}
            onClick={() => setShowTable((v) => !v)}
            className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded border border-black/10 dark:border-white/10 text-[11px] font-medium text-[#525B68] dark:text-[#AEB7C2] hover:text-[#101216] dark:hover:text-[#F1F2F3] whitespace-nowrap"
          >
            <Table2 className="w-3.5 h-3.5" aria-hidden="true" />
            <span>{showTable ? t('charts.toggleTableHide') : t('charts.toggleTableShow')}</span>
          </button>
        </div>
      </div>

      {showTable ? (
        <div className="overflow-x-auto rounded-md border border-black/10 dark:border-white/10">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-black/10 dark:border-white/10 bg-black/[0.02] dark:bg-white/[0.02] text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
                <th className="py-2 pl-3 pr-3">{t('charts.tableColPeriod')}</th>
                {visibleSeries.map((s) => (
                  <th key={s.id} className="py-2 px-3 text-right whitespace-nowrap">
                    {s.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-black/[0.06] dark:divide-white/[0.06]">
              {points.map((pt) => {
                const isSel = selectedPointId === pt.id;
                return (
                  <tr
                    key={pt.id}
                    className={
                      isSel
                        ? 'bg-[#315FEA]/10'
                        : 'hover:bg-black/[0.02] dark:hover:bg-white/[0.02]'
                    }
                  >
                    <td className="py-2 pl-3 pr-3 font-mono text-[11px] whitespace-nowrap">
                      <button
                        type="button"
                        onClick={() =>
                          onSelectPoint?.(isSel ? null : pt, isSel ? null : points.indexOf(pt))
                        }
                        className="text-left hover:text-[#315FEA] dark:hover:text-[#7FA0FF] font-medium"
                      >
                        {pt.fullDateLabel ?? pt.label}
                        {pt.isProjection ? ` · ${t('charts.projectionBadge')}` : ''}
                      </button>
                    </td>
                    {visibleSeries.map((s) => {
                      const val = pt.values[s.id];
                      const fmt = s.formatValue ?? formatValue;
                      return (
                        <td
                          key={s.id}
                          className="py-2 px-3 text-right font-mono tabular-nums whitespace-nowrap"
                        >
                          {typeof val === 'number' && Number.isFinite(val) ? fmt(val) : '—'}
                        </td>
                      );
                    })}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      ) : (
        <div
          className="relative rounded-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA]"
          tabIndex={0}
          role="group"
          aria-label={ariaLabel}
          onKeyDown={handleKeyDown}
        >
          <svg
            ref={svgRef}
            viewBox={`0 0 ${width} ${height}`}
            className="w-full h-auto block select-none cursor-crosshair"
            style={{ touchAction: 'pan-y' }}
            role="img"
            aria-label={ariaLabel}
            onPointerMove={handlePointerMove}
            onPointerDown={handlePointerDown}
            onPointerLeave={() => setHoverIdx(null)}
            onClick={handleSvgClick}
          >
            <defs>
              <linearGradient id={`vyronArea-${gradId}`} x1="0" y1="0" x2="0" y2="1">
                <stop
                  offset="0%"
                  stopColor={primaryAreaSeries?.color ?? '#315FEA'}
                  stopOpacity="0.22"
                />
                <stop
                  offset="100%"
                  stopColor={primaryAreaSeries?.color ?? '#315FEA'}
                  stopOpacity="0.0"
                />
              </linearGradient>
            </defs>

            {/* Horizontal gridlines + Y-axis labels */}
            {yTicks.map((tick) => (
              <g key={tick.ratio}>
                <line
                  x1={padL}
                  x2={width - padR}
                  y1={tick.y}
                  y2={tick.y}
                  stroke="currentColor"
                  className={
                    tick.ratio === 0
                      ? 'text-black/[0.14] dark:text-white/[0.14]'
                      : 'text-black/[0.07] dark:text-white/[0.07]'
                  }
                  strokeWidth="1"
                />
                <text
                  x={padL - 8}
                  y={tick.y + 3.5}
                  textAnchor="end"
                  fontSize="10"
                  className="fill-[#525B68] dark:fill-[#AEB7C2] font-mono tabular-nums"
                >
                  {(formatYAxis ?? formatValue)(tick.val)}
                </text>
              </g>
            ))}

            {/* Area fill */}
            {areaPath && <path d={areaPath} fill={`url(#vyronArea-${gradId})`} />}

            {/* Lines */}
            {visibleSeries.map((s) => {
              const d = buildSegmentedPath(s.id);
              if (!d) return null;
              return (
                <path
                  key={s.id}
                  d={d}
                  fill="none"
                  stroke={s.color}
                  strokeWidth={s.strokeWidth ?? (s.dashed ? 1.8 : 2.2)}
                  strokeDasharray={s.dashed ? '4 4' : undefined}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              );
            })}

            {/* Vertical crosshair */}
            {activeIdx !== null && (
              <line
                x1={xAt(activeIdx)}
                x2={xAt(activeIdx)}
                y1={padT}
                y2={padT + innerH}
                stroke="#315FEA"
                strokeOpacity="0.55"
                strokeDasharray="3 3"
                strokeWidth="1.2"
              />
            )}

            {/* Data point dots & X-axis labels */}
            {points.map((pt, i) => {
              const cx = xAt(i);
              const isActive = activeIdx === i;
              const isPinned = selectedIdx === i;

              return (
                <g key={pt.id}>
                  {visibleSeries.map((s) => {
                    const val = pt.values[s.id];
                    if (typeof val !== 'number' || !Number.isFinite(val)) return null;
                    const cy = yAt(val);
                    return (
                      <g key={`${pt.id}-${s.id}`}>
                        {isPinned && (
                          <circle
                            cx={cx}
                            cy={cy}
                            r={6.5}
                            fill="none"
                            stroke={s.color}
                            strokeOpacity="0.45"
                            strokeWidth="1.5"
                          />
                        )}
                        <circle
                          cx={cx}
                          cy={cy}
                          r={isActive ? 4.5 : points.length > 16 ? 2 : 3}
                          fill={s.color}
                          stroke={isActive ? '#FFFFFF' : 'none'}
                          strokeWidth={isActive ? 1.2 : 0}
                        />
                      </g>
                    );
                  })}

                  {shouldShowXLabel(i) && (
                    <text
                      x={cx}
                      y={height - 8}
                      textAnchor={
                        i === 0 && points.length > 2
                          ? 'start'
                          : i === points.length - 1 && points.length > 2
                          ? 'end'
                          : 'middle'
                      }
                      fontSize="10"
                      className={`font-mono ${
                        isActive
                          ? 'fill-[#101216] dark:fill-[#F1F2F3] font-semibold'
                          : 'fill-[#525B68] dark:fill-[#AEB7C2]'
                      }`}
                    >
                      {pt.label}
                    </text>
                  )}
                </g>
              );
            })}
          </svg>

          {/* Clamped floating tooltip (desktop & mobile safe) */}
          {activePoint && activeIdx !== null && (
            <div
              className="pointer-events-none hidden sm:block absolute top-2 z-20 w-[236px] rounded-md border border-black/15 dark:border-white/15 bg-white/95 dark:bg-[#101216]/95 shadow-lg p-2.5 text-[11px] backdrop-blur-xs"
              style={{
                left: `clamp(8px, calc(${activeXPct.toFixed(1)}% ${
                  flipTooltipLeft ? '- 248px' : '+ 12px'
                }), calc(100% - 244px))`,
              }}
            >
              <div className="flex items-center justify-between gap-2 pb-1.5 mb-1.5 border-b border-black/10 dark:border-white/10">
                <span className="font-mono font-semibold text-[#101216] dark:text-[#F1F2F3]">
                  {activePoint.fullDateLabel ?? activePoint.label}
                </span>
                {(activePoint.isProjection || activePoint.isEstimate) && (
                  <span className="font-mono text-[10px] text-amber-700 dark:text-amber-400">
                    {activePoint.isProjection ? t('charts.projectionBadge') : t('charts.estimateBadge')}
                  </span>
                )}
              </div>
              <div className="space-y-1">
                {visibleSeries.map((s) => {
                  const val = activePoint.values[s.id];
                  if (typeof val !== 'number' || !Number.isFinite(val)) return null;
                  const fmt = s.formatValue ?? formatValue;
                  return (
                    <div key={s.id} className="flex items-center justify-between gap-2">
                      <span className="inline-flex items-center gap-1.5 text-[#525B68] dark:text-[#AEB7C2] truncate">
                        <span
                          className="w-2 h-2 rounded-full shrink-0"
                          style={{ backgroundColor: s.color }}
                        />
                        <span className="truncate">{s.label}</span>
                      </span>
                      <span className="font-mono tabular-nums font-semibold text-[#101216] dark:text-[#F1F2F3] shrink-0">
                        {fmt(val)}
                      </span>
                    </div>
                  );
                })}
              </div>
              {deltaText && (
                <div className="mt-1.5 pt-1 border-t border-black/10 dark:border-white/10 font-mono text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                  {t('charts.deltaFromPrev', { delta: deltaText })}
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* Always-accessible inline readout strip (ideal for touch/mobile and screen readers) */}
      <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-black/[0.06] dark:border-white/[0.06] text-[11px] text-[#525B68] dark:text-[#AEB7C2]">
        {activePoint ? (
          <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
            <span className="font-mono font-semibold text-[#101216] dark:text-[#F1F2F3]">
              {selectedPointId === activePoint.id ? `${t('charts.pinnedLabel')}: ` : ''}
              {activePoint.fullDateLabel ?? activePoint.label}
            </span>
            {visibleSeries.map((s) => {
              const val = activePoint.values[s.id];
              if (typeof val !== 'number' || !Number.isFinite(val)) return null;
              const fmt = s.formatValue ?? formatValue;
              return (
                <span key={s.id} className="inline-flex items-center gap-1 font-mono tabular-nums">
                  <span
                    className="w-1.5 h-1.5 rounded-full shrink-0"
                    style={{ backgroundColor: s.color }}
                  />
                  <span>{s.label}:</span>
                  <strong className="text-[#101216] dark:text-[#F1F2F3]">{fmt(val)}</strong>
                </span>
              );
            })}
            {deltaText && (
              <span className="font-mono text-[10px]">{t('charts.deltaFromPrev', { delta: deltaText })}</span>
            )}
          </div>
        ) : (
          <span>{t('charts.hintInteract')}</span>
        )}
      </div>
    </div>
  );
};

export const InteractiveComparisonChart: React.FC<{
  items: ComparisonBarItem[];
  selectedId?: string | null;
  onSelect?: (item: ComparisonBarItem | null) => void;
  emptyMessage?: string;
}> = ({ items, selectedId = null, onSelect, emptyMessage }) => {
  const { t } = useI18n();
  const [hoverId, setHoverId] = useState<string | null>(null);

  if (items.length === 0) {
    return (
      <div className="py-8 px-4 text-center rounded-md border border-dashed border-black/15 dark:border-white/15 text-xs text-[#525B68] dark:text-[#AEB7C2]">
        {emptyMessage ?? t('charts.noComparisonBars')}
      </div>
    );
  }

  const numericValues = items
    .map((i) => i.value)
    .filter((v): v is number => typeof v === 'number' && Number.isFinite(v));
  const maxAbs = Math.max(...numericValues.map((v) => Math.abs(v)), 1);

  return (
    <div className="space-y-2.5">
      {items.map((item) => {
        const isMissing = item.isMissing || item.value === null || !Number.isFinite(item.value);
        const isSelected = selectedId === item.id;
        const isHovered = hoverId === item.id;
        const pct = isMissing
          ? 0
          : Math.max(4, Math.min(100, (Math.abs(item.value!) / maxAbs) * 100));
        const barColor =
          !isMissing && (item.value ?? 0) < 0 ? '#E11D48' : item.color ?? '#315FEA';

        const content = (
          <div className="space-y-1.5 w-full text-left">
            <div className="flex items-start justify-between gap-3 text-xs">
              <div className="min-w-0">
                <div className="font-medium text-[#101216] dark:text-[#F1F2F3] truncate">
                  {item.label}
                  {item.badge && (
                    <span className="ml-2 font-mono text-[10px] text-[#525B68] dark:text-[#AEB7C2]">
                      · {item.badge}
                    </span>
                  )}
                </div>
                {item.sublabel && (
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] truncate">
                    {item.sublabel}
                  </div>
                )}
              </div>
              <span
                className={`font-mono tabular-nums font-medium shrink-0 ${
                  isMissing
                    ? 'text-amber-700 dark:text-amber-400 text-[11px]'
                    : 'text-[#101216] dark:text-[#F1F2F3]'
                }`}
              >
                {item.formattedValue}
              </span>
            </div>
            <div
              className={`h-2 w-full rounded-sm overflow-hidden ${
                isMissing
                  ? 'border border-dashed border-black/20 dark:border-white/20 bg-transparent'
                  : 'bg-[#E6E9ED] dark:bg-[#292E36]'
              }`}
            >
              {!isMissing && (
                <div
                  className="h-full rounded-sm transition-all duration-200"
                  style={{
                    width: `${pct}%`,
                    backgroundColor: barColor,
                    opacity: isSelected || isHovered || !selectedId ? 1 : 0.65,
                  }}
                />
              )}
            </div>
          </div>
        );

        if (!onSelect) {
          return (
            <div key={item.id} className="p-1.5 -mx-1.5 rounded-md">
              {content}
            </div>
          );
        }

        return (
          <button
            key={item.id}
            type="button"
            aria-pressed={isSelected}
            onMouseEnter={() => setHoverId(item.id)}
            onMouseLeave={() => setHoverId(null)}
            onClick={() => onSelect(isSelected ? null : item)}
            className={`w-full block p-2 rounded-md border transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#315FEA] ${
              isSelected
                ? 'border-[#315FEA] bg-[#315FEA]/[0.07]'
                : 'border-transparent hover:border-black/10 dark:hover:border-white/10 hover:bg-black/[0.02] dark:hover:bg-white/[0.02]'
            }`}
          >
            {content}
          </button>
        );
      })}
    </div>
  );
};

// Backward-compatible wrappers delegating to interactive components
export interface SeriesPoint {
  label: string;
  primary: number | null;
  secondary?: number | null;
  tertiary?: number | null;
}

export const DualLineChart: React.FC<{
  data: SeriesPoint[];
  primaryLabel: string;
  secondaryLabel?: string;
  tertiaryLabel?: string;
  formatValue: (v: number) => string;
  height?: number;
}> = ({ data, primaryLabel, secondaryLabel, tertiaryLabel, formatValue, height = 220 }) => {
  const { t } = useI18n();
  const series: InteractiveSeriesConfig[] = [
    { id: 'primary', label: primaryLabel, color: '#315FEA', areaFill: true },
    ...(secondaryLabel
      ? [{ id: 'secondary', label: secondaryLabel, color: '#10B981' }]
      : []),
    ...(tertiaryLabel
      ? [{ id: 'tertiary', label: tertiaryLabel, color: '#AEB7C2', dashed: true, isProjection: true }]
      : []),
  ];

  const points: InteractiveTimeSeriesPoint[] = data.map((d, i) => ({
    id: `legacy-${i}-${d.label}`,
    label: d.label,
    isProjection: d.primary === null && d.tertiary !== null && d.tertiary !== undefined,
    values: {
      primary: d.primary,
      secondary: d.secondary,
      tertiary: d.tertiary,
    },
  }));

  return (
    <InteractiveTimeSeriesChart
      points={points}
      series={series}
      formatValue={formatValue}
      height={height}
      ariaLabel={t('charts.timeSeriesAria', { label: primaryLabel })}
    />
  );
};

export const HorizontalBarComparison: React.FC<{
  items: Array<{
    id: string;
    label: string;
    sublabel?: string;
    value: number;
    formattedValue: string;
    color?: string;
  }>;
  selectedId?: string | null;
  onSelect?: (item: ComparisonBarItem | null) => void;
}> = ({ items, selectedId, onSelect }) => (
  <InteractiveComparisonChart items={items} selectedId={selectedId} onSelect={onSelect} />
);
