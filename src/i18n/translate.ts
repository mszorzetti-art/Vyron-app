import { I18nParams, UiLanguage } from './types';
import { I18nKey, ptBR } from './ptBR';
import { enUS } from './enUS';

export function getDictionary(lang: UiLanguage): Record<I18nKey, string> {
  return lang === 'EN-US' ? enUS : ptBR;
}

export function translate(
  lang: UiLanguage,
  key: I18nKey,
  params?: I18nParams
): string {
  const dict = getDictionary(lang);
  let text: string = dict[key] ?? ptBR[key] ?? String(key);
  if (params) {
    for (const [paramKey, paramValue] of Object.entries(params)) {
      text = text.replace(new RegExp(`\\{${paramKey}\\}`, 'g'), String(paramValue));
    }
  }
  return text;
}

export function validateDictionaryParity(): {
  missingInEn: string[];
  extraInEn: string[];
  placeholderMismatches: string[];
  emptyValues: string[];
} {
  const ptKeys = Object.keys(ptBR) as I18nKey[];
  const enKeys = Object.keys(enUS);
  const ptSet = new Set<string>(ptKeys);
  const enSet = new Set<string>(enKeys);

  const missingInEn = ptKeys.filter((k) => !enSet.has(k));
  const extraInEn = enKeys.filter((k) => !ptSet.has(k));

  const extractPlaceholders = (s: string) =>
    Array.from(new Set(Array.from(s.matchAll(/\{([a-zA-Z0-9_]+)\}/g), (m) => m[1]))).sort();

  const placeholderMismatches: string[] = [];
  const emptyValues: string[] = [];

  for (const key of ptKeys) {
    const ptVal = ptBR[key];
    const enVal = enUS[key];
    if (!ptVal || ptVal.trim().length === 0) emptyValues.push(`ptBR:${key}`);
    if (!enVal || enVal.trim().length === 0) {
      emptyValues.push(`enUS:${key}`);
      continue;
    }
    const p1 = extractPlaceholders(ptVal);
    const p2 = extractPlaceholders(enVal);
    if (p1.join(',') !== p2.join(',')) {
      placeholderMismatches.push(`${key} (pt:[${p1.join(',')}] vs en:[${p2.join(',')}])`);
    }
  }

  return { missingInEn, extraInEn, placeholderMismatches, emptyValues };
}
