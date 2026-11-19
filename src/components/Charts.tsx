import React, { useState } from 'react';
import { useI18n } from '../i18n/useI18n';

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
}> = ({
  data,
  primaryLabel,
  secondaryLabel,
  tertiaryLabel,
  formatValue,
  height = 220,
}) => {
  const { t } = useI18n();
  const [hoverIdx, setHoverIdx] = useState<number | null>(null);

  if (data.length === 0) return null;

  const width = 640;
  const padL = 16;
  const padR = 16;
  const padT = 18;
  const padB = 28;
  const innerW = width - padL - padR;
  const innerH = height - padT - padB;

  const allVals = data.flatMap((d) => [
    d.primary ?? 0,
    d.secondary ?? 0,
    d.tertiary ?? 0,
  ]);
  const maxVal = Math.max(...allVals, 1) * 1.12;

  const xAt = (i: number) =>
    padL + (data.length === 1 ? innerW / 2 : (i / (data.length - 1)) * innerW);
  const yAt = (v: number) => padT + innerH - (v / maxVal) * innerH;

  const buildSegmentedPath = (getter: (d: SeriesPoint) => number | null | undefined) => {
    let path = '';
    let started = false;
    data.forEach((d, i) => {
      const v = getter(d);
      if (v === null || v === undefined) {
        started = false;
        return;
      }
      const cmd = started ? 'L' : 'M';
      path += `${cmd} ${xAt(i).toFixed(1)} ${yAt(v).toFixed(1)} `;
      started = true;
    });
    return path.trim();
  };

  const primaryPoints = data
    .map((d, i) => ({ d, i }))
    .filter((x) => x.d.primary !== null && x.d.primary !== undefined);

  const primaryPath = buildSegmentedPath((d) => d.primary);
  const areaPath =
    primaryPoints.length >= 2
      ? `${primaryPath} L ${xAt(primaryPoints[primaryPoints.length - 1].i).toFixed(1)} ${(padT + innerH).toFixed(1)} L ${xAt(primaryPoints[0].i).toFixed(1)} ${(padT + innerH).toFixed(1)} Z`
      : '';

  const secondaryPath = secondaryLabel ? buildSegmentedPath((d) => d.secondary) : '';
  const tertiaryPath = tertiaryLabel ? buildSegmentedPath((d) => d.tertiary) : '';

  const hovered = hoverIdx !== null ? data[hoverIdx] : null;

  return (
    <div className="relative">
      <div className="flex flex-wrap items-center justify-between gap-3 mb-3 text-xs">
        <div className="flex flex-wrap items-center gap-4 text-[#525B68] dark:text-[#AEB7C2]">
          <span className="inline-flex items-center gap-1.5">
            <span className="w-2.5 h-0.5 bg-[#315FEA] inline-block" />
            {primaryLabel}
          </span>
          {secondaryLabel && (
            <span className="inline-flex items-center gap-1.5">
              <span className="w-2.5 h-0.5 bg-emerald-500 inline-block" />
              {secondaryLabel}
            </span>
          )}
          {tertiaryLabel && (
            <span className="inline-flex items-center gap-1.5">
              <span className="w-2.5 h-0.5 border-b border-dashed border-[#AEB7C2] inline-block" />
              {tertiaryLabel}
            </span>
          )}
        </div>
        {hovered && (
          <div className="font-mono tabular-nums text-[11px] text-[#101216] dark:text-[#F1F2F3]">
            {hovered.label}
            {hovered.primary !== null && hovered.primary !== undefined && `: ${formatValue(hovered.primary)}`}
            {hovered.secondary !== null && hovered.secondary !== undefined && ` · ${formatValue(hovered.secondary)}`}
            {hovered.tertiary !== null &&
              hovered.tertiary !== undefined &&
              ` · ${t('charts.projectionPrefix')} ${formatValue(hovered.tertiary)}`}
          </div>
        )}
      </div>

      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="w-full h-auto overflow-visible select-none"
        role="img"
        aria-label={t('charts.timeSeriesAria', { label: primaryLabel })}
      >
        <defs>
          <linearGradient id="vyronAreaGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#315FEA" stopOpacity="0.22" />
            <stop offset="100%" stopColor="#315FEA" stopOpacity="0.0" />
          </linearGradient>
        </defs>

        {[0.25, 0.5, 0.75, 1].map((ratio) => {
          const y = padT + innerH * (1 - ratio);
          return (
            <line
              key={ratio}
              x1={padL}
              x2={width - padR}
              y1={y}
              y2={y}
              stroke="currentColor"
              className="text-black/[0.07] dark:text-white/[0.07]"
              strokeWidth="1"
            />
          );
        })}

        {areaPath && <path d={areaPath} fill="url(#vyronAreaGrad)" />}
        {primaryPath && (
          <path
            d={primaryPath}
            fill="none"
            stroke="#315FEA"
            strokeWidth="2.2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        )}
        {secondaryPath && (
          <path
            d={secondaryPath}
            fill="none"
            stroke="#10B981"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        )}
        {tertiaryPath && (
          <path
            d={tertiaryPath}
            fill="none"
            stroke="#AEB7C2"
            strokeWidth="1.8"
            strokeDasharray="4 4"
            strokeLinecap="round"
          />
        )}

        {data.map((d, i) => {
          const cx = xAt(i);
          return (
            <g key={d.label}>
              <rect
                x={cx - innerW / data.length / 2}
                y={padT}
                width={innerW / data.length}
                height={innerH}
                fill="transparent"
                onMouseEnter={() => setHoverIdx(i)}
                onMouseLeave={() => setHoverIdx(null)}
              />
              {hoverIdx === i && (
                <line
                  x1={cx}
                  x2={cx}
                  y1={padT}
                  y2={padT + innerH}
                  stroke="#315FEA"
                  strokeOpacity="0.35"
                  strokeWidth="1"
                />
              )}
              {d.primary !== null && d.primary !== undefined && (
                <circle
                  cx={cx}
                  cy={yAt(d.primary)}
                  r={hoverIdx === i ? 4.5 : 3}
                  fill="#315FEA"
                />
              )}
              {d.secondary !== null && d.secondary !== undefined && (
                <circle
                  cx={cx}
                  cy={yAt(d.secondary)}
                  r={hoverIdx === i ? 4 : 2.5}
                  fill="#10B981"
                />
              )}
              {d.tertiary !== null && d.tertiary !== undefined && (
                <circle
                  cx={cx}
                  cy={yAt(d.tertiary)}
                  r={hoverIdx === i ? 4 : 2.5}
                  fill="#AEB7C2"
                />
              )}
              <text
                x={cx}
                y={height - 6}
                textAnchor="middle"
                fontSize="10"
                className="fill-[#525B68] dark:fill-[#AEB7C2] font-mono"
              >
                {d.label}
              </text>
            </g>
          );
        })}
      </svg>
    </div>
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
}> = ({ items }) => {
  const max = Math.max(...items.map((i) => i.value), 1);
  return (
    <div className="space-y-4">
      {items.map((item) => {
        const pct = Math.max(4, Math.min(100, (item.value / max) * 100));
        return (
          <div key={item.id} className="space-y-1.5">
            <div className="flex items-start justify-between gap-3 text-xs">
              <div className="min-w-0">
                <div className="font-medium text-[#101216] dark:text-[#F1F2F3] truncate">
                  {item.label}
                </div>
                {item.sublabel && (
                  <div className="text-[11px] text-[#525B68] dark:text-[#AEB7C2] truncate">
                    {item.sublabel}
                  </div>
                )}
              </div>
              <span className="font-mono tabular-nums font-medium text-[#101216] dark:text-[#F1F2F3] shrink-0">
                {item.formattedValue}
              </span>
            </div>
            <div className="h-2 w-full rounded-sm bg-[#E6E9ED] dark:bg-[#292E36] overflow-hidden">
              <div
                className="h-full rounded-sm"
                style={{
                  width: `${pct}%`,
                  backgroundColor: item.color ?? '#315FEA',
                }}
              />
            </div>
          </div>
        );
      })}
    </div>
  );
};
