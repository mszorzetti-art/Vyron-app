import { useCallback, useMemo } from 'react';
import { CurrencyCode } from '../types/vyron';
import { useVyron } from '../context/VyronContext';
import { I18nKey } from './ptBR';
import { translate } from './translate';
import {
  formatCompactNumberForLang,
  formatCurrencyForLang,
  formatDateForLang,
  formatDateTimeForLang,
  formatIntegerForLang,
  formatNumberForLang,
  formatPercentForLang,
} from './formatters';
import { I18nParams, UiLanguage } from './types';

export function useI18n() {
  const { state } = useVyron();
  const lang: UiLanguage = state.settings.uiLanguage === 'EN-US' ? 'EN-US' : 'PT-BR';

  const t = useCallback(
    (key: I18nKey, params?: I18nParams) => translate(lang, key, params),
    [lang]
  );

  const fmtCurrency = useCallback(
    (amount: number, currency: CurrencyCode) => formatCurrencyForLang(amount, currency, lang),
    [lang]
  );

  const fmtNumber = useCallback(
    (value: number, fractionDigits = 1) => formatNumberForLang(value, lang, fractionDigits),
    [lang]
  );

  const fmtInteger = useCallback(
    (value: number) => formatIntegerForLang(value, lang),
    [lang]
  );

  const fmtCompact = useCallback(
    (value: number) => formatCompactNumberForLang(value, lang),
    [lang]
  );

  const fmtPercent = useCallback(
    (value: number, fractionDigits = 1) => formatPercentForLang(value, lang, fractionDigits),
    [lang]
  );

  const fmtDate = useCallback(
    (dateIso: string) => formatDateForLang(dateIso, lang),
    [lang]
  );

  const fmtDateTime = useCallback(
    (iso: string) => formatDateTimeForLang(iso, lang),
    [lang]
  );

  return useMemo(
    () => ({
      lang,
      t,
      fmtCurrency,
      fmtNumber,
      fmtInteger,
      fmtCompact,
      fmtPercent,
      fmtDate,
      fmtDateTime,
    }),
    [lang, t, fmtCurrency, fmtNumber, fmtInteger, fmtCompact, fmtPercent, fmtDate, fmtDateTime]
  );
}
