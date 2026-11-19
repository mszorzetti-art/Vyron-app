import test from 'node:test';
import assert from 'node:assert/strict';
import {
  applyStopAllToAutomations,
  calculateFinanceSummary,
  canResumeSystemControl,
  computeContentManifestHash,
  computeOperationalEfficiency,
  convertCurrency,
  evaluateContentPreSendChecks,
  groupProductsByCurrency,
  reconcileOrphanedJobRuns,
  scoreProductV61,
  transitionContentStatus,
  transitionProductStatus,
} from './vyronRules';
import {
  AutomationAgent,
  ContentItem,
  FinanceEntry,
  JobRun,
  Product,
  SystemControlState,
} from '../types/vyron';

function makeBaseContent(): ContentItem {
  const base: Omit<ContentItem, 'currentManifestHash'> = {
    id: 'c1',
    brandId: 'b1',
    channelId: 'ch1',
    productId: 'p1',
    title: 'Review Keychron Q1 Pro',
    description: 'Análise técnica completa com testes de latência.',
    format: 'Long-form',
    category: 'Comercial contextual',
    visibility: 'unlisted',
    analysisMethod: 'Teste próprio',
    sensitiveTopic: 'Nenhum',
    unclassifiedRiskFlag: false,
    status: 'In Review',
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
    authorization: null,
    versions: [
      {
        version: 'v1.0',
        manifestHash: 'seed',
        author: 'Agente Editorial',
        note: 'Rascunho inicial',
        timestamp: '2026-11-15T10:00:00Z',
        scriptSnapshot: 'Introdução técnica e testes práticos.',
      },
    ],
  };
  const hash = computeContentManifestHash(base);
  return {
    ...base,
    currentManifestHash: hash,
    versions: [{ ...base.versions[0], manifestHash: hash }],
  };
}

function makeBaseProduct(overrides: Partial<Product> = {}): Product {
  return {
    id: 'p1',
    externalId: 'EXT-001',
    brandId: 'b1',
    linkedBrandIds: ['b1'],
    isTest: false,
    name: 'Keychron Q1 Pro',
    category: 'Periféricos',
    platform: 'Amazon Associates',
    remunerationModel: 'RevShare',
    price: 1290,
    currency: 'BRL',
    commissionRatePct: 8,
    cpaValue: null,
    epcValue: 1.85,
    cookieWindowDays: 14,
    opportunityScore: 84,
    dataConfidence: 'Alta',
    qualityGrade: 'A',
    complianceState: 'APPROVED',
    complianceMarket: 'Brasil',
    demandTrendPct: 18,
    competitionLevel: 'Média',
    status: 'Candidate',
    evidence: [],
    decisions: [],
    updatedAt: '2026-11-10T10:00:00Z',
    ...overrides,
  };
}

const ACTIVE_CONTROL: SystemControlState = {
  state: 'ACTIVE',
  actor: 'Proprietário',
  reason: 'Operação normal',
  updatedAt: '2026-11-18T08:00:00Z',
  publishingEnabled: true,
  phaseBPublicAllowed: false,
};

test('calculateFinanceSummary strictly separates Pending, Confirmed, Received, Projections, excludes isTest, and caps reinvestment budget', () => {
  const entries: FinanceEntry[] = [
    {
      id: 'f1',
      brandId: 'b1',
      platform: 'Amazon',
      description: 'Comissão Pendente',
      type: 'Commission',
      stage: 'Pending',
      amount: 1000,
      currency: 'BRL',
      date: '2026-11-10',
    },
    {
      id: 'f2',
      brandId: 'b1',
      platform: 'Hotmart',
      description: 'Comissão Confirmada aguardando saque',
      type: 'Commission',
      stage: 'Confirmed',
      amount: 500,
      currency: 'BRL',
      date: '2026-11-08',
    },
    {
      id: 'f3',
      brandId: 'b1',
      platform: 'PartnerStack',
      description: 'Recebido em conta',
      type: 'Commission',
      stage: 'Received',
      amount: 100,
      currency: 'USD', // 572 BRL
      date: '2026-11-05',
    },
    {
      id: 'f4',
      brandId: 'b1',
      platform: 'Infra',
      description: 'Despesa operacional',
      type: 'Expense',
      stage: 'Received',
      amount: 200,
      currency: 'BRL',
      date: '2026-11-06',
    },
    {
      id: 'f5',
      brandId: 'b1',
      platform: 'Projeção',
      description: 'Estimativa próximo mês',
      type: 'Commission',
      stage: 'Confirmed',
      amount: 4000,
      currency: 'BRL',
      date: '2026-12-01',
      isProjection: true,
    },
    {
      id: 'f-test',
      brandId: 'b1',
      platform: 'Test Sandbox',
      description: 'Registro is_test ignorado por padrão',
      type: 'Commission',
      stage: 'Received',
      amount: 99999,
      currency: 'BRL',
      date: '2026-11-12',
      isTest: true,
    },
  ];

  const summary = calculateFinanceSummary(entries, 'BRL', { period: '30d', referenceDate: '2026-11-18' });

  assert.equal(summary.pendingCommissions, 1000);
  assert.equal(Math.round(summary.receivedCashIn), 572);
  assert.equal(Math.round(summary.confirmedAwaitingPayout), 500);
  assert.equal(Math.round(summary.confirmedCommercialResult), 1072);
  assert.equal(summary.expensesCashOut, 200);
  assert.equal(Math.round(summary.netRealizedCash), 372);
  assert.equal(Math.round(summary.availableReinvestmentBudget), 372);
  assert.equal(summary.projectedFutureRevenue, 4000);
});

test('computeOperationalEfficiency derives realized cash per human hour', () => {
  const item = makeBaseContent();
  const fin = calculateFinanceSummary(
    [
      {
        id: 'f1',
        brandId: 'b1',
        platform: 'Amazon',
        description: 'Caixa',
        type: 'Commission',
        stage: 'Received',
        amount: 650,
        currency: 'BRL',
        date: '2026-11-10',
      },
    ],
    'BRL'
  );
  const eff = computeOperationalEfficiency(fin, [item], 'b1');
  assert.equal(eff.totalHumanHours, 6.5);
  assert.equal(eff.realizedCashPerHour, 100);
});

test('computeContentManifestHash is invariant to scheduledDate edits but changes on any manifest field edit', () => {
  const item = makeBaseContent();
  const h1 = computeContentManifestHash(item);
  const rescheduled = { ...item, scheduledDate: '2026-12-15' };
  const h2 = computeContentManifestHash(rescheduled);
  assert.equal(h1, h2);

  const editedScript = { ...item, script: `${item.script} (ajuste de copy)` };
  const h3 = computeContentManifestHash(editedScript);
  assert.notEqual(h1, h3);

  const editedVisibility = { ...item, visibility: 'public' as const };
  assert.notEqual(h1, computeContentManifestHash(editedVisibility));
});

test('evaluateContentPreSendChecks blocks on hash mismatch, expired auth, HALTED control, public in Phase A, missing disclosure, or unclassified risk', () => {
  const item = makeBaseContent();
  const hash = computeContentManifestHash(item);
  const validAuth = {
    type: 'individual' as const,
    authorizedHash: hash,
    actor: 'Proprietário',
    authorizedAt: '2026-11-18T14:00:00Z',
    expiresAt: '2026-11-20T14:00:00Z',
    rulesVersion: 'v1.0',
    evidenceVerifiedAt: '2026-11-18T12:00:00Z',
  };

  // All valid in Phase A unlisted
  const okEval = evaluateContentPreSendChecks(
    { ...item, authorization: validAuth },
    ACTIVE_CONTROL,
    '2026-11-18T18:00:00Z'
  );
  assert.equal(okEval.canSend, true);

  // Edit script -> hash mismatch (zero inheritance)
  const editedEval = evaluateContentPreSendChecks(
    { ...item, script: 'Texto alterado sem nova aprovação', authorization: validAuth },
    ACTIVE_CONTROL,
    '2026-11-18T18:00:00Z'
  );
  assert.equal(editedEval.canSend, false);
  assert.equal(editedEval.checks.find((c) => c.id === 'hash_match')?.passed, false);

  // Expired authorization
  const expiredEval = evaluateContentPreSendChecks(
    { ...item, authorization: { ...validAuth, expiresAt: '2026-11-18T17:00:00Z' } },
    ACTIVE_CONTROL,
    '2026-11-18T18:00:00Z'
  );
  assert.equal(expiredEval.canSend, false);
  assert.equal(expiredEval.checks.find((c) => c.id === 'auth_valid')?.passed, false);

  // System HALTED
  const haltedEval = evaluateContentPreSendChecks(
    { ...item, authorization: validAuth },
    { ...ACTIVE_CONTROL, state: 'HALTED', reason: 'Stop All teste' },
    '2026-11-18T18:00:00Z'
  );
  assert.equal(haltedEval.canSend, false);
  assert.equal(haltedEval.checks.find((c) => c.id === 'system_control_phase')?.passed, false);

  // Public visibility in Phase A
  const pubItem = { ...item, visibility: 'public' as const };
  const pubHash = computeContentManifestHash(pubItem);
  const pubPhaseAEval = evaluateContentPreSendChecks(
    { ...pubItem, authorization: { ...validAuth, authorizedHash: pubHash } },
    ACTIVE_CONTROL,
    '2026-11-18T18:00:00Z'
  );
  assert.equal(pubPhaseAEval.canSend, false);

  // Unclassified risk flag blocks
  const riskEval = evaluateContentPreSendChecks(
    { ...item, unclassifiedRiskFlag: true, authorization: validAuth },
    ACTIVE_CONTROL,
    '2026-11-18T18:00:00Z'
  );
  assert.equal(riskEval.canSend, false);
  assert.equal(riskEval.checks.find((c) => c.id === 'risk_compliance')?.passed, false);
});

test('scoreProductV61 preserves unknown null inputs without coercing to 0, and groupProductsByCurrency keeps native currency rankings', () => {
  const incomplete = makeBaseProduct({ id: 'p-inc', epcValue: null, cookieWindowDays: null });
  const incompleteRes = scoreProductV61(incomplete);
  assert.equal(incompleteRes.score, null);
  assert.equal(incompleteRes.unknownFieldsCount, 2);

  const brlProd = makeBaseProduct({ id: 'p-brl', currency: 'BRL', opportunityScore: 88 });
  const usdProd = makeBaseProduct({ id: 'p-usd', currency: 'USD', opportunityScore: 93 });
  const brlNull = makeBaseProduct({ id: 'p-brl-null', currency: 'BRL', opportunityScore: null });

  const grouped = groupProductsByCurrency([brlNull, usdProd, brlProd]);
  assert.equal(grouped.length, 2);
  assert.equal(grouped[0].currency, 'BRL');
  assert.equal(grouped[0].items[0].id, 'p-brl');
  assert.equal(grouped[0].items[1].id, 'p-brl-null');
  assert.equal(grouped[1].currency, 'USD');
});

test('reconcileOrphanedJobRuns clears stale running jobs and unlocks canResumeSystemControl', () => {
  const jobs: JobRun[] = [
    {
      id: 101,
      taskName: 'pipeline.run',
      mode: 'dry-run',
      status: 'running',
      startedAt: '2026-11-18T10:00:00Z',
      recordsProcessed: 0,
      summary: 'Execução interrompida sem término.',
    },
    {
      id: 100,
      taskName: 'products.score',
      mode: 'commit',
      status: 'succeeded',
      startedAt: '2026-11-18T08:00:00Z',
      finishedAt: '2026-11-18T08:00:12Z',
      recordsProcessed: 8,
      summary: 'Score v0-hipotese concluído.',
    },
  ];

  const blocked = canResumeSystemControl(jobs);
  assert.equal(blocked.allowed, false);
  assert.deepEqual(blocked.blockingJobIds, [101]);

  const { updated, reconciledIds } = reconcileOrphanedJobRuns(jobs, '2026-11-18T18:00:00Z', 30);
  assert.deepEqual(reconciledIds, [101]);
  assert.equal(updated[0].status, 'failed');

  const unblocked = canResumeSystemControl(updated);
  assert.equal(unblocked.allowed, true);
});

test('convertCurrency converts consistently across BRL, USD, and EUR', () => {
  const usdToBrl = convertCurrency(100, 'USD', 'BRL');
  assert.equal(Math.round(usdToBrl), 572);
  const backToUsd = convertCurrency(usdToBrl, 'BRL', 'USD');
  assert.equal(Math.round(backToUsd), 100);
});

test('transitionProductStatus requires justification and logs decision history', () => {
  const sampleProduct = makeBaseProduct();
  assert.throws(() => transitionProductStatus(sampleProduct, 'Approved', '   '));

  const approved = transitionProductStatus(
    sampleProduct,
    'Approved',
    'EPC acima de R$1,40 e demanda crescente no Brasil.'
  );
  assert.equal(approved.status, 'Approved');
  assert.equal(approved.decisions.length, 1);
  assert.equal(approved.decisions[0].previousStatus, 'Candidate');
  assert.equal(approved.decisions[0].newStatus, 'Approved');
});

test('transitionContentStatus advances status and records manifestHash in version snapshot', () => {
  const item = makeBaseContent();
  const published = transitionContentStatus(item, 'Published', 'Publicado no YouTube');
  assert.equal(published.status, 'Published');
  assert.equal(published.versions.length, 2);
  assert.equal(published.versions[0].version, 'v2.0');
  assert.equal(published.versions[0].manifestHash, computeContentManifestHash(item));
  assert.ok(published.publishedAt);
});

test('applyStopAllToAutomations pauses running and waiting agents and records history', () => {
  const agents: AutomationAgent[] = [
    {
      id: 'a1',
      name: 'Radar de Produtos',
      category: 'Product Intelligence',
      autonomyLevel: 2,
      responsibility: 'Coleta sinais de demanda',
      state: 'Running',
      brandScope: 'Todas',
      dependencies: [],
      flowSteps: ['Coletar', 'Pontuar'],
      pendingApprovalCount: 0,
      lastRunAt: '2026-11-18T12:00:00Z',
      limits: {
        requireHumanApproval: true,
        maxActionsPerDay: 20,
        maxDailySpendBRL: 0,
        allowedModules: ['Products'],
      },
      history: [],
    },
    {
      id: 'a2',
      name: 'Conciliador Financeiro',
      category: 'Finance',
      autonomyLevel: 2,
      responsibility: 'Separa pendente vs confirmado',
      state: 'Idle',
      brandScope: 'Todas',
      dependencies: [],
      flowSteps: ['Ler extratos'],
      pendingApprovalCount: 0,
      lastRunAt: '2026-11-18T11:00:00Z',
      limits: {
        requireHumanApproval: true,
        maxActionsPerDay: 10,
        maxDailySpendBRL: 0,
        allowedModules: ['Finance'],
      },
      history: [],
    },
  ];

  const { updated, stoppedCount } = applyStopAllToAutomations(agents);
  assert.equal(stoppedCount, 1);
  assert.equal(updated[0].state, 'Paused');
  assert.equal(updated[0].history[0].status, 'Paused');
  assert.equal(updated[1].state, 'Idle');
});
