import React from 'react';

interface VyronMarkProps {
  size?: number;
  variant?: 'cobalt' | 'white' | 'obsidian';
  className?: string;
}

/**
 * Official Vyron geometric symbol faithfully constructed from the brand sheet:
 * Left thick diagonal V-wing + right folded hook wing separated by a precise diagonal channel.
 */
export const VyronMark: React.FC<VyronMarkProps> = ({
  size = 28,
  variant = 'cobalt',
  className = '',
}) => {
  const gradId = React.useId();

  return (
    <svg
      width={size}
      height={Math.round(size * 0.72)}
      viewBox="0 0 100 72"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-hidden="true"
    >
      <defs>
        <linearGradient id={gradId} x1="8" y1="6" x2="92" y2="68" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor="#3B6BFF" />
          <stop offset="55%" stopColor="#315FEA" />
          <stop offset="100%" stopColor="#1D44C4" />
        </linearGradient>
      </defs>
      {/* Left Wing */}
      <path
        d="M4 6H31.5L51.5 40.5L39.2 66L4 6Z"
        fill={
          variant === 'cobalt'
            ? `url(#${gradId})`
            : variant === 'white'
            ? '#F1F2F3'
            : '#101216'
        }
      />
      {/* Right Upper Hooked Wing */}
      <path
        d="M55.5 6H96L86.8 22H63.5L52.8 40.5L45.2 27.4L55.5 6Z"
        fill={
          variant === 'cobalt'
            ? `url(#${gradId})`
            : variant === 'white'
            ? '#F1F2F3'
            : '#101216'
        }
      />
      {/* Right Lower Diagonal Fold */}
      <path
        d="M65.8 27H84.2L60.2 66H44.5L65.8 27Z"
        fill={
          variant === 'cobalt'
            ? `url(#${gradId})`
            : variant === 'white'
            ? '#F1F2F3'
            : '#101216'
        }
      />
    </svg>
  );
};

export const VyronWordmark: React.FC<{
  showMark?: boolean;
  markSize?: number;
  className?: string;
}> = ({ showMark = true, markSize = 26, className = '' }) => {
  return (
    <div className={`inline-flex items-center gap-3 select-none ${className}`}>
      {showMark && <VyronMark size={markSize} variant="cobalt" />}
      <span
        className="font-display font-semibold tracking-[0.32em] text-[15px] text-[#101216] dark:text-[#F1F2F3] uppercase whitespace-nowrap"
      >
        VYRON
      </span>
    </div>
  );
};
