import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/domain/charts/chart_series.dart';
import 'package:vyron/domain/models/brand_product_models.dart';
import 'package:vyron/domain/models/content_channel_finance_models.dart';
import 'package:vyron/domain/models/vyron_enums.dart';

const List<FinanceEntry> _financeFixtures = [
  FinanceEntry(
    id: 'fin-1',
    brandId: 'brand-apex',
    productId: 'prod-keychron-q1',
    platform: 'Amazon Associates BR',
    description: 'Repasse liquidado',
    type: FinanceEntryType.commission,
    stage: CommissionStage.received,
    amount: 9420.5,
    currency: CurrencyCode.brl,
    date: '2026-11-05',
  ),
  FinanceEntry(
    id: 'fin-2',
    brandId: 'brand-nordic',
    productId: 'prod-benq-halo',
    platform: 'Impact / BenQ Direct',
    description: 'Payout USD',
    type: FinanceEntryType.commission,
    stage: CommissionStage.received,
    amount: 2480.0,
    currency: CurrencyCode.usd,
    date: '2026-11-07',
  ),
  FinanceEntry(
    id: 'fin-5',
    brandId: 'brand-apex',
    productId: 'prod-dell-oled',
    platform: 'Dell Affiliate Program',
    description: 'Conversões confirmadas',
    type: FinanceEntryType.commission,
    stage: CommissionStage.confirmed,
    amount: 5790.0,
    currency: CurrencyCode.brl,
    date: '2026-11-15',
  ),
  FinanceEntry(
    id: 'fin-8',
    brandId: 'brand-nordic',
    productId: 'prod-benq-halo',
    platform: 'Impact / BenQ Direct',
    description: 'Cliques aguardando validação',
    type: FinanceEntryType.commission,
    stage: CommissionStage.pending,
    amount: 1350.0,
    currency: CurrencyCode.usd,
    date: '2026-11-18',
  ),
  FinanceEntry(
    id: 'fin-9',
    brandId: 'brand-apex',
    platform: 'Infra & Estúdio',
    description: 'Edição técnica e captação',
    type: FinanceEntryType.expense,
    stage: CommissionStage.received,
    amount: 3200.0,
    currency: CurrencyCode.brl,
    date: '2026-11-04',
  ),
  FinanceEntry(
    id: 'fin-10',
    brandId: 'brand-nordic',
    platform: 'Cloud & Ferramentas',
    description: 'Hospedagem CDN',
    type: FinanceEntryType.expense,
    stage: CommissionStage.received,
    amount: 210.0,
    currency: CurrencyCode.usd,
    date: '2026-11-06',
  ),
  FinanceEntry(
    id: 'fin-12',
    brandId: 'brand-apex',
    platform: 'Modelo Conservador',
    description: 'Projeção Dezembro',
    type: FinanceEntryType.commission,
    stage: CommissionStage.pending,
    amount: 18500.0,
    currency: CurrencyCode.brl,
    date: '2026-12-15',
    isProjection: true,
  ),
  FinanceEntry(
    id: 'fin-13',
    brandId: 'brand-nordic',
    platform: 'Modelo Conservador',
    description: 'Projeção Q4 EUA/EU',
    type: FinanceEntryType.commission,
    stage: CommissionStage.pending,
    amount: 4600.0,
    currency: CurrencyCode.usd,
    date: '2026-12-15',
    isProjection: true,
  ),
  FinanceEntry(
    id: 'fin-test-1',
    brandId: 'brand-apex',
    platform: 'Sandbox QA',
    description: '[TESTE] Lançamento is_test',
    type: FinanceEntryType.commission,
    stage: CommissionStage.received,
    amount: 15000.0,
    currency: CurrencyCode.brl,
    date: '2026-11-14',
    isTest: true,
  ),
];

ContentItem _makePublishedContent({
  required String id,
  required String publishedAt,
  required String brandId,
  required String channelId,
  required int views,
  required int clicks,
  required double revenue,
  required CurrencyCode currency,
}) {
  return ContentItem(
    id: id,
    brandId: brandId,
    channelId: channelId,
    title: 'Item $id',
    description: 'Descrição',
    format: ContentFormat.longForm,
    category: ContentCategory.comercialContextual,
    visibility: ContentVisibility.publicVis,
    analysisMethod: AnalysisMethod.testeProprio,
    sensitiveTopic: SensitiveTopic.nenhum,
    unclassifiedRiskFlag: false,
    status: ContentStatus.published,
    scheduledDate: publishedAt,
    publishedAt: publishedAt,
    brief: 'Brief',
    angleIdea: 'Ângulo',
    script: 'Roteiro',
    affiliateLinkUrl: 'https://vyron.internal/go',
    verifiedDestinationUrl: 'https://vyron.internal/dest',
    linkVerifiedAt: '2026-11-10T10:00:00Z',
    commercialConditionsVerifiedAt: '2026-11-10T10:00:00Z',
    affiliateDisclosure: 'Divulgação padrão',
    aiDisclosureRequired: false,
    aiDisclosureText: '',
    relevanceTestPassed: true,
    editorialChecklistPassed: true,
    humanHoursLogged: 8.0,
    dossier: const [],
    references: const [],
    currentManifestHash: 'hash-$id',
    authorization: null,
    versions: const [],
    metrics: ContentMetrics(
      views: views,
      retention30sPct: 71.4,
      avgViewPct: 54.2,
      clicks: clicks,
      conversions: 40,
      revenueGenerated: revenue,
      currency: currency,
      trackingSrc: 'src_$id',
      attributionStatus: AttributionStatus.estimativaEmInvestigacao,
    ),
  );
}

Product _makeProductFixture({
  required String id,
  required CurrencyCode currency,
  required int? score,
  double? epcValue = 1.5,
  bool isTest = false,
}) {
  return Product(
    id: id,
    externalId: 'EXT-$id',
    brandId: 'brand-nordic',
    linkedBrandIds: const ['brand-nordic'],
    isTest: isTest,
    name: 'Produto $id',
    category: 'Hardware',
    platform: 'Awin',
    remunerationModel: RemunerationModel.revShare,
    price: 499,
    currency: currency,
    commissionRatePct: 7.5,
    cpaValue: null,
    epcValue: epcValue,
    cookieWindowDays: 30,
    opportunityScore: score,
    dataConfidence: DataConfidence.alta,
    qualityGrade: ProductQualityGrade.b,
    complianceState: ComplianceState.approved,
    complianceMarket: 'França / UE',
    demandTrendPct: 12,
    competitionLevel: CompetitionLevel.media,
    status: ProductStatus.candidate,
    evidence: const [],
    decisions: const [],
    updatedAt: '2026-11-18T11:20:00Z',
  );
}

void main() {
  group('Lote 1 — Séries de Gráficos (ChartSeries)', () {
    test('resolveTimeWindow calcula intervalos 7d e custom de forma determinística',
        () {
      final w7 = resolveTimeWindow(ChartTimeRange.d7);
      expect(w7.startDate, '2026-11-12');
      expect(w7.endDate, '2026-11-18');
      expect(w7.days, 7);
      expect(w7.prevEndDate, '2026-11-11');
      expect(w7.prevStartDate, '2026-11-05');

      final wCustom = resolveTimeWindow(
        ChartTimeRange.custom,
        customStart: '2026-11-10',
        customEnd: '2026-11-15',
      );
      expect(wCustom.days, 6);
      expect(wCustom.prevStartDate, '2026-11-04');
      expect(wCustom.prevEndDate, '2026-11-09');
    },);

    test(
      'buildOverviewFinanceSeries isola Pendente/Confirmado/Recebido/Projeção e responde a 7d vs 30d',
      () {
        final res30 = buildOverviewFinanceSeries(
          _financeFixtures,
          CurrencyCode.brl,
          range: ChartTimeRange.d30,
          excludeTest: true,
          includeProjection: true,
        );
        final res7 = buildOverviewFinanceSeries(
          _financeFixtures,
          CurrencyCode.brl,
          range: ChartTimeRange.d7,
          excludeTest: true,
          includeProjection: true,
        );

        final real30 = res30.points.where((p) => !p.isProjection).toList();
        final real7 = res7.points.where((p) => !p.isProjection).toList();
        expect(real30.length, greaterThan(real7.length));

        expect(
          real30.any((p) => p.entryIds.contains('fin-test-1')),
          isFalse,
        );

        final lastReal = real30.last;
        expect(lastReal.date, '2026-11-18');
        expect(
          lastReal.confirmedCommercial,
          greaterThan(lastReal.receivedCash ?? 0),
        );
        expect(lastReal.pendingCommissions, greaterThan(0));

        final projPoint = res30.points.last;
        expect(projPoint.isProjection, isTrue);
        expect(projPoint.confirmedCommercial, isNull);
        expect(projPoint.receivedCash, isNull);
        expect(projPoint.pendingCommissions, isNull);
        expect(
          projPoint.projection,
          greaterThan(lastReal.confirmedCommercial ?? 0),
        );

        expect(res7.hasPreviousData, isTrue);
        expect(res30.hasPreviousData, isFalse);
        expect(real30.first.previousConfirmed, isNull);
      },
    );

    test('buildFinanceCashflowSeries filtra por marca e separa saídas vs entradas',
        () {
      final apexDaily = buildFinanceCashflowSeries(
        _financeFixtures,
        CurrencyCode.brl,
        brandId: 'brand-apex',
        range: ChartTimeRange.d30,
        mode: SeriesAggregationMode.daily,
        excludeTest: true,
        includeProjections: false,
      );

      final nov04 = apexDaily.points.firstWhere((p) => p.date == '2026-11-04');
      expect(nov04.outflows, 3200);
      expect(nov04.receivedInflow, 0);

      final nov05 = apexDaily.points.firstWhere((p) => p.date == '2026-11-05');
      expect(nov05.receivedInflow, 9420.5);
    },);

    test(
      'buildAnalyticsContentPoints filtra por janela sem inventar métricas inexistentes',
      () {
        final contents = [
          _makePublishedContent(
            id: 'cnt-1',
            publishedAt: '2026-11-08',
            brandId: 'brand-apex',
            channelId: 'ch-apex-yt',
            views: 84200,
            clicks: 3140,
            revenue: 8034,
            currency: CurrencyCode.brl,
          ),
          _makePublishedContent(
            id: 'cnt-4',
            publishedAt: '2026-11-11',
            brandId: 'brand-nordic',
            channelId: 'ch-nordic-yt',
            views: 112500,
            clicks: 4290,
            revenue: 2717,
            currency: CurrencyCode.usd,
          ),
        ];

        final res30 = buildAnalyticsContentPoints(
          contents,
          CurrencyCode.brl,
          range: ChartTimeRange.d30,
        );
        expect(res30.items.length, 2);
        expect(res30.items[0].contentId, 'cnt-1');
        expect(res30.items[1].contentId, 'cnt-4');
        expect(res30.items[0].isEstimate, isTrue);

        final res7 = buildAnalyticsContentPoints(
          contents,
          CurrencyCode.brl,
          range: ChartTimeRange.d7,
        );
        expect(res7.items.length, 0);
        expect(res7.previousCount, 2);
      },
    );

    test(
      'buildProductNativeCurrencyComparison isola moeda nativa e preserva null sem coerção para 0',
      () {
        final products = [
          _makeProductFixture(
            id: 'prod-izotope-rx',
            currency: CurrencyCode.eur,
            score: 89,
            epcValue: 3.1,
          ),
          _makeProductFixture(
            id: 'prod-unknown-epc',
            currency: CurrencyCode.eur,
            score: null,
            epcValue: null,
          ),
          _makeProductFixture(
            id: 'prod-keychron-q1',
            currency: CurrencyCode.brl,
            score: 91,
          ),
          _makeProductFixture(
            id: 'prod-seed-test',
            currency: CurrencyCode.brl,
            score: 76,
            isTest: true,
          ),
        ];

        final eurItems = buildProductNativeCurrencyComparison(
          products,
          CurrencyCode.eur,
          ProductChartMetric.opportunityScore,
          excludeTest: true,
        );
        expect(
          eurItems.every((i) => i.product.currency == CurrencyCode.eur),
          isTrue,
        );
        final missing =
            eurItems.firstWhere((i) => i.product.id == 'prod-unknown-epc');
        expect(missing.value, isNull);
        expect(missing.missingData, isTrue);
        expect(eurItems.last.product.id, 'prod-unknown-epc');

        final brlItems = buildProductNativeCurrencyComparison(
          products,
          CurrencyCode.brl,
          ProductChartMetric.opportunityScore,
          excludeTest: true,
        );
        expect(brlItems.any((i) => i.product.isTest), isFalse);
      },
    );
  });
}
