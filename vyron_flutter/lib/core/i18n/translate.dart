import '../../domain/models/vyron_enums.dart';
import 'en_us.dart';
import 'pt_br.dart';

Map<String, String> getDictionary(UiLanguage lang) =>
    lang == UiLanguage.enUS ? enUS : ptBR;

String translate(UiLanguage lang, String key, [Map<String, Object?>? params]) {
  final dict = getDictionary(lang);
  var text = dict[key] ?? ptBR[key] ?? key;
  if (params != null && params.isNotEmpty) {
    for (final entry in params.entries) {
      text = text.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
    }
  }
  return text;
}

class DictionaryParityReport {
  const DictionaryParityReport({
    required this.missingInEn,
    required this.extraInEn,
    required this.placeholderMismatches,
    required this.emptyValues,
  });

  final List<String> missingInEn;
  final List<String> extraInEn;
  final List<String> placeholderMismatches;
  final List<String> emptyValues;

  bool get isClean =>
      missingInEn.isEmpty &&
      extraInEn.isEmpty &&
      placeholderMismatches.isEmpty &&
      emptyValues.isEmpty;
}

DictionaryParityReport validateDictionaryParity() {
  final ptKeys = ptBR.keys.toList();
  final enKeys = enUS.keys.toList();
  final ptSet = ptKeys.toSet();
  final enSet = enKeys.toSet();

  final missingInEn = ptKeys.where((k) => !enSet.contains(k)).toList();
  final extraInEn = enKeys.where((k) => !ptSet.contains(k)).toList();

  final placeholderRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');
  List<String> extractPlaceholders(String s) {
    final set = <String>{};
    for (final match in placeholderRegex.allMatches(s)) {
      final group = match.group(1);
      if (group != null) set.add(group);
    }
    return set.toList()..sort();
  }

  final placeholderMismatches = <String>[];
  final emptyValues = <String>[];

  for (final key in ptKeys) {
    final ptVal = ptBR[key];
    final enVal = enUS[key];
    if (ptVal == null || ptVal.trim().isEmpty) {
      emptyValues.add('ptBR:$key');
    }
    if (enVal == null || enVal.trim().isEmpty) {
      emptyValues.add('enUS:$key');
      continue;
    }
    if (ptVal != null) {
      final p1 = extractPlaceholders(ptVal).join(',');
      final p2 = extractPlaceholders(enVal).join(',');
      if (p1 != p2) {
        placeholderMismatches.add('$key (pt:[$p1] vs en:[$p2])');
      }
    }
  }

  return DictionaryParityReport(
    missingInEn: missingInEn,
    extraInEn: extraInEn,
    placeholderMismatches: placeholderMismatches,
    emptyValues: emptyValues,
  );
}
