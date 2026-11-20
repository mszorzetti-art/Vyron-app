import '../../domain/models/vyron_enums.dart';

String getIntlLocale(UiLanguage lang) =>
    lang == UiLanguage.enUS ? 'en-US' : 'pt-BR';

String _formatPositiveGrouped(
  double absValue,
  UiLanguage lang,
  int fractionDigits,
) {
  final fixed = absValue.toStringAsFixed(fractionDigits);
  final dotIdx = fixed.indexOf('.');
  final intPart = dotIdx >= 0 ? fixed.substring(0, dotIdx) : fixed;
  final fracPart = dotIdx >= 0 ? fixed.substring(dotIdx + 1) : '';

  final thousandSep = lang == UiLanguage.enUS ? ',' : '.';
  final decimalSep = lang == UiLanguage.enUS ? '.' : ',';

  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final remaining = intPart.length - i;
    if (i > 0 && remaining % 3 == 0) {
      buf.write(thousandSep);
    }
    buf.write(intPart[i]);
  }

  if (fractionDigits > 0) {
    buf.write(decimalSep);
    buf.write(fracPart);
  }
  return buf.toString();
}

/// Formats monetary amounts using the user's selected UI language for decimal/thousand
/// separators while strictly preserving the monetary currency symbol and value (no FX conversion).
String formatCurrencyForLang(
  double amount,
  CurrencyCode currency, [
  UiLanguage lang = UiLanguage.ptBR,
]) {
  final roundedZero = double.parse(amount.toStringAsFixed(2)) == 0.0;
  final isNegative = !roundedZero && amount < 0;
  final formatted = _formatPositiveGrouped(
    roundedZero ? 0.0 : amount.abs(),
    lang,
    2,
  );

  final prefix = switch ((lang, currency)) {
    (UiLanguage.ptBR, CurrencyCode.brl) => r'R$ ',
    (UiLanguage.ptBR, CurrencyCode.usd) => r'US$ ',
    (UiLanguage.ptBR, CurrencyCode.eur) => '€ ',
    (UiLanguage.enUS, CurrencyCode.brl) => r'R$',
    (UiLanguage.enUS, CurrencyCode.usd) => r'$',
    (UiLanguage.enUS, CurrencyCode.eur) => '€',
  };

  return '${isNegative ? '-' : ''}$prefix$formatted';
}

String formatNumberForLang(
  double value, [
  UiLanguage lang = UiLanguage.ptBR,
  int fractionDigits = 1,
]) {
  final normalized =
      double.parse(value.toStringAsFixed(fractionDigits)) == 0.0 ? 0.0 : value;
  final isNegative = normalized < 0;
  final formatted = _formatPositiveGrouped(
    normalized.abs(),
    lang,
    fractionDigits,
  );
  return '${isNegative ? '-' : ''}$formatted';
}

String formatIntegerForLang(
  num value, [
  UiLanguage lang = UiLanguage.ptBR,
]) {
  final rounded = value.round();
  final isNegative = rounded < 0;
  final formatted = _formatPositiveGrouped(
    rounded.abs().toDouble(),
    lang,
    0,
  );
  return '${isNegative ? '-' : ''}$formatted';
}

String formatPercentForLang(
  double value, [
  UiLanguage lang = UiLanguage.ptBR,
  int fractionDigits = 1,
]) {
  return '${formatNumberForLang(value, lang, fractionDigits)}%';
}

String formatCompactNumberForLang(
  num value, [
  UiLanguage lang = UiLanguage.ptBR,
]) {
  final abs = value.abs();
  if (abs >= 1000000) {
    return '${formatNumberForLang(value / 1000000.0, lang, 1)}M';
  }
  if (abs >= 1000) {
    return '${formatNumberForLang(value / 1000.0, lang, 1)}K';
  }
  return formatIntegerForLang(value, lang);
}

class _DateParts {
  const _DateParts({
    required this.year,
    required this.month,
    required this.day,
    this.hour,
    this.minute,
  });

  final String year;
  final String month;
  final String day;
  final String? hour;
  final String? minute;
}

final RegExp _dateOnlyRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final RegExp _isoMatchRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})');

_DateParts? _parseIsoParts(String input) {
  final trimmed = input.trim();
  final dateOnly = _dateOnlyRegex.firstMatch(trimmed);
  if (dateOnly != null) {
    return _DateParts(
      year: dateOnly.group(1)!,
      month: dateOnly.group(2)!,
      day: dateOnly.group(3)!,
    );
  }
  final isoMatch = _isoMatchRegex.firstMatch(trimmed);
  if (isoMatch != null) {
    return _DateParts(
      year: isoMatch.group(1)!,
      month: isoMatch.group(2)!,
      day: isoMatch.group(3)!,
      hour: isoMatch.group(4),
      minute: isoMatch.group(5),
    );
  }
  final parsed = DateTime.tryParse(trimmed)?.toUtc();
  if (parsed == null) return null;
  return _DateParts(
    year: parsed.year.toString(),
    month: parsed.month.toString().padLeft(2, '0'),
    day: parsed.day.toString().padLeft(2, '0'),
    hour: parsed.hour.toString().padLeft(2, '0'),
    minute: parsed.minute.toString().padLeft(2, '0'),
  );
}

/// Formats calendar dates strictly per regional convention without shifting days across timezones:
/// - PT-BR: DD/MM/YYYY
/// - EN-US: MM/DD/YYYY
String formatDateForLang(
  String isoOrYmd, [
  UiLanguage lang = UiLanguage.ptBR,
]) {
  if (isoOrYmd.isEmpty) return '-';
  final parts = _parseIsoParts(isoOrYmd);
  if (parts == null) return isoOrYmd;
  if (lang == UiLanguage.enUS) {
    return '${parts.month}/${parts.day}/${parts.year}';
  }
  return '${parts.day}/${parts.month}/${parts.year}';
}

String formatDateTimeForLang(
  String iso, [
  UiLanguage lang = UiLanguage.ptBR,
]) {
  if (iso.isEmpty) return '-';
  final parts = _parseIsoParts(iso);
  if (parts == null) return iso;
  final datePart = lang == UiLanguage.enUS
      ? '${parts.month}/${parts.day}/${parts.year}'
      : '${parts.day}/${parts.month}/${parts.year}';
  if (parts.hour != null && parts.minute != null) {
    return '$datePart ${parts.hour}:${parts.minute}';
  }
  return datePart;
}
