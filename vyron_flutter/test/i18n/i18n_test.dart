import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/core/i18n/domain_labels.dart';
import 'package:vyron/core/i18n/en_us.dart';
import 'package:vyron/core/i18n/formatters.dart';
import 'package:vyron/core/i18n/pt_br.dart';
import 'package:vyron/core/i18n/seed_translations.dart';
import 'package:vyron/core/i18n/translate.dart';
import 'package:vyron/domain/models/content_channel_finance_models.dart';
import 'package:vyron/domain/models/vyron_enums.dart';

void main() {
  group('Lote 2 — Internacionalização (PT-BR / EN-US) e Formatadores', () {
    test(
      'dicionários PT-BR e EN-US possuem 872 chaves com 100% de paridade e placeholders idênticos',
      () {
        expect(ptBR.length, 872);
        expect(enUS.length, 872);

        final parity = validateDictionaryParity();
        expect(parity.missingInEn, isEmpty);
        expect(parity.extraInEn, isEmpty);
        expect(parity.placeholderMismatches, isEmpty);
        expect(parity.emptyValues, isEmpty);
      },
    );

    test(
      'dicionários cotidianos da UI não vazam identificadores técnicos internos',
      () {
        const forbidden = <String>[
          'system_controls',
          'job_runs',
          'audit_log',
          'PUBLISHING_ENABLED',
          'RISK_REGISTER',
          'score-6.1',
          'source_commit',
          'is_test',
        ];

        for (final entry in <(String, Map<String, String>)>[
          ('PT-BR', ptBR),
          ('EN-US', enUS),
        ]) {
          final langName = entry.$1;
          final dict = entry.$2;
          for (final kv in dict.entries) {
            for (final token in forbidden) {
              expect(
                kv.value.contains(token),
                isFalse,
                reason:
                    'Forbidden identifier "$token" leaked in $langName key "${kv.key}": ${kv.value}',
              );
            }
          }
        }
      },
    );

    test('rótulos de domínio seguem terminologia oficial PT-BR e EN-US', () {
      expect(
        labelContentStatus(ContentStatus.brief, UiLanguage.ptBR),
        'Planejamento de conteúdo',
      );
      expect(
        labelContentStatus(ContentStatus.draft, UiLanguage.ptBR),
        'Rascunho',
      );
      expect(
        labelContentStatus(ContentStatus.inReview, UiLanguage.ptBR),
        'Em revisão',
      );
      expect(
        labelContentStatus(ContentStatus.approved, UiLanguage.ptBR),
        'Aprovado',
      );
      expect(
        labelContentStatus(ContentStatus.published, UiLanguage.ptBR),
        'Publicado',
      );
      expect(
        labelContentStatus(ContentStatus.rejected, UiLanguage.ptBR),
        'Rejeitado',
      );

      expect(
        labelContentStatus(ContentStatus.brief, UiLanguage.enUS),
        'Content Plan',
      );
      expect(
        labelContentStatus(ContentStatus.draft, UiLanguage.enUS),
        'Draft',
      );
      expect(
        labelContentStatus(ContentStatus.inReview, UiLanguage.enUS),
        'In Review',
      );

      expect(
        labelCommissionStage(CommissionStage.pending, UiLanguage.ptBR),
        'Pendente',
      );
      expect(
        labelCommissionStage(CommissionStage.confirmed, UiLanguage.ptBR),
        'Confirmado',
      );
      expect(
        labelCommissionStage(CommissionStage.received, UiLanguage.ptBR),
        'Recebido',
      );

      expect(
        labelRiskStatus(RiskStatus.mitigadoDemo, UiLanguage.ptBR),
        'Mitigado no protótipo',
      );
      expect(
        labelRiskStatus(RiskStatus.pendenteInfra, UiLanguage.ptBR),
        'Infraestrutura pendente',
      );
    });

    test(
      'formatação regional de datas, números e moedas segue idioma sem converter moeda',
      () {
        expect(formatDateForLang('2026-11-18', UiLanguage.ptBR), '18/11/2026');
        expect(formatDateForLang('2026-11-18', UiLanguage.enUS), '11/18/2026');
        expect(
          formatDateTimeForLang('2026-11-18T14:30:00Z', UiLanguage.ptBR),
          '18/11/2026 14:30',
        );
        expect(
          formatDateTimeForLang('2026-11-18T14:30:00Z', UiLanguage.enUS),
          '11/18/2026 14:30',
        );

        expect(formatNumberForLang(1234.5, UiLanguage.ptBR, 1), '1.234,5');
        expect(formatNumberForLang(1234.5, UiLanguage.enUS, 1), '1,234.5');

        expect(formatCompactNumberForLang(1500, UiLanguage.ptBR), '1,5K');
        expect(formatCompactNumberForLang(1500, UiLanguage.enUS), '1.5K');

        expect(
          formatCurrencyForLang(1234.5, CurrencyCode.brl, UiLanguage.ptBR),
          r'R$ 1.234,50',
        );
        expect(
          formatCurrencyForLang(1234.5, CurrencyCode.brl, UiLanguage.enUS),
          r'R$1,234.50',
        );
        expect(
          formatCurrencyForLang(1234.5, CurrencyCode.usd, UiLanguage.ptBR),
          r'US$ 1.234,50',
        );
        expect(
          formatCurrencyForLang(1234.5, CurrencyCode.usd, UiLanguage.enUS),
          r'$1,234.50',
        );
        expect(
          formatCurrencyForLang(-1234.5, CurrencyCode.eur, UiLanguage.ptBR),
          '-€ 1.234,50',
        );
        expect(
          formatCurrencyForLang(-1234.5, CurrencyCode.eur, UiLanguage.enUS),
          '-€1,234.50',
        );

        expect(translate(UiLanguage.enUS, 'controls.stopAll'), 'STOP ALL');
        expect(
          translate(UiLanguage.ptBR, 'controls.title'),
          'CONTROLES DO SISTEMA',
        );
        expect(
          translate(
            UiLanguage.ptBR,
            'nav.notificationsAria',
            {'count': 3},
          ),
          'Notificações (3 não lidas)',
        );
      },
    );

    test('seedTranslations traduz registros seed e preserva edições do usuário',
        () {
      expect(localizeActor('Proprietário', UiLanguage.enUS), 'Owner');
      expect(localizeActor('Owner', UiLanguage.ptBR), 'Proprietário');

      expect(
        txSeed(
          UiLanguage.enUS,
          'Texto original',
          'Original text',
          'Texto editado pelo usuário',
        ),
        'Texto editado pelo usuário',
      );
      expect(
        txSeed(
          UiLanguage.enUS,
          'Texto original',
          'Original text',
          'Texto original',
        ),
        'Original text',
      );

      const testFin = FinanceEntry(
        id: 'fin-test-1',
        brandId: 'brand-apex',
        platform: 'Sandbox QA',
        description: '[TESTE] Lançamento sintético de validação is_test',
        type: FinanceEntryType.commission,
        stage: CommissionStage.received,
        amount: 15000,
        currency: CurrencyCode.brl,
        date: '2026-11-14',
        isTest: true,
      );
      final cleanedPt = localizeFinanceEntry(testFin, UiLanguage.ptBR);
      expect(cleanedPt.description.contains('is_test'), isFalse);
      final localizedEn = localizeFinanceEntry(testFin, UiLanguage.enUS);
      expect(
        localizedEn.description,
        '[TEST] Synthetic test-record validation entry',
      );
    },);
  });
}
