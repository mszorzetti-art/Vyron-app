import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/core/crypto/vyron_crypto.dart';
import 'package:vyron/data/seed_data.dart';
import 'package:vyron/domain/charts/chart_series.dart';
import 'package:vyron/domain/models/brand_product_models.dart';
import 'package:vyron/domain/models/vyron_enums.dart';
import 'package:vyron/domain/rules/vyron_rules.dart';

void main() {
  group('Lote 3 — Seed Data oficial & integridade de domínio', () {
    test(
      'reproduz exatamente contagens e identidade do estado seed oficial',
      () {
        final seed = buildInitialVyronState();

        expect(seed.brands.length, 4);
        expect(seed.products.length, 10);
        expect(seed.channels.length, 8);
        expect(seed.contents.length, 8);
        expect(seed.financeEntries.length, 14);
        expect(seed.automations.length, 6);
        expect(seed.jobRuns.length, 4);
        expect(seed.risks.length, 9);
        expect(seed.activities.length, 7);
        expect(seed.notifications.length, 4);

        expect(seed.settings.ownerName, OwnerProfile.name);
        expect(seed.settings.ownerEmail, OwnerProfile.email);
        expect(seed.settings.integrations.length, 7);
        expect(seed.systemControl.state, SystemControlStatus.active);
        expect(seed.systemControl.publishingEnabled, isFalse);
        expect(seed.systemControl.phaseBPublicAllowed, isFalse);
      },
    );

    test('calcula hashes SHA-256 idênticos nas peças seed autorizadas', () {
      final seed = buildInitialVyronState();
      final cnt1 = seed.contents.firstWhere((c) => c.id == 'cnt-1');
      final cnt3 = seed.contents.firstWhere((c) => c.id == 'cnt-3');
      final cnt4 = seed.contents.firstWhere((c) => c.id == 'cnt-4');

      expect(cnt1.currentManifestHash.length, 64);
      expect(cnt1.currentManifestHash, computeContentItemManifestHash(cnt1));
      expect(cnt1.authorization?.authorizedHash, cnt1.currentManifestHash);
      expect(cnt4.authorization?.authorizedHash, cnt4.currentManifestHash);
      expect(cnt3.authorization?.authorizedHash, cnt3.currentManifestHash);

      // Em Fase A com publicação habilitada, cnt-3 (unlisted) passa todas as 6 travas
      final preSendCnt3 = evaluateContentPreSendChecks(
        cnt3,
        seed.systemControl.copyWith(publishingEnabled: true),
        nowIso: '2026-11-18T18:00:00Z',
        evidenceFreshnessMaxHours: 48,
      );
      expect(preSendCnt3.canSend, isTrue);

      // cnt-1 (public) exige phaseBPublicAllowed = true mesmo com link recente
      final preSendCnt1PhaseA = evaluateContentPreSendChecks(
        cnt1,
        seed.systemControl.copyWith(publishingEnabled: true),
        nowIso: '2026-11-08T18:00:00Z',
        evidenceFreshnessMaxHours: 48,
      );
      expect(preSendCnt1PhaseA.canSend, isFalse);

      final preSendCnt1PhaseB = evaluateContentPreSendChecks(
        cnt1,
        seed.systemControl.copyWith(
          publishingEnabled: true,
          phaseBPublicAllowed: true,
        ),
        nowIso: '2026-11-08T18:00:00Z',
        evidenceFreshnessMaxHours: 48,
      );
      expect(preSendCnt1PhaseB.canSend, isTrue);
    });

    test('preserva campos nulos explícitos e isola registros isTest', () {
      final seed = buildInitialVyronState();
      final unknown = seed.products.firstWhere(
        (p) => p.id == 'prod-unknown-epc',
      );

      expect(unknown.epcValue, isNull);
      expect(unknown.cookieWindowDays, isNull);
      expect(unknown.opportunityScore, isNull);

      final scoreRes = scoreProductV61(unknown);
      expect(scoreRes.score, isNull);
      expect(scoreRes.missingCriticalFields, contains('EPC'));

      final realSummary = calculateFinanceSummary(
        seed.financeEntries,
        CurrencyCode.brl,
        excludeTest: true,
      );
      final withTestSummary = calculateFinanceSummary(
        seed.financeEntries,
        CurrencyCode.brl,
        excludeTest: false,
      );
      expect(
        withTestSummary.receivedCashIn - realSummary.receivedCashIn,
        closeTo(15000.0, 0.01),
      );
    });

    test(
      'gera séries de gráficos sobre o estado seed sem coerção ou mistura FX',
      () {
        final seed = buildInitialVyronState();

        final overview30 = buildOverviewFinanceSeries(
          seed.financeEntries,
          CurrencyCode.brl,
          range: ChartTimeRange.d30,
          excludeTest: true,
          includeProjection: true,
        );
        final realPoints = overview30.points
            .where((p) => !p.isProjection)
            .toList();
        expect(
          realPoints.any((p) => p.entryIds.contains('fin-test-1')),
          isFalse,
        );
        expect(overview30.points.last.isProjection, isTrue);

        final analytics30 = buildAnalyticsContentPoints(
          seed.contents,
          CurrencyCode.brl,
          range: ChartTimeRange.d30,
        );
        expect(analytics30.items.length, 2);
        expect(analytics30.items.map((e) => e.contentId), ['cnt-1', 'cnt-4']);

        final eurRanking = buildProductNativeCurrencyComparison(
          seed.products,
          CurrencyCode.eur,
          ProductChartMetric.opportunityScore,
          excludeTest: true,
        );
        expect(eurRanking.length, 2);
        expect(eurRanking.first.product.id, 'prod-izotope-rx');
        expect(eurRanking.last.product.id, 'prod-unknown-epc');
        expect(eurRanking.last.missingData, isTrue);
        expect(eurRanking.last.value, isNull);
      },
    );
  });
}
