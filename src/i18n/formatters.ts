import { CurrencyCode } from '../types/vyron';
import { UiLanguage } from './types';

export function getIntlLocale(lang: UiLanguage): 'pt-BR' | 'en-US' {
  return lang === 'EN-US' ? 'en-US' : 'pt-BR';
}

/**
 * Formats monetary amounts using the user's selected UI language for decimal/thousand
 * separators while strictly preserving the monetary currency symbol and value (no FX conversion).
 */
export function formatCurrencyForLang(
  amount: number,
  currency: CurrencyCode,
  lang: UiLanguage = 'PT-BR'
): string {
  return new Intl.NumberFormat(getIntlLocale(lang), {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

export function formatNumberForLang(
  value: number,
  lang: UiLanguage = 'PT-BR',
  fractionDigits = 1
): string {
  return new Intl.NumberFormat(getIntlLocale(lang), {
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  }).format(value);
}

export function formatIntegerForLang(
  value: number,
  lang: UiLanguage = 'PT-BR'
): string {
  return new Intl.NumberFormat(getIntlLocale(lang), {
    maximumFractionDigits: 0,
  }).format(value);
}

export function formatPercentForLang(
  value: number,
  lang: UiLanguage = 'PT-BR',
  fractionDigits = 1
): string {
  return `${formatNumberForLang(value, lang, fractionDigits)}%`;
}

export function formatCompactNumberForLang(
  value: number,
  lang: UiLanguage = 'PT-BR'
): string {
  const abs = Math.abs(value);
  if (abs >= 1_000_000) {
    return `${formatNumberForLang(value / 1_000_000, lang, 1)}M`;
  }
  if (abs >= 1_000) {
    return `${formatNumberForLang(value / 1_000, lang, 1)}K`;
  }
  return formatIntegerForLang(value, lang);
}

function parseIsoParts(input: string): {
  year: string;
  month: string;
  day: string;
  hour?: string;
  minute?: string;
} | null {
  const trimmed = input.trim();
  const dateOnly = /^(\d{4})-(\d{2})-(\d{2})$/.exec(trimmed);
  if (dateOnly) {
    return {
      year: dateOnly[1],
      month: dateOnly[2],
      day: dateOnly[3],
    };
  }
  const isoMatch = /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})/.exec(trimmed);
  if (isoMatch) {
    return {
      year: isoMatch[1],
      month: isoMatch[2],
      day: isoMatch[3],
      hour: isoMatch[4],
      minute: isoMatch[5],
    };
  }
  const parsed = new Date(trimmed);
  if (Number.isNaN(parsed.getTime())) return null;
  return {
    year: String(parsed.getUTCFullYear()),
    month: String(parsed.getUTCMonth() + 1).padStart(2, '0'),
    day: String(parsed.getUTCDate()).padStart(2, '0'),
    hour: String(parsed.getUTCHours()).padStart(2, '0'),
    minute: String(parsed.getUTCMinutes()).padStart(2, '0'),
  };
}

/**
 * Formats calendar dates strictly per regional convention without shifting days across timezones:
 * - PT-BR: DD/MM/YYYY
 * - EN-US: MM/DD/YYYY
 */
export function formatDateForLang(
  isoOrYmd: string,
  lang: UiLanguage = 'PT-BR'
): string {
  if (!isoOrYmd) return '-';
  const parts = parseIsoParts(isoOrYmd);
  if (!parts) return isoOrYmd;
  if (lang === 'EN-US') {
    return `${parts.month}/${parts.day}/${parts.year}`;
  }
  return `${parts.day}/${parts.month}/${parts.year}`;
}

export function formatDateTimeForLang(
  iso: string,
  lang: UiLanguage = 'PT-BR'
): string {
  if (!iso) return '-';
  const parts = parseIsoParts(iso);
  if (!parts) return iso;
  const datePart =
    lang === 'EN-US'
      ? `${parts.month}/${parts.day}/${parts.year}`
      : `${parts.day}/${parts.month}/${parts.year}`;
  if (parts.hour !== undefined && parts.minute !== undefined) {
    return `${datePart} ${parts.hour}:${parts.minute}`;
  }
  return datePart;
}
