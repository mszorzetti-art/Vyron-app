import {
  ActivityCategory,
  ActivityEvent,
  AutomationAgent,
  Brand,
  Channel,
  ContentItem,
  ContentStatus,
  ContentVersion,
  CurrencyCode,
  FinanceEntry,
  JobRun,
  PeriodFilter,
  Product,
  ProductStatus,
  SystemControlState,
} from '../types/vyron';

/**
 * Deterministic FX rates relative to BRL (1 unit -> BRL)
 * Used for consolidated reporting in Finance/Overview/Analytics,
 * NEVER inside `products score` ranking (which stays per-currency).
 */
export const FX_TO_BRL: Record<CurrencyCode, number> = {
  BRL: 1.0,
  USD: 5.72,
  EUR: 6.18,
};

export function convertCurrency(
  amount: number,
  from: CurrencyCode,
  to: CurrencyCode
): number {
  if (from === to) return amount;
  const inBRL = amount * FX_TO_BRL[from];
  return inBRL / FX_TO_BRL[to];
}

export function formatCurrency(amount: number, currency: CurrencyCode): string {
  const locale = currency === 'BRL' ? 'pt-BR' : currency === 'EUR' ? 'de-DE' : 'en-US';
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

export function formatCompactNumber(value: number): string {
  if (Math.abs(value) >= 1_000_000) {
    return `${(value / 1_000_000).toFixed(1)}M`;
  }
  if (Math.abs(value) >= 1_000) {
    return `${(value / 1_000).toFixed(1)}K`;
  }
  return value.toString();
}

export function getPeriodStartDate(period: PeriodFilter, referenceDate = '2026-11-18'): string {
  const ref = new Date(`${referenceDate}T00:00:00Z`);
  const days = period === '7d' ? 7 : period === '30d' ? 30 : period === '90d' ? 90 : 365;
  ref.setUTCDate(ref.getUTCDate() - days);
  return ref.toISOString().slice(0, 10);
}

/**
 * Pure TypeScript synchronous SHA-256 (UTF-8 -> lowercase hex).
 * Allows identical deterministic manifest hashing in both browser UI and Node tests.
 */
export function sha256Hex(input: string): string {
  const K = new Uint32Array([
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ]);

  const utf8 = new TextEncoder().encode(input);
  const bitLen = utf8.length * 8;
  const padLen = ((utf8.length + 9 + 63) >> 6) << 6;
  const padded = new Uint8Array(padLen);
  padded.set(utf8);
  padded[utf8.length] = 0x80;
  const view = new DataView(padded.buffer);
  view.setUint32(padLen - 8, Math.floor(bitLen / 0x100000000), false);
  view.setUint32(padLen - 4, bitLen >>> 0, false);

  let h0 = 0x6a09e667;
  let h1 = 0xbb67ae85;
  let h2 = 0x3c6ef372;
  let h3 = 0xa54ff53a;
  let h4 = 0x510e527f;
  let h5 = 0x9b05688c;
  let h6 = 0x1f83d9ab;
  let h7 = 0x5be0cd19;

  const w = new Uint32Array(64);
  const rotr = (x: number, n: number) => (x >>> n) | (x << (32 - n));

  for (let offset = 0; offset < padLen; offset += 64) {
    for (let i = 0; i < 16; i++) {
      w[i] = view.getUint32(offset + i * 4, false);
    }
    for (let i = 16; i < 64; i++) {
      const s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      const s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) >>> 0;
    }

    let a = h0;
    let b = h1;
    let c = h2;
    let d = h3;
    let e = h4;
    let f = h5;
    let g = h6;
    let h = h7;

    for (let i = 0; i < 64; i++) {
      const S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
      const ch = (e & f) ^ (~e & g);
      const temp1 = (h + S1 + ch + K[i] + w[i]) >>> 0;
      const S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
      const maj = (a & b) ^ (a & c) ^ (b & c);
      const temp2 = (S0 + maj) >>> 0;

      h = g;
      g = f;
      f = e;
      e = (d + temp1) >>> 0;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) >>> 0;
    }

    h0 = (h0 + a) >>> 0;
    h1 = (h1 + b) >>> 0;
    h2 = (h2 + c) >>> 0;
    h3 = (h3 + d) >>> 0;
    h4 = (h4 + e) >>> 0;
    h5 = (h5 + f) >>> 0;
    h6 = (h6 + g) >>> 0;
    h7 = (h7 + h) >>> 0;
  }

  return [h0, h1, h2, h3, h4, h5, h6, h7]
    .map((n) => n.toString(16).padStart(8, '0'))
    .join('');
}

export type ManifestFields = Pick<
  ContentItem,
  | 'brandId'
  | 'channelId'
  | 'productId'
  | 'title'
  | 'description'
  | 'format'
  | 'category'
  | 'visibility'
  | 'analysisMethod'
  | 'sensitiveTopic'
  | 'script'
  | 'affiliateLinkUrl'
  | 'affiliateDisclosure'
  | 'aiDisclosureRequired'
  | 'aiDisclosureText'
>;

export const MANIFEST_FIELD_KEYS: Array<keyof ManifestFields> = [
  'brandId',
  'channelId',
  'productId',
  'title',
  'description',
  'format',
  'category',
  'visibility',
  'analysisMethod',
  'sensitiveTopic',
  'script',
  'affiliateLinkUrl',
  'affiliateDisclosure',
  'aiDisclosureRequired',
  'aiDisclosureText',
];

/**
 * Computes deterministic SHA-256 hash over the immutable release manifest.
 * Operational `scheduledDate` and workflow `status` sit intentionally OUTSIDE the hash
 * so rescheduling never breaks an authorized manifest, while ANY edit to copy/link/visibility
 * invalidates authorization immediately (zero inheritance).
 */
export function computeContentManifestHash(item: ManifestFields): string {
  const canonical = {
    affiliateDisclosure: item.affiliateDisclosure.trim(),
    affiliateLinkUrl: item.affiliateLinkUrl.trim(),
    aiDisclosureRequired: Boolean(item.aiDisclosureRequired),
    aiDisclosureText: item.aiDisclosureText.trim(),
    analysisMethod: item.analysisMethod,
    brandId: item.brandId,
    category: item.category,
    channelId: item.channelId,
    description: item.description.trim(),
    format: item.format,
    productId: item.productId ?? null,
    script: item.script.trim(),
    sensitiveTopic: item.sensitiveTopic,
    title: item.title.trim(),
    visibility: item.visibility,
  };
  return sha256Hex(JSON.stringify(canonical));
}

export interface PreSendCheckItem {
  id:
    | 'hash_match'
    | 'auth_valid'
    | 'link_verified'
    | 'commercial_disclosures'
    | 'risk_compliance'
    | 'system_control_phase';
  label: string;
  passed: boolean;
  detail: string;
}

export interface PreSendEvaluation {
  canSend: boolean;
  recalculatedHash: string;
  checks: PreSendCheckItem[];
}

/**
 * Evaluates all 6 mandatory pre-send verification gates defined in AUTONOMY_AND_AGENTS.md §4.
 */
export function evaluateContentPreSendChecks(
  item: ContentItem,
  systemControl: SystemControlState,
  nowIso = '2026-11-18T18:00:00Z',
  options?: { evidenceFreshnessMaxHours?: number }
): PreSendEvaluation {
  const maxFreshHours = options?.evidenceFreshnessMaxHours ?? 48;
  const nowMs = Date.parse(nowIso);
  const recalculatedHash = computeContentManifestHash(item);
  const auth = item.authorization;

  // 1. Hash match
  const hashMatch = Boolean(auth && auth.authorizedHash === recalculatedHash);
  const check1: PreSendCheckItem = {
    id: 'hash_match',
    label: '1. Hash SHA-256 do manifesto coincide com versão autorizada',
    passed: hashMatch,
    detail: !auth
      ? 'Nenhuma autorização vinculada a esta versão.'
      : hashMatch
      ? `Hash íntegro (${recalculatedHash.slice(0, 12)}...).`
      : 'Divergência detectada: conteúdo alterado após autorização (herança zero).',
  };

  // 2. Authorization active & not expired (and within offer window)
  const expiresMs = auth ? Date.parse(auth.expiresAt) : NaN;
  const offerEndsMs = item.offerEndsAt ? Date.parse(item.offerEndsAt) : NaN;
  const notRevoked = Boolean(auth && !auth.revoked);
  const notExpired = Boolean(auth && !Number.isNaN(expiresMs) && nowMs < expiresMs);
  const withinOfferWindow =
    !item.offerEndsAt ||
    (!Number.isNaN(offerEndsMs) && nowMs <= offerEndsMs && (!auth || expiresMs <= offerEndsMs));

  const authValid = notRevoked && notExpired && withinOfferWindow;
  const check2: PreSendCheckItem = {
    id: 'auth_valid',
    label: '2. Autorização vigente, não revogada e dentro da validade da oferta',
    passed: authValid,
    detail: !auth
      ? 'Aguardando autorização individual com timestamp de expiração.'
      : auth.revoked
      ? `Autorização revogada: ${auth.revokedReason ?? 'Sem motivo registrado'}.`
      : !notExpired
      ? `Autorização expirada em ${auth.expiresAt.slice(0, 16).replace('T', ' ')}.`
      : !withinOfferWindow
      ? `Janela da oferta (${item.offerEndsAt?.slice(0, 10)}) incompatível ou expirada.`
      : `Válida até ${auth.expiresAt.slice(0, 16).replace('T', ' ')}.`,
  };

  // 3. Affiliate link destination verified & fresh
  const isCommercial =
    item.category === 'Comercial contextual' ||
    Boolean(item.productId) ||
    Boolean(item.affiliateLinkUrl.trim());
  const linkVerifiedMs = item.linkVerifiedAt ? Date.parse(item.linkVerifiedAt) : NaN;
  const linkFresh =
    !Number.isNaN(linkVerifiedMs) && (nowMs - linkVerifiedMs) / 3_600_000 <= maxFreshHours;
  const linkOk =
    !isCommercial ||
    (Boolean(item.affiliateLinkUrl.trim()) &&
      Boolean(item.verifiedDestinationUrl.trim()) &&
      linkFresh);

  const check3: PreSendCheckItem = {
    id: 'link_verified',
    label: '3. Link e destino comercial verificados recentemente',
    passed: linkOk,
    detail: !isCommercial
      ? 'Peça puramente editorial sem link comercial.'
      : !item.affiliateLinkUrl.trim() || !item.verifiedDestinationUrl.trim()
      ? 'URL comercial ou destino verificado ausente.'
      : !linkFresh
      ? `Verificação de link expirada (> ${maxFreshHours}h). Revalide o destino.`
      : `Destino verificado (${item.verifiedDestinationUrl}).`,
  };

  // 4. Commercial conditions, 7-point relevance, 9-point checklist & disclosures
  const condMs = item.commercialConditionsVerifiedAt
    ? Date.parse(item.commercialConditionsVerifiedAt)
    : NaN;
  const condFresh = !Number.isNaN(condMs) && (nowMs - condMs) / 3_600_000 <= maxFreshHours;
  const affDiscOk = !isCommercial || item.affiliateDisclosure.trim().length > 0;
  const aiDiscOk = !item.aiDisclosureRequired || item.aiDisclosureText.trim().length > 0;
  const gatesOk =
    item.relevanceTestPassed &&
    item.editorialChecklistPassed &&
    (!isCommercial || condFresh) &&
    affDiscOk &&
    aiDiscOk;

  const missingDetails: string[] = [];
  if (!item.relevanceTestPassed) missingDetails.push('teste de relevância (7 pts)');
  if (!item.editorialChecklistPassed) missingDetails.push('checklist editorial (9 pts)');
  if (isCommercial && !condFresh) missingDetails.push('condições comerciais frescas');
  if (!affDiscOk) missingDetails.push('divulgação de afiliação');
  if (!aiDiscOk) missingDetails.push('divulgação de IA generativa');

  const check4: PreSendCheckItem = {
    id: 'commercial_disclosures',
    label: '4. Evidência comercial, checklists e divulgações obrigatórias',
    passed: gatesOk,
    detail: gatesOk
      ? 'Relevância, checklist editorial, condições e divulgações em conformidade.'
      : `Pendente: ${missingDetails.join(', ')}.`,
  };

  // 5. Risk classification & sensitive topic individual gate
  const hasSensitiveTopic = item.sensitiveTopic !== 'Nenhum';
  const sensitiveIndividualOk = !hasSensitiveTopic || auth?.type === 'individual';
  const riskOk = !item.unclassifiedRiskFlag && sensitiveIndividualOk;

  const check5: PreSendCheckItem = {
    id: 'risk_compliance',
    label: '5. Classificação de risco e trava para temas sensíveis',
    passed: riskOk,
    detail: item.unclassifiedRiskFlag
      ? 'Bloqueado: item marcado com risco não classificado.'
      : hasSensitiveTopic && auth?.type !== 'individual'
      ? `Tema sensível (${item.sensitiveTopic}) exige autorização individual humana.`
      : hasSensitiveTopic
      ? `Tema sensível (${item.sensitiveTopic}) com autorização individual registrada.`
      : 'Sem sinalizadores de risco não classificado.',
  };

  // 6. SystemControl ACTIVE + PUBLISHING_ENABLED + Phase A/B visibility gate
  const phaseOk = item.visibility !== 'public' || systemControl.phaseBPublicAllowed;
  const sysOk = systemControl.state === 'ACTIVE' && systemControl.publishingEnabled && phaseOk;

  const check6: PreSendCheckItem = {
    id: 'system_control_phase',
    label: '6. Stop All inativo, Publishing habilitado e visibilidade da Fase',
    passed: sysOk,
    detail:
      systemControl.state === 'HALTED'
        ? `Sistema em HALTED (${systemControl.reason}).`
        : !systemControl.publishingEnabled
        ? 'PUBLISHING_ENABLED desligado (modo seguro).'
        : !phaseOk
        ? `Visibilidade 'public' bloqueada na Fase A (permitido apenas private/unlisted).`
        : `Sistema ACTIVE · Visibilidade '${item.visibility}' permitida.`,
  };

  const checks = [check1, check2, check3, check4, check5, check6];
  return {
    canSend: checks.every((c) => c.passed),
    recalculatedHash,
    checks,
  };
}

export interface ProductScoreV61Result {
  score: number | null;
  version: 'v0-hipotese';
  unknownFieldsCount: number;
  missingCriticalFields: string[];
  explanation: string;
}

/**
 * Deterministic `score-6.1` (`v0-hipotese`):
 * - Unknown (`null`) values NEVER become `0`.
 * - If critical economic inputs are missing (`price`, `epcValue`, or both `commissionRatePct` & `cpaValue`),
 *   returns `score: null` so incomplete candidates are never misranked as 0.
 * - Operates strictly within the product's native currency (no FX mixing).
 */
export function scoreProductV61(product: Product): ProductScoreV61Result {
  const missingCriticalFields: string[] = [];
  if (product.price === null) missingCriticalFields.push('price');
  if (product.commissionRatePct === null && product.cpaValue === null) {
    missingCriticalFields.push('remuneration');
  }
  if (product.epcValue === null) missingCriticalFields.push('epc');

  const optionalNulls = [
    product.cookieWindowDays,
    product.demandTrendPct,
  ].filter((v) => v === null).length;

  const unknownFieldsCount = missingCriticalFields.length + optionalNulls;

  if (missingCriticalFields.length > 0) {
    return {
      score: null,
      version: 'v0-hipotese',
      unknownFieldsCount,
      missingCriticalFields,
      explanation: `Score indeterminado (null): campos críticos ausentes (${missingCriticalFields.join(', ')}).`,
    };
  }

  // Deterministic bounded scoring when core variables exist (preserving null optionals without zero-coercion penalty)
  const epc = product.epcValue!;
  const price = product.price!;
  const commPct = product.commissionRatePct ?? 0;
  const cpa = product.cpaValue ?? 0;

  // Normalize EPC relative to ticket/commission strength inside native currency
  const epcComponent = Math.min(38, Math.round((epc / Math.max(1, price * 0.0025)) * 22));
  const remunerationComponent = Math.min(
    26,
    Math.round(commPct * 1.4 + (cpa > 0 ? 10 : 0))
  );
  const cookieComponent =
    product.cookieWindowDays === null
      ? 6 // Neutral baseline when unknown — never treated as 0d
      : product.cookieWindowDays >= 30
      ? 16
      : product.cookieWindowDays >= 7
      ? 11
      : 6;
  const trendComponent =
    product.demandTrendPct === null
      ? 8
      : Math.min(14, Math.max(2, Math.round(8 + product.demandTrendPct * 0.25)));
  const competitionBonus =
    product.competitionLevel === 'Baixa'
      ? 8
      : product.competitionLevel === 'Média'
      ? 5
      : product.competitionLevel === 'Alta'
      ? 2
      : 4;

  const raw = epcComponent + remunerationComponent + cookieComponent + trendComponent + competitionBonus;
  const score = Math.max(1, Math.min(99, raw));

  return {
    score,
    version: 'v0-hipotese',
    unknownFieldsCount,
    missingCriticalFields: [],
    explanation: `Calculado na moeda nativa (${product.currency}) com ${unknownFieldsCount} campo(s) desconhecido(s).`,
  };
}

/**
 * Architecture rule (Lote 6): `products score` never mixes currencies.
 * Rankings are strictly grouped per native currency.
 */
export function groupProductsByCurrency(
  products: Product[]
): Array<{ currency: CurrencyCode; items: Product[] }> {
  const currencies: CurrencyCode[] = ['BRL', 'USD', 'EUR'];
  const groups: Array<{ currency: CurrencyCode; items: Product[] }> = [];

  for (const currency of currencies) {
    const items = products
      .filter((p) => p.currency === currency)
      .sort((a, b) => {
        if (a.opportunityScore === null && b.opportunityScore === null) return 0;
        if (a.opportunityScore === null) return 1;
        if (b.opportunityScore === null) return -1;
        return b.opportunityScore - a.opportunityScore;
      });
    if (items.length > 0) {
      groups.push({ currency, items });
    }
  }
  return groups;
}

export interface FinanceSummary {
  pendingCommissions: number; // Awaiting platform validation — NEVER cash
  confirmedCommercialResult: number; // 12.1.1: Confirmed + Received revenues
  confirmedAwaitingPayout: number; // Approved by platform, not yet received in bank
  receivedCashIn: number; // Realized cash inflows only
  expensesCashOut: number; // Realized operating expenses
  reinvestmentsCashOut: number; // Realized reinvestments
  netRealizedCash: number; // receivedCashIn - expensesCashOut - reinvestmentsCashOut
  availableReinvestmentBudget: number; // Strictly derived from realized net cash >= 0
  projectedFutureRevenue: number; // Explicitly separated projections
  currency: CurrencyCode;
}

/**
 * Strictly separates Pending, Confirmed, Received, and Projections:
 * - `isTest` records are excluded by default so test data never leaks into real totals.
 * - Available reinvestment budget comes ONLY from `netRealizedCash` (never Pending or Confirmed).
 */
export function calculateFinanceSummary(
  entries: FinanceEntry[],
  targetCurrency: CurrencyCode,
  options?: { brandId?: string; period?: PeriodFilter; referenceDate?: string; excludeTest?: boolean }
): FinanceSummary {
  const brandId = options?.brandId;
  const excludeTest = options?.excludeTest ?? true;
  const startDate = options?.period
    ? getPeriodStartDate(options.period, options.referenceDate)
    : '1970-01-01';

  let pendingCommissions = 0;
  let confirmedAwaitingPayout = 0;
  let receivedCashIn = 0;
  let expensesCashOut = 0;
  let reinvestmentsCashOut = 0;
  let projectedFutureRevenue = 0;

  for (const entry of entries) {
    if (excludeTest && entry.isTest) continue;
    if (brandId && brandId !== 'all' && entry.brandId !== brandId) continue;
    if (!entry.isProjection && entry.date < startDate) continue;

    const val = convertCurrency(entry.amount, entry.currency, targetCurrency);

    if (entry.isProjection) {
      if (entry.type === 'Commission' || entry.type === 'DirectRevenue') {
        projectedFutureRevenue += val;
      }
      continue;
    }

    if (entry.type === 'Commission' || entry.type === 'DirectRevenue') {
      if (entry.stage === 'Pending') {
        pendingCommissions += val;
      } else if (entry.stage === 'Confirmed') {
        confirmedAwaitingPayout += val;
      } else if (entry.stage === 'Received') {
        receivedCashIn += val;
      }
    } else if (entry.type === 'Expense') {
      expensesCashOut += val;
    } else if (entry.type === 'Reinvestment') {
      reinvestmentsCashOut += val;
    }
  }

  const confirmedCommercialResult = confirmedAwaitingPayout + receivedCashIn;
  const netRealizedCash = receivedCashIn - expensesCashOut - reinvestmentsCashOut;
  const availableReinvestmentBudget = Math.max(0, netRealizedCash);

  return {
    pendingCommissions,
    confirmedCommercialResult,
    confirmedAwaitingPayout,
    receivedCashIn,
    expensesCashOut,
    reinvestmentsCashOut,
    netRealizedCash,
    availableReinvestmentBudget,
    projectedFutureRevenue,
    currency: targetCurrency,
  };
}

export interface OperationalEfficiencyMetrics {
  totalHumanHours: number;
  realizedCashPerHour: number | null;
  confirmedCommercialPerHour: number | null;
  currency: CurrencyCode;
}

/**
 * Dimensão 2 (ACQUISITION_STRATEGY §12): Eficiência Operacional = Resultado / Hora humana.
 */
export function computeOperationalEfficiency(
  finance: FinanceSummary,
  contents: ContentItem[],
  brandId = 'all'
): OperationalEfficiencyMetrics {
  const totalHumanHours = contents
    .filter((c) => brandId === 'all' || c.brandId === brandId)
    .reduce((sum, c) => sum + (c.humanHoursLogged || 0), 0);

  return {
    totalHumanHours,
    realizedCashPerHour:
      totalHumanHours > 0 ? finance.netRealizedCash / totalHumanHours : null,
    confirmedCommercialPerHour:
      totalHumanHours > 0 ? finance.confirmedCommercialResult / totalHumanHours : null,
    currency: finance.currency,
  };
}

export function transitionProductStatus(
  product: Product,
  nextStatus: ProductStatus,
  justification: string,
  actor = 'Proprietário',
  timestamp = new Date().toISOString()
): Product {
  const trimmed = justification.trim();
  if (!trimmed) {
    throw new Error('Justificativa obrigatória para alteração de status do produto.');
  }
  return {
    ...product,
    status: nextStatus,
    updatedAt: timestamp,
    decisions: [
      {
        id: `dec-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
        previousStatus: product.status,
        newStatus: nextStatus,
        justification: trimmed,
        actor,
        timestamp,
      },
      ...product.decisions,
    ],
  };
}

export function transitionContentStatus(
  item: ContentItem,
  nextStatus: ContentStatus,
  note: string,
  author = 'Proprietário',
  timestamp = new Date().toISOString(),
  feedbackCategory?: ContentVersion['feedbackCategory']
): ContentItem {
  const nextVersionNumber = `v${item.versions.length + 1}.0`;
  const manifestHash = computeContentManifestHash(item);
  // Moving out of Approved/Published clears prior authorization if returning to Draft/Brief/Rejected
  const clearAuth =
    nextStatus === 'Brief' || nextStatus === 'Draft' || nextStatus === 'Rejected';

  return {
    ...item,
    status: nextStatus,
    currentManifestHash: manifestHash,
    authorization: clearAuth ? null : item.authorization,
    publishedAt: nextStatus === 'Published' ? timestamp.slice(0, 10) : item.publishedAt,
    versions: [
      {
        version: nextVersionNumber,
        manifestHash,
        author,
        note: note.trim() || `Status alterado para ${nextStatus}`,
        feedbackCategory,
        timestamp,
        scriptSnapshot: item.script,
      },
      ...item.versions,
    ],
  };
}

export function applyStopAllToAutomations(
  automations: AutomationAgent[],
  timestamp = new Date().toISOString()
): { updated: AutomationAgent[]; stoppedCount: number } {
  let stoppedCount = 0;
  const updated = automations.map((agent) => {
    if (agent.state === 'Running' || agent.state === 'Waiting Approval') {
      stoppedCount += 1;
      return {
        ...agent,
        state: 'Paused' as const,
        history: [
          {
            id: `exec-stop-${Date.now()}-${agent.id}`,
            timestamp,
            status: 'Paused' as const,
            durationSec: 0,
            summary: 'Operação interrompida via comando global Stop All (HALTED).',
            recordsAffected: 0,
          },
          ...agent.history,
        ],
      };
    }
    return agent;
  });
  return { updated, stoppedCount };
}

/**
 * Reconciles stale `running` jobs (Lote 7 / Débito M2: `autopilot jobs reconcile`).
 */
export function reconcileOrphanedJobRuns(
  jobRuns: JobRun[],
  nowIso = new Date().toISOString(),
  olderThanMinutes = 30
): { updated: JobRun[]; reconciledIds: number[] } {
  const nowMs = Date.parse(nowIso);
  const reconciledIds: number[] = [];

  const updated = jobRuns.map((job) => {
    if (job.status !== 'running') return job;
    const ageMinutes = (nowMs - Date.parse(job.startedAt)) / 60_000;
    if (ageMinutes >= olderThanMinutes) {
      reconciledIds.push(job.id);
      return {
        ...job,
        status: 'failed' as const,
        finishedAt: nowIso,
        error: `Reconciliado como órfão após ${Math.round(ageMinutes)} min sem heartbeat.`,
      };
    }
    return job;
  });

  return { updated, reconciledIds };
}

/**
 * Lote 8 rule: `control resume` is blocked while any job_run is `running` or `unknown`.
 */
export function canResumeSystemControl(jobRuns: JobRun[]): {
  allowed: boolean;
  blockingJobIds: number[];
  reason?: string;
} {
  const blocking = jobRuns.filter((j) => j.status === 'running' || j.status === 'unknown');
  if (blocking.length === 0) {
    return { allowed: true, blockingJobIds: [] };
  }
  const ids = blocking.map((j) => j.id);
  return {
    allowed: false,
    blockingJobIds: ids,
    reason: `Resume bloqueado: existem ${blocking.length} execução(ões) pendentes/órfãs (#${ids.join(', #')}). Execute 'jobs reconcile' antes de retomar.`,
  };
}

export interface BrandRollup {
  brand: Brand;
  channelsCount: number;
  productsCount: number;
  approvedProductsCount: number;
  contentsCount: number;
  publishedContentsCount: number;
  totalViews30d: number;
  confirmedCommercial: number;
  receivedCash: number;
  pendingCommissions: number;
  expenses: number;
}

export function computeBrandRollups(
  brands: Brand[],
  channels: Channel[],
  products: Product[],
  contents: ContentItem[],
  financeEntries: FinanceEntry[],
  targetCurrency: CurrencyCode,
  options?: { excludeTest?: boolean }
): BrandRollup[] {
  const excludeTest = options?.excludeTest ?? true;
  return brands.map((brand) => {
    const brandChannels = channels.filter((c) => c.brandId === brand.id);
    const brandProducts = products.filter(
      (p) =>
        (!excludeTest || !p.isTest) &&
        (p.brandId === brand.id || p.linkedBrandIds.includes(brand.id))
    );
    const brandContents = contents.filter((c) => c.brandId === brand.id);
    const fin = calculateFinanceSummary(financeEntries, targetCurrency, {
      brandId: brand.id,
      excludeTest,
    });

    return {
      brand,
      channelsCount: brandChannels.length,
      productsCount: brandProducts.length,
      approvedProductsCount: brandProducts.filter((p) => p.status === 'Approved').length,
      contentsCount: brandContents.length,
      publishedContentsCount: brandContents.filter((c) => c.status === 'Published').length,
      totalViews30d: brandChannels.reduce((acc, c) => acc + c.views30d, 0),
      confirmedCommercial: fin.confirmedCommercialResult,
      receivedCash: fin.receivedCashIn,
      pendingCommissions: fin.pendingCommissions,
      expenses: fin.expensesCashOut + fin.reinvestmentsCashOut,
    };
  });
}

export function filterActivities(
  activities: ActivityEvent[],
  filters: { brandId?: string; category?: ActivityCategory | 'Todas'; period?: PeriodFilter; query?: string }
): ActivityEvent[] {
  const startDate = filters.period ? getPeriodStartDate(filters.period) : '1970-01-01';
  const q = (filters.query ?? '').trim().toLowerCase();

  return activities.filter((ev) => {
    if (filters.brandId && filters.brandId !== 'all' && ev.brandId !== filters.brandId) {
      return false;
    }
    if (filters.category && filters.category !== 'Todas' && ev.category !== filters.category) {
      return false;
    }
    if (ev.timestamp.slice(0, 10) < startDate) {
      return false;
    }
    if (q) {
      const hay = `${ev.action} ${ev.detail} ${ev.justification ?? ''} ${ev.actor}`.toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });
}
