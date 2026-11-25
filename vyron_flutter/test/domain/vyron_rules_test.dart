import 'package:flutter_test/flutter_test.dart';
import 'package:vyron/core/crypto/vyron_crypto.dart';
import 'package:vyron/domain/models/brand_product_models.dart';
import 'package:vyron/domain/models/content_channel_finance_models.dart';
import 'package:vyron/domain/models/operations_settings_models.dart';
import 'package:vyron/domain/models/vyron_enums.dart';
import 'package:vyron/domain/rules/vyron_rules.dart';

ContentItem _makeBaseContent() {
  const draft = ContentItem(
    id: 'c1',
    brandId: 'b1',
    channelId: 'ch1',
    productId: 'p1',
    title: 'Review Keychron Q1 Pro',
    description: 'Análise técnica completa com testes de latência.',
    format: ContentFormat.longForm,
    category: ContentCategory.comercialContextual,
    visibility: ContentVisibility.unlisted,
    analysisMethod: AnalysisMethod.testeProprio,
    sensitiveTopic: SensitiveTopic.nenhum,
    unclassifiedRiskFlag: false,
    status: ContentStatus.inReview,
    scheduledDate: '2026-11-22',
    brief: 'Comparativo completo',
    angleIdea: 'Setup minimalista',
    script: 'Introdução técnica e testes práticos.',
    affiliateLinkUrl: 'https://amzn.to/vyron-q1p',
    verifiedDestinationUrl: 'https://www.amazon.com.br/dp/B0EXAMPLE',
    linkVerifiedAt: '2026-11-18T12:00:00Z',
    commercialConditionsVerifiedAt: '2026-11-18T12:00:00Z',
    offerEndsAt: '2026-11-30T23:59:59Z',
    affiliateDisclosure: 'Este vídeo contém links de afiliado. Posso receber comissão sem custo extra.',
    aiDisclosureRequired: false,
    aiDisclosureText: '',
    relevanceTestPassed: true,
    editorialChecklistPassed: true,
    humanHoursLogged: 6.5,
    dossier: [],
    references: [],
    currentManifestHash: '',
    authorization: null,
    versions: [
      ContentVersion(
        version: 'v1.0',
        manifestHash: 'seed',
        author: 'Agente Editorial',
        note: 'Rascunho inicial',
        timestamp: '2026-11-15T10:00:00Z',
        scriptSnapshot: 'Introdução técnica e testes práticos.',
      ),
    ],
  );
  final hash = computeContentItemManifestHash(draft);
  return draft.copyWith(
    currentManifestHash: hash,
    versions: [
      ContentVersion(
        version: draft.versions.first.version,
        manifestHash: hash,
        author: draft.versions.first.author,
        note: draft.versions.first.note,
        timestamp: draft.versions.first.timestamp,
        scriptSnapshot: draft.versions.first.scriptSnapshot,
      ),
    ],
  );
}

Product _makeBaseProduct({
  String id = 'p1',
  CurrencyCode currency = CurrencyCode.brl,
  double? epcValue = 1.85,
  int? cookieWindowDays = 14,
  int? opportunityScore = 84,
}) {
  return Product(
    id: id,
    externalId: 'EXT-001',
    brandId: 'b1',
    linkedBrandIds: const ['b1'],
    isTest: false,
    name: 'Keychron Q1 Pro',
    category: 'Periféricos',
    platform: 'Amazon Associates',
    remunerationModel: RemunerationModel.revShare,
    price: 1290,
    currency: currency,
    commissionRatePct: 8,
    cpaValue: null,
    epcValue: epcValue,
    cookieWindowDays: cookieWindowDays,
    opportunityScore: opportunityScore,
    dataConfidence: DataConfidence.alta,
    qualityGrade: ProductQualityGrade.a,
    complianceState: ComplianceState.approved,
    complianceMarket: 'Brasil',
    demandTrendPct: 18,
    competitionLevel: CompetitionLevel.media,
    status: ProductStatus.candidate,
    evidence: const [],
    decisions: const [],
    updatedAt: '2026-11-10T10:00:00Z',
  );
}

const SystemControlState _activeControl = SystemControlState(
  state: SystemControlStatus.active,
  actor: 'Proprietário',
  reason: 'Operação normal',
  updatedAt: '2026-11-18T08:00:00Z',
  publishingEnabled: true,
  phaseBPublicAllowed: false,
);

void main() {
  group('Lote 1 — Regras de Domínio (VyronRules)', () {
    test('calculateFinanceSummary separa Pending, Confirmed, Received, Projeções, exclui isTest e limita budget', () {
      const entries = <FinanceEntry>[
        FinanceEntry(
          id: 'f1',
          brandId: 'b1',
          platform: 'Amazon',
          description: 'Comissão Pendente',
          type: FinanceEntryType.commission,
          stage: CommissionStage.pending,
          amount: 1000,
          currency: CurrencyCode.brl,
          date: '2026-11-10',
        ),
        FinanceEntry(
          id: 'f2',
          brandId: 'b1',
          platform: 'Hotmart',
          description: 'Comissão Confirmada aguardando saque',
          type: FinanceEntryType.commission,
          stage: CommissionStage.confirmed,
          amount: 500,
          currency: CurrencyCode.brl,
          date: '2026-11-08',
        ),
        FinanceEntry(
          id: 'f3',
          brandId: 'b1',
          platform: 'PartnerStack',
          description: 'Recebido em conta',
          type: FinanceEntryType.commission,
          stage: CommissionStage.received,
          amount: 100,
          currency: CurrencyCode.usd, // 572 BRL
          date: '2026-11-05',
        ),
        FinanceEntry(
          id: 'f4',
          brandId: 'b1',
          platform: 'Infra',
          description: 'Despesa operacional',
          type: FinanceEntryType.expense,
          stage: CommissionStage.received,
          amount: 200,
          currency: CurrencyCode.brl,
          date: '2026-11-06',
        ),
        FinanceEntry(
          id: 'f5',
          brandId: 'b1',
          platform: 'Projeção',
          description: 'Estimativa próximo mês',
          type: FinanceEntryType.commission,
          stage: CommissionStage.confirmed,
          amount: 4000,
          currency: CurrencyCode.brl,
          date: '2026-12-01',
          isProjection: true,
        ),
        FinanceEntry(
          id: 'f-test',
          brandId: 'b1',
          platform: 'Test Sandbox',
          description: 'Registro is_test ignorado por padrão',
          type: FinanceEntryType.commission,
          stage: CommissionStage.received,
          amount: 99999,
          currency: CurrencyCode.brl,
          date: '2026-11-12',
          isTest: true,
        ),
      ];

      final summary = calculateFinanceSummary(
        entries,
        CurrencyCode.brl,
        period: PeriodFilter.d30,
        referenceDate: '2026-11-18',
      );

      expect(summary.pendingCommissions, 1000);
      expect(summary.receivedCashIn.round(), 572);
      expect(summary.confirmedAwaitingPayout.round(), 500);
      expect(summary.confirmedCommercialResult.round(), 1072);
      expect(summary.expensesCashOut, 200);
      expect(summary.netRealizedCash.round(), 372);
      expect(summary.availableReinvestmentBudget.round(), 372);
      expect(summary.projectedFutureRevenue, 4000);
    });

    test(
      'computeOperationalEfficiency deriva caixa realizado por hora humana',
      () {
        final item = _makeBaseContent();
        final fin = calculateFinanceSummary(const [
          FinanceEntry(
            id: 'f1',
            brandId: 'b1',
            platform: 'Amazon',
            description: 'Caixa',
            type: FinanceEntryType.commission,
            stage: CommissionStage.received,
            amount: 650,
            currency: CurrencyCode.brl,
            date: '2026-11-10',
          ),
        ], CurrencyCode.brl);
        final eff = computeOperationalEfficiency(fin, [item], brandId: 'b1');
        expect(eff.totalHumanHours, 6.5);
        expect(eff.realizedCashPerHour, 100);
      },
    );

    test('computeContentManifestHash é idêntico ao vetor TypeScript, invariante a scheduledDate e sensível a edição do manifesto', () {
      final item = _makeBaseContent();
      final h1 = computeContentItemManifestHash(item);
      expect(
        h1,
        '4d808e2090788063bf00081daada035c73d164963cee260a2866beeca8a2c0cb',
      );

      final rescheduled = item.copyWith(scheduledDate: '2026-12-15');
      expect(computeContentItemManifestHash(rescheduled), h1);

      final editedScript = item.copyWith(
        script: '${item.script} (ajuste de copy)',
      );
      expect(computeContentItemManifestHash(editedScript), isNot(h1));

      final editedVisibility = item.copyWith(
        visibility: ContentVisibility.publicVis,
      );
      expect(computeContentItemManifestHash(editedVisibility), isNot(h1));
    });

    test('evaluateContentPreSendChecks bloqueia por divergência de hash, expiração, HALTED, público na Fase A e risco não classificado', () {
      final item = _makeBaseContent();
      final hash = computeContentItemManifestHash(item);
      final validAuth = ContentAuthorization(
        type: AuthorizationType.individual,
        authorizedHash: hash,
        actor: 'Proprietário',
        authorizedAt: '2026-11-18T14:00:00Z',
        expiresAt: '2026-11-20T14:00:00Z',
        rulesVersion: 'v1.0',
        evidenceVerifiedAt: '2026-11-18T12:00:00Z',
      );

      final okEval = evaluateContentPreSendChecks(
        item.copyWith(authorization: validAuth),
        _activeControl,
        nowIso: '2026-11-18T18:00:00Z',
      );
      expect(okEval.canSend, isTrue);

      final editedEval = evaluateContentPreSendChecks(
        item.copyWith(
          script: 'Texto alterado sem nova aprovação',
          authorization: validAuth,
        ),
        _activeControl,
        nowIso: '2026-11-18T18:00:00Z',
      );
      expect(editedEval.canSend, isFalse);
      expect(
        editedEval.checks
            .firstWhere((c) => c.id == PreSendCheckId.hashMatch)
            .passed,
        isFalse,
      );

      final expiredEval = evaluateContentPreSendChecks(
        item.copyWith(
          authorization: validAuth.copyWith(expiresAt: '2026-11-18T17:00:00Z'),
        ),
        _activeControl,
        nowIso: '2026-11-18T18:00:00Z',
      );
      expect(expiredEval.canSend, isFalse);
      expect(
        expiredEval.checks
            .firstWhere((c) => c.id == PreSendCheckId.authValid)
            .passed,
        isFalse,
      );

      final haltedEval = evaluateContentPreSendChecks(
        item.copyWith(authorization: validAuth),
        _activeControl.copyWith(
          state: SystemControlStatus.halted,
          reason: 'Stop All teste',
        ),
        nowIso: '2026-11-18T18:00:00Z',
      );
      expect(haltedEval.canSend, isFalse);
      expect(
        haltedEval.checks
            .firstWhere((c) => c.id == PreSendCheckId.systemControlPhase)
            .passed,
        isFalse,
      );

      final pubItem = item.copyWith(visibility: ContentVisibility.publicVis);
      final pubHash = computeContentItemManifestHash(pubItem);
      final pubPhaseAEval = evaluateContentPreSendChecks(
        pubItem.copyWith(
          authorization: validAuth.copyWith(authorizedHash: pubHash),
        ),
        _activeControl,
        nowIso: '2026-11-18T18:00:00Z',
      );
      expect(pubPhaseAEval.canSend, isFalse);

      final riskEval = evaluateContentPreSendChecks(
        item.copyWith(unclassifiedRiskFlag: true, authorization: validAuth),
        _activeControl,
        nowIso: '2026-11-18T18:00:00Z',
      );
      expect(riskEval.canSend, isFalse);
      expect(
        riskEval.checks
            .firstWhere((c) => c.id == PreSendCheckId.riskCompliance)
            .passed,
        isFalse,
      );
    });

    test('scoreProductV61 preserva null sem coerção para 0 e groupProductsByCurrency isola moedas nativas', () {
      final incomplete = _makeBaseProduct(
        id: 'p-inc',
        epcValue: null,
        cookieWindowDays: null,
      );
      final incompleteRes = scoreProductV61(incomplete);
      expect(incompleteRes.score, isNull);
      expect(incompleteRes.unknownFieldsCount, 2);

      final complete = _makeBaseProduct(id: 'p-ok');
      final completeRes = scoreProductV61(complete);
      expect(completeRes.score, isNotNull);
      expect(completeRes.score, inInclusiveRange(1, 99));

      final brlProd = _makeBaseProduct(
        id: 'p-brl',
        currency: CurrencyCode.brl,
        opportunityScore: 88,
      );
      final usdProd = _makeBaseProduct(
        id: 'p-usd',
        currency: CurrencyCode.usd,
        opportunityScore: 93,
      );
      final brlNull = _makeBaseProduct(
        id: 'p-brl-null',
        currency: CurrencyCode.brl,
        opportunityScore: null,
      );

      final grouped = groupProductsByCurrency([brlNull, usdProd, brlProd]);
      expect(grouped.length, 2);
      expect(grouped[0].currency, CurrencyCode.brl);
      expect(grouped[0].items[0].id, 'p-brl');
      expect(grouped[0].items[1].id, 'p-brl-null');
      expect(grouped[1].currency, CurrencyCode.usd);
    });

    test('reconcileOrphanedJobRuns encerra jobs órfãos e libera canResumeSystemControl', () {
      const jobs = <JobRun>[
        JobRun(
          id: 101,
          taskName: JobTaskName.pipelineRun,
          mode: JobMode.dryRun,
          status: JobRunStatus.running,
          startedAt: '2026-11-18T10:00:00Z',
          recordsProcessed: 0,
          summary: 'Execução interrompida sem término.',
        ),
        JobRun(
          id: 100,
          taskName: JobTaskName.productsScore,
          mode: JobMode.commit,
          status: JobRunStatus.succeeded,
          startedAt: '2026-11-18T08:00:00Z',
          finishedAt: '2026-11-18T08:00:12Z',
          recordsProcessed: 8,
          summary: 'Score v0-hipotese concluído.',
        ),
      ];

      final blocked = canResumeSystemControl(jobs);
      expect(blocked.allowed, isFalse);
      expect(blocked.blockingJobIds, [101]);

      final reconciled = reconcileOrphanedJobRuns(
        jobs,
        nowIso: '2026-11-18T18:00:00Z',
        olderThanMinutes: 30,
      );
      expect(reconciled.reconciledIds, [101]);
      expect(reconciled.updated[0].status, JobRunStatus.failed);

      final unblocked = canResumeSystemControl(reconciled.updated);
      expect(unblocked.allowed, isTrue);
    });

    test('convertCurrency converte consistentemente entre BRL, USD e EUR', () {
      final usdToBrl = convertCurrency(100, CurrencyCode.usd, CurrencyCode.brl);
      expect(usdToBrl.round(), 572);
      final backToUsd = convertCurrency(
        usdToBrl,
        CurrencyCode.brl,
        CurrencyCode.usd,
      );
      expect(backToUsd.round(), 100);
    });

    test(
      'transitionProductStatus exige justificativa e registra histórico',
      () {
        final sampleProduct = _makeBaseProduct();
        expect(
          () => transitionProductStatus(
            sampleProduct,
            ProductStatus.approved,
            '   ',
          ),
          throwsStateError,
        );

        final approved = transitionProductStatus(
          sampleProduct,
          ProductStatus.approved,
          'EPC acima de R\$ 1,40 e demanda crescente no Brasil.',
        );
        expect(approved.status, ProductStatus.approved);
        expect(approved.decisions.length, 1);
        expect(approved.decisions[0].previousStatus, ProductStatus.candidate);
        expect(approved.decisions[0].newStatus, ProductStatus.approved);
      },
    );

    test(
      'transitionContentStatus avança status e grava manifestHash na versão',
      () {
        final item = _makeBaseContent();
        final published = transitionContentStatus(
          item,
          ContentStatus.published,
          'Publicado no YouTube',
          timestamp: '2026-11-18T19:00:00Z',
        );
        expect(published.status, ContentStatus.published);
        expect(published.versions.length, 2);
        expect(published.versions[0].version, 'v2.0');
        expect(
          published.versions[0].manifestHash,
          computeContentItemManifestHash(item),
        );
        expect(published.publishedAt, '2026-11-18');
      },
    );

    test(
      'applyStopAllToAutomations pausa agentes Running/Waiting e registra log',
      () {
        const agents = <AutomationAgent>[
          AutomationAgent(
            id: 'a1',
            name: 'Radar de Produtos',
            category: AgentCategory.productIntelligence,
            autonomyLevel: 2,
            responsibility: 'Coleta sinais de demanda',
            state: AgentRunState.running,
            brandScope: 'Todas',
            dependencies: [],
            flowSteps: ['Coletar', 'Pontuar'],
            pendingApprovalCount: 0,
            lastRunAt: '2026-11-18T12:00:00Z',
            limits: AgentPolicyLimits(
              requireHumanApproval: true,
              maxActionsPerDay: 20,
              maxDailySpendBRL: 0,
              allowedModules: ['Products'],
            ),
            history: [],
          ),
          AutomationAgent(
            id: 'a2',
            name: 'Conciliador Financeiro',
            category: AgentCategory.finance,
            autonomyLevel: 2,
            responsibility: 'Separa pendente vs confirmado',
            state: AgentRunState.idle,
            brandScope: 'Todas',
            dependencies: [],
            flowSteps: ['Ler extratos'],
            pendingApprovalCount: 0,
            lastRunAt: '2026-11-18T11:00:00Z',
            limits: AgentPolicyLimits(
              requireHumanApproval: true,
              maxActionsPerDay: 10,
              maxDailySpendBRL: 0,
              allowedModules: ['Finance'],
            ),
            history: [],
          ),
        ];

        final res = applyStopAllToAutomations(agents);
        expect(res.stoppedCount, 1);
        expect(res.updated[0].state, AgentRunState.paused);
        expect(res.updated[0].history[0].status, AgentExecutionStatus.paused);
        expect(res.updated[1].state, AgentRunState.idle);
      },
    );
  });
}
