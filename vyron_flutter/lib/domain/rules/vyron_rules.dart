import '../../core/crypto/vyron_crypto.dart';
import '../models/brand_product_models.dart';
import '../models/content_channel_finance_models.dart';
import '../models/operations_settings_models.dart';
import '../models/vyron_enums.dart';

/// Deterministic FX rates relative to BRL (1 unit -> BRL).
/// Used for consolidated reporting in Finance/Overview/Analytics,
/// NEVER inside product scoring ranking (which stays per native currency).
const Map<CurrencyCode, double> fxToBrl = {
  CurrencyCode.brl: 1.0,
  CurrencyCode.usd: 5.72,
  CurrencyCode.eur: 6.18,
};

double convertCurrency(
  double amount,
  CurrencyCode from,
  CurrencyCode to,
) {
  if (from == to) return amount;
  final inBrl = amount * (fxToBrl[from] ?? 1.0);
  return inBrl / (fxToBrl[to] ?? 1.0);
}

String getPeriodStartDate(
  PeriodFilter period, [
  String referenceDate = '2026-11-18',
]) {
  final ref = DateTime.parse('${referenceDate}T00:00:00Z');
  final days = switch (period) {
    PeriodFilter.d7 => 7,
    PeriodFilter.d30 => 30,
    PeriodFilter.d90 => 90,
    PeriodFilter.m12 => 365,
  };
  final shifted = ref.subtract(Duration(days: days));
  return shifted.toIso8601String().substring(0, 10);
}

int? _parseIsoMs(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc().millisecondsSinceEpoch;
}

enum PreSendCheckId {
  hashMatch,
  authValid,
  linkVerified,
  commercialDisclosures,
  riskCompliance,
  systemControlPhase,
}

class PreSendCheckItem {
  const PreSendCheckItem({
    required this.id,
    required this.label,
    required this.passed,
    required this.detail,
  });

  final PreSendCheckId id;
  final String label;
  final bool passed;
  final String detail;
}

class PreSendEvaluation {
  const PreSendEvaluation({
    required this.canSend,
    required this.recalculatedHash,
    required this.checks,
  });

  final bool canSend;
  final String recalculatedHash;
  final List<PreSendCheckItem> checks;
}

/// Evaluates all 6 mandatory pre-send verification gates defined in AUTONOMY_AND_AGENTS.md §4.
PreSendEvaluation evaluateContentPreSendChecks(
  ContentItem item,
  SystemControlState systemControl, {
  String nowIso = '2026-11-18T18:00:00Z',
  int evidenceFreshnessMaxHours = 48,
  UiLanguage language = UiLanguage.ptBR,
}) {
  final en = language == UiLanguage.enUS;
  final nowMs = _parseIsoMs(nowIso) ?? 0;
  final recalculatedHash = computeContentItemManifestHash(item);
  final auth = item.authorization;

  // 1. Hash match
  final hashMatch = auth != null && auth.authorizedHash == recalculatedHash;
  final check1 = PreSendCheckItem(
    id: PreSendCheckId.hashMatch,
    label: en
        ? '1. Manifest SHA-256 hash matches authorized version'
        : '1. Hash SHA-256 do manifesto coincide com versão autorizada',
    passed: hashMatch,
    detail: auth == null
        ? (en
            ? 'No authorization linked to this version.'
            : 'Nenhuma autorização vinculada a esta versão.')
        : hashMatch
            ? (en
                ? 'Hash intact (${recalculatedHash.substring(0, 12)}...).'
                : 'Hash íntegro (${recalculatedHash.substring(0, 12)}...).')
            : (en
                ? 'Mismatch detected: content edited after authorization (zero inheritance).'
                : 'Divergência detectada: conteúdo alterado após autorização (herança zero).'),
  );

  // 2. Authorization active & not expired (and within offer window)
  final expiresMs = _parseIsoMs(auth?.expiresAt);
  final offerEndsMs = _parseIsoMs(item.offerEndsAt);
  final notRevoked = auth != null && auth.revoked != true;
  final notExpired = expiresMs != null && nowMs < expiresMs;
  final withinOfferWindow = item.offerEndsAt == null ||
      (offerEndsMs != null &&
          nowMs <= offerEndsMs &&
          (expiresMs == null || expiresMs <= offerEndsMs));

  final authValid = notRevoked && notExpired && withinOfferWindow;
  final expiresFormatted =
      auth != null ? auth.expiresAt.substring(0, 16).replaceFirst('T', ' ') : '';
  final offerDatePrefix =
      item.offerEndsAt != null && item.offerEndsAt!.length >= 10
          ? item.offerEndsAt!.substring(0, 10)
          : item.offerEndsAt ?? '';

  final check2 = PreSendCheckItem(
    id: PreSendCheckId.authValid,
    label: en
        ? '2. Authorization active, not revoked, and within offer window'
        : '2. Autorização vigente, não revogada e dentro da validade da oferta',
    passed: authValid,
    detail: auth == null
        ? (en
            ? 'Awaiting individual authorization with expiration timestamp.'
            : 'Aguardando autorização individual com prazo de expiração.')
        : auth.revoked == true
            ? (en
                ? 'Authorization revoked: ${auth.revokedReason ?? 'No reason recorded'}.'
                : 'Autorização revogada: ${auth.revokedReason ?? 'Sem motivo registrado'}.')
            : !notExpired
                ? (en
                    ? 'Authorization expired at $expiresFormatted.'
                    : 'Autorização expirada em $expiresFormatted.')
                : !withinOfferWindow
                    ? (en
                        ? 'Offer window ($offerDatePrefix) incompatible or expired.'
                        : 'Janela da oferta ($offerDatePrefix) incompatível ou expirada.')
                    : (en
                        ? 'Valid until $expiresFormatted.'
                        : 'Válida até $expiresFormatted.'),
  );

  // 3. Affiliate link destination verified & fresh
  final isCommercial = item.category == ContentCategory.comercialContextual ||
      (item.productId != null && item.productId!.isNotEmpty) ||
      item.affiliateLinkUrl.trim().isNotEmpty;
  final linkVerifiedMs = _parseIsoMs(item.linkVerifiedAt);
  final linkFresh = linkVerifiedMs != null &&
      (nowMs - linkVerifiedMs) / 3600000.0 <= evidenceFreshnessMaxHours;
  final linkOk = !isCommercial ||
      (item.affiliateLinkUrl.trim().isNotEmpty &&
          item.verifiedDestinationUrl.trim().isNotEmpty &&
          linkFresh);

  final check3 = PreSendCheckItem(
    id: PreSendCheckId.linkVerified,
    label: en
        ? '3. Commercial link and destination recently verified'
        : '3. Link e destino comercial verificados recentemente',
    passed: linkOk,
    detail: !isCommercial
        ? (en
            ? 'Purely editorial item with no commercial link.'
            : 'Peça puramente editorial sem link comercial.')
        : (item.affiliateLinkUrl.trim().isEmpty ||
                item.verifiedDestinationUrl.trim().isEmpty)
            ? (en
                ? 'Commercial URL or verified destination missing.'
                : 'URL comercial ou destino verificado ausente.')
            : !linkFresh
                ? (en
                    ? 'Link verification expired (> ${evidenceFreshnessMaxHours}h). Revalidate destination.'
                    : 'Verificação de link expirada (> ${evidenceFreshnessMaxHours}h). Revalide o destino.')
                : (en
                    ? 'Destination verified (${item.verifiedDestinationUrl}).'
                    : 'Destino verificado (${item.verifiedDestinationUrl}).'),
  );

  // 4. Commercial conditions, 7-point relevance, 9-point checklist & disclosures
  final condMs = _parseIsoMs(item.commercialConditionsVerifiedAt);
  final condFresh = condMs != null &&
      (nowMs - condMs) / 3600000.0 <= evidenceFreshnessMaxHours;
  final affDiscOk = !isCommercial || item.affiliateDisclosure.trim().isNotEmpty;
  final aiDiscOk =
      !item.aiDisclosureRequired || item.aiDisclosureText.trim().isNotEmpty;
  final gatesOk = item.relevanceTestPassed &&
      item.editorialChecklistPassed &&
      (!isCommercial || condFresh) &&
      affDiscOk &&
      aiDiscOk;

  final missingDetails = <String>[];
  if (!item.relevanceTestPassed) {
    missingDetails.add(
      en ? 'relevance check (7 pts)' : 'teste de relevância (7 pts)',
    );
  }
  if (!item.editorialChecklistPassed) {
    missingDetails.add(
      en ? 'editorial checklist (9 pts)' : 'checklist editorial (9 pts)',
    );
  }
  if (isCommercial && !condFresh) {
    missingDetails.add(
      en ? 'fresh commercial conditions' : 'condições comerciais recentes',
    );
  }
  if (!affDiscOk) {
    missingDetails.add(
      en ? 'affiliate disclosure' : 'divulgação de afiliação',
    );
  }
  if (!aiDiscOk) {
    missingDetails.add(
      en ? 'generative AI disclosure' : 'divulgação de IA generativa',
    );
  }

  final check4 = PreSendCheckItem(
    id: PreSendCheckId.commercialDisclosures,
    label: en
        ? '4. Commercial evidence, checklists & mandatory disclosures'
        : '4. Evidência comercial, checklists e divulgações obrigatórias',
    passed: gatesOk,
    detail: gatesOk
        ? (en
            ? 'Relevance, editorial checklist, conditions, and disclosures compliant.'
            : 'Relevância, checklist editorial, condições e divulgações em conformidade.')
        : (en
            ? 'Pending: ${missingDetails.join(', ')}.'
            : 'Pendente: ${missingDetails.join(', ')}.'),
  );

  // 5. Risk classification & sensitive topic individual gate
  final hasSensitiveTopic = item.sensitiveTopic != SensitiveTopic.nenhum;
  final sensitiveIndividualOk =
      !hasSensitiveTopic || auth?.type == AuthorizationType.individual;
  final riskOk = !item.unclassifiedRiskFlag && sensitiveIndividualOk;

  final check5 = PreSendCheckItem(
    id: PreSendCheckId.riskCompliance,
    label: en
        ? '5. Risk classification & sensitive-topic safeguard'
        : '5. Classificação de risco e trava para temas sensíveis',
    passed: riskOk,
    detail: item.unclassifiedRiskFlag
        ? (en
            ? 'Blocked: item flagged with unclassified risk.'
            : 'Bloqueado: item marcado com risco não classificado.')
        : (hasSensitiveTopic && auth?.type != AuthorizationType.individual)
            ? (en
                ? 'Sensitive topic (${item.sensitiveTopic.wire}) requires individual human authorization.'
                : 'Tema sensível (${item.sensitiveTopic.wire}) exige autorização individual humana.')
            : hasSensitiveTopic
                ? (en
                    ? 'Sensitive topic (${item.sensitiveTopic.wire}) has individual authorization recorded.'
                    : 'Tema sensível (${item.sensitiveTopic.wire}) com autorização individual registrada.')
                : (en
                    ? 'No unclassified risk flags.'
                    : 'Sem sinalizadores de risco não classificado.'),
  );

  // 6. SystemControl ACTIVE + Automated Publishing + Environment visibility gate
  final phaseOk = item.visibility != ContentVisibility.publicVis ||
      systemControl.phaseBPublicAllowed;
  final sysOk = systemControl.state == SystemControlStatus.active &&
      systemControl.publishingEnabled &&
      phaseOk;

  final visLabel = switch (item.visibility) {
    ContentVisibility.publicVis => en ? 'Public' : 'Público',
    ContentVisibility.unlisted => en ? 'Unlisted' : 'Não listado',
    ContentVisibility.privateVis => en ? 'Private' : 'Privado',
  };

  final check6 = PreSendCheckItem(
    id: PreSendCheckId.systemControlPhase,
    label: en
        ? '6. Stop All inactive, automated publishing enabled & environment visibility'
        : '6. Stop All inativo, publicação automática habilitada e visibilidade permitida',
    passed: sysOk,
    detail: systemControl.state == SystemControlStatus.halted
        ? (en
            ? 'System halted (${systemControl.reason}).'
            : 'Sistema interrompido (${systemControl.reason}).')
        : !systemControl.publishingEnabled
            ? (en
                ? 'Automated publishing disabled (safe mode).'
                : 'Publicação automática desligada (modo seguro).')
            : !phaseOk
                ? (en
                    ? 'Public visibility is blocked in the private environment (only private/unlisted allowed).'
                    : 'Visibilidade pública bloqueada no ambiente privado (apenas privado ou não listado).')
                : (en
                    ? 'System active · Visibility "$visLabel" allowed.'
                    : "Sistema ativo · Visibilidade '$visLabel' permitida."),
  );

  final checks = [check1, check2, check3, check4, check5, check6];
  return PreSendEvaluation(
    canSend: checks.every((c) => c.passed),
    recalculatedHash: recalculatedHash,
    checks: checks,
  );
}

class ProductScoreV61Result {
  const ProductScoreV61Result({
    required this.score,
    required this.version,
    required this.unknownFieldsCount,
    required this.missingCriticalFields,
    required this.explanation,
  });

  final int? score;
  final String version;
  final int unknownFieldsCount;
  final List<String> missingCriticalFields;
  final String explanation;
}

/// Deterministic `score-6.1` (`v0-hipotese`):
/// - Unknown (`null`) values NEVER become `0`.
/// - Operates strictly within the product's native currency (no FX mixing).
ProductScoreV61Result scoreProductV61(
  Product product, {
  UiLanguage language = UiLanguage.ptBR,
}) {
  final en = language == UiLanguage.enUS;
  final missingCriticalFields = <String>[];
  if (product.price == null) {
    missingCriticalFields.add(en ? 'price' : 'preço');
  }
  if (product.commissionRatePct == null && product.cpaValue == null) {
    missingCriticalFields.add(en ? 'payout' : 'remuneração');
  }
  if (product.epcValue == null) {
    missingCriticalFields.add('EPC');
  }

  var optionalNulls = 0;
  if (product.cookieWindowDays == null) optionalNulls++;
  if (product.demandTrendPct == null) optionalNulls++;

  final unknownFieldsCount = missingCriticalFields.length + optionalNulls;

  if (missingCriticalFields.isNotEmpty) {
    return ProductScoreV61Result(
      score: null,
      version: 'v0-hipotese',
      unknownFieldsCount: unknownFieldsCount,
      missingCriticalFields: missingCriticalFields,
      explanation: en
          ? 'Indeterminate index (no data): missing critical fields (${missingCriticalFields.join(', ')}).'
          : 'Índice indeterminado (sem dados): campos críticos ausentes (${missingCriticalFields.join(', ')}).',
    );
  }

  final epc = product.epcValue!;
  final price = product.price!;
  final commPct = product.commissionRatePct ?? 0;
  final cpa = product.cpaValue ?? 0;

  final denominator = (price * 0.0025) > 1.0 ? (price * 0.0025) : 1.0;
  final epcComponent = (((epc / denominator) * 22).round()).clamp(0, 38);
  final remunerationComponent =
      ((commPct * 1.4 + (cpa > 0 ? 10 : 0)).round()).clamp(0, 26);

  final cookieDays = product.cookieWindowDays;
  final cookieComponent = cookieDays == null
      ? 6
      : cookieDays >= 30
          ? 16
          : cookieDays >= 7
              ? 11
              : 6;

  final demandTrend = product.demandTrendPct;
  final trendComponent = demandTrend == null
      ? 8
      : ((8 + demandTrend * 0.25).round()).clamp(2, 14);

  final competitionBonus = switch (product.competitionLevel) {
    CompetitionLevel.baixa => 8,
    CompetitionLevel.media => 5,
    CompetitionLevel.alta => 2,
    CompetitionLevel.desconhecida => 4,
  };

  final raw = epcComponent +
      remunerationComponent +
      cookieComponent +
      trendComponent +
      competitionBonus;
  final score = raw.clamp(1, 99);

  return ProductScoreV61Result(
    score: score,
    version: 'v0-hipotese',
    unknownFieldsCount: unknownFieldsCount,
    missingCriticalFields: const [],
    explanation: en
        ? 'Computed in native currency (${product.currency.wire}) with $unknownFieldsCount missing field(s).'
        : 'Calculado na moeda nativa (${product.currency.wire}) com $unknownFieldsCount campo(s) sem dados.',
  );
}

class CurrencyProductGroup {
  const CurrencyProductGroup({
    required this.currency,
    required this.items,
  });

  final CurrencyCode currency;
  final List<Product> items;
}

/// Strictly groups product rankings per native currency (never mixing BRL/USD/EUR).
List<CurrencyProductGroup> groupProductsByCurrency(List<Product> products) {
  const currencies = [CurrencyCode.brl, CurrencyCode.usd, CurrencyCode.eur];
  final groups = <CurrencyProductGroup>[];

  for (final currency in currencies) {
    final items = products.where((p) => p.currency == currency).toList()
      ..sort((a, b) {
        if (a.opportunityScore == null && b.opportunityScore == null) return 0;
        if (a.opportunityScore == null) return 1;
        if (b.opportunityScore == null) return -1;
        return b.opportunityScore!.compareTo(a.opportunityScore!);
      });
    if (items.isNotEmpty) {
      groups.add(CurrencyProductGroup(currency: currency, items: items));
    }
  }
  return groups;
}

class FinanceSummary {
  const FinanceSummary({
    required this.pendingCommissions,
    required this.confirmedCommercialResult,
    required this.confirmedAwaitingPayout,
    required this.receivedCashIn,
    required this.expensesCashOut,
    required this.reinvestmentsCashOut,
    required this.netRealizedCash,
    required this.availableReinvestmentBudget,
    required this.projectedFutureRevenue,
    required this.currency,
  });

  final double pendingCommissions;
  final double confirmedCommercialResult;
  final double confirmedAwaitingPayout;
  final double receivedCashIn;
  final double expensesCashOut;
  final double reinvestmentsCashOut;
  final double netRealizedCash;
  final double availableReinvestmentBudget;
  final double projectedFutureRevenue;
  final CurrencyCode currency;
}

/// Strictly separates Pending, Confirmed, Received, Projections, and excludes `isTest`.
FinanceSummary calculateFinanceSummary(
  List<FinanceEntry> entries,
  CurrencyCode targetCurrency, {
  String? brandId,
  PeriodFilter? period,
  String referenceDate = '2026-11-18',
  bool excludeTest = true,
}) {
  final startDate =
      period != null ? getPeriodStartDate(period, referenceDate) : '1970-01-01';

  var pendingCommissions = 0.0;
  var confirmedAwaitingPayout = 0.0;
  var receivedCashIn = 0.0;
  var expensesCashOut = 0.0;
  var reinvestmentsCashOut = 0.0;
  var projectedFutureRevenue = 0.0;

  for (final entry in entries) {
    if (excludeTest && entry.isTest) continue;
    if (brandId != null && brandId != 'all' && entry.brandId != brandId) {
      continue;
    }
    if (!entry.isProjection && entry.date.compareTo(startDate) < 0) continue;

    final val = convertCurrency(entry.amount, entry.currency, targetCurrency);

    if (entry.isProjection) {
      if (entry.type == FinanceEntryType.commission ||
          entry.type == FinanceEntryType.directRevenue) {
        projectedFutureRevenue += val;
      }
      continue;
    }

    if (entry.type == FinanceEntryType.commission ||
        entry.type == FinanceEntryType.directRevenue) {
      switch (entry.stage) {
        case CommissionStage.pending:
          pendingCommissions += val;
        case CommissionStage.confirmed:
          confirmedAwaitingPayout += val;
        case CommissionStage.received:
          receivedCashIn += val;
      }
    } else if (entry.type == FinanceEntryType.expense) {
      expensesCashOut += val;
    } else if (entry.type == FinanceEntryType.reinvestment) {
      reinvestmentsCashOut += val;
    }
  }

  final confirmedCommercialResult = confirmedAwaitingPayout + receivedCashIn;
  final netRealizedCash =
      receivedCashIn - expensesCashOut - reinvestmentsCashOut;
  final availableReinvestmentBudget =
      netRealizedCash > 0 ? netRealizedCash : 0.0;

  return FinanceSummary(
    pendingCommissions: pendingCommissions,
    confirmedCommercialResult: confirmedCommercialResult,
    confirmedAwaitingPayout: confirmedAwaitingPayout,
    receivedCashIn: receivedCashIn,
    expensesCashOut: expensesCashOut,
    reinvestmentsCashOut: reinvestmentsCashOut,
    netRealizedCash: netRealizedCash,
    availableReinvestmentBudget: availableReinvestmentBudget,
    projectedFutureRevenue: projectedFutureRevenue,
    currency: targetCurrency,
  );
}

class OperationalEfficiencyMetrics {
  const OperationalEfficiencyMetrics({
    required this.totalHumanHours,
    required this.realizedCashPerHour,
    required this.confirmedCommercialPerHour,
    required this.currency,
  });

  final double totalHumanHours;
  final double? realizedCashPerHour;
  final double? confirmedCommercialPerHour;
  final CurrencyCode currency;
}

OperationalEfficiencyMetrics computeOperationalEfficiency(
  FinanceSummary finance,
  List<ContentItem> contents, {
  String brandId = 'all',
}) {
  final totalHumanHours = contents
      .where((c) => brandId == 'all' || c.brandId == brandId)
      .fold<double>(0.0, (sum, c) => sum + c.humanHoursLogged);

  return OperationalEfficiencyMetrics(
    totalHumanHours: totalHumanHours,
    realizedCashPerHour:
        totalHumanHours > 0 ? finance.netRealizedCash / totalHumanHours : null,
    confirmedCommercialPerHour: totalHumanHours > 0
        ? finance.confirmedCommercialResult / totalHumanHours
        : null,
    currency: finance.currency,
  );
}

Product transitionProductStatus(
  Product product,
  ProductStatus nextStatus,
  String justification, {
  String actor = 'Proprietário',
  String? timestamp,
}) {
  final trimmed = justification.trim();
  if (trimmed.isEmpty) {
    throw StateError(
      'Justificativa obrigatória para alteração de status do produto.',
    );
  }
  final ts = timestamp ?? DateTime.now().toUtc().toIso8601String();
  final decId =
      'dec-${DateTime.now().millisecondsSinceEpoch}-${product.decisions.length}';
  return product.copyWith(
    status: nextStatus,
    updatedAt: ts,
    decisions: [
      ProductDecisionLog(
        id: decId,
        previousStatus: product.status,
        newStatus: nextStatus,
        justification: trimmed,
        actor: actor,
        timestamp: ts,
      ),
      ...product.decisions,
    ],
  );
}

ContentItem transitionContentStatus(
  ContentItem item,
  ContentStatus nextStatus,
  String note, {
  String author = 'Proprietário',
  String? timestamp,
  FeedbackCategory? feedbackCategory,
}) {
  final ts = timestamp ?? DateTime.now().toUtc().toIso8601String();
  final nextVersionNumber = 'v${item.versions.length + 1}.0';
  final manifestHash = computeContentItemManifestHash(item);
  final clearAuth = nextStatus == ContentStatus.brief ||
      nextStatus == ContentStatus.draft ||
      nextStatus == ContentStatus.rejected;

  return item.copyWith(
    status: nextStatus,
    currentManifestHash: manifestHash,
    clearAuthorization: clearAuth,
    publishedAt:
        nextStatus == ContentStatus.published && ts.length >= 10
            ? ts.substring(0, 10)
            : item.publishedAt,
    versions: [
      ContentVersion(
        version: nextVersionNumber,
        manifestHash: manifestHash,
        author: author,
        note: note.trim().isNotEmpty
            ? note.trim()
            : 'Status alterado para ${nextStatus.wire}',
        feedbackCategory: feedbackCategory,
        timestamp: ts,
        scriptSnapshot: item.script,
      ),
      ...item.versions,
    ],
  );
}

class StopAllResult {
  const StopAllResult({required this.updated, required this.stoppedCount});
  final List<AutomationAgent> updated;
  final int stoppedCount;
}

StopAllResult applyStopAllToAutomations(
  List<AutomationAgent> automations, {
  String? timestamp,
  UiLanguage language = UiLanguage.ptBR,
}) {
  final en = language == UiLanguage.enUS;
  final ts = timestamp ?? DateTime.now().toUtc().toIso8601String();
  var stoppedCount = 0;

  final updated = automations.map((agent) {
    if (agent.state == AgentRunState.running ||
        agent.state == AgentRunState.waitingApproval) {
      stoppedCount += 1;
      return agent.copyWith(
        state: AgentRunState.paused,
        history: [
          AgentExecutionLog(
            id: 'exec-stop-${DateTime.now().millisecondsSinceEpoch}-${agent.id}',
            timestamp: ts,
            status: AgentExecutionStatus.paused,
            durationSec: 0,
            summary: en
                ? 'Operation halted via global Stop All command.'
                : 'Operação interrompida via comando global Stop All.',
            recordsAffected: 0,
          ),
          ...agent.history,
        ],
      );
    }
    return agent;
  }).toList();

  return StopAllResult(updated: updated, stoppedCount: stoppedCount);
}

class ReconcileJobsResult {
  const ReconcileJobsResult({
    required this.updated,
    required this.reconciledIds,
  });
  final List<JobRun> updated;
  final List<int> reconciledIds;
}

ReconcileJobsResult reconcileOrphanedJobRuns(
  List<JobRun> jobRuns, {
  String? nowIso,
  int olderThanMinutes = 30,
  UiLanguage language = UiLanguage.ptBR,
}) {
  final en = language == UiLanguage.enUS;
  final effectiveNowIso = nowIso ?? DateTime.now().toUtc().toIso8601String();
  final nowMs = _parseIsoMs(effectiveNowIso) ?? 0;
  final reconciledIds = <int>[];

  final updated = jobRuns.map((job) {
    if (job.status != JobRunStatus.running) return job;
    final startedMs = _parseIsoMs(job.startedAt) ?? nowMs;
    final ageMinutes = (nowMs - startedMs) / 60000.0;
    if (ageMinutes >= olderThanMinutes) {
      reconciledIds.add(job.id);
      return job.copyWith(
        status: JobRunStatus.failed,
        finishedAt: effectiveNowIso,
        error: en
            ? 'Reconciled as stalled after ${ageMinutes.round()} min without heartbeat.'
            : 'Reconciliado como pendente após ${ageMinutes.round()} min sem resposta.',
      );
    }
    return job;
  }).toList();

  return ReconcileJobsResult(updated: updated, reconciledIds: reconciledIds);
}

class ResumeControlGate {
  const ResumeControlGate({
    required this.allowed,
    required this.blockingJobIds,
    this.reason,
  });
  final bool allowed;
  final List<int> blockingJobIds;
  final String? reason;
}

ResumeControlGate canResumeSystemControl(
  List<JobRun> jobRuns, {
  UiLanguage language = UiLanguage.ptBR,
}) {
  final en = language == UiLanguage.enUS;
  final blocking = jobRuns
      .where(
        (j) =>
            j.status == JobRunStatus.running ||
            j.status == JobRunStatus.unknown,
      )
      .toList();
  if (blocking.isEmpty) {
    return const ResumeControlGate(allowed: true, blockingJobIds: []);
  }
  final ids = blocking.map((j) => j.id).toList();
  return ResumeControlGate(
    allowed: false,
    blockingJobIds: ids,
    reason: en
        ? 'Resume blocked: ${blocking.length} pending run(s) detected (#${ids.join(', #')}). Reconcile runs before resuming.'
        : 'Retomada bloqueada: existem ${blocking.length} execução(ões) pendente(s) (#${ids.join(', #')}). Reconcilie as execuções antes de retomar.',
  );
}

class BrandRollup {
  const BrandRollup({
    required this.brand,
    required this.channelsCount,
    required this.productsCount,
    required this.approvedProductsCount,
    required this.contentsCount,
    required this.publishedContentsCount,
    required this.totalViews30d,
    required this.confirmedCommercial,
    required this.receivedCash,
    required this.pendingCommissions,
    required this.expenses,
  });

  final Brand brand;
  final int channelsCount;
  final int productsCount;
  final int approvedProductsCount;
  final int contentsCount;
  final int publishedContentsCount;
  final int totalViews30d;
  final double confirmedCommercial;
  final double receivedCash;
  final double pendingCommissions;
  final double expenses;
}

List<BrandRollup> computeBrandRollups(
  List<Brand> brands,
  List<Channel> channels,
  List<Product> products,
  List<ContentItem> contents,
  List<FinanceEntry> financeEntries,
  CurrencyCode targetCurrency, {
  bool excludeTest = true,
}) {
  return brands.map((brand) {
    final brandChannels =
        channels.where((c) => c.brandId == brand.id).toList();
    final brandProducts = products
        .where(
          (p) =>
              (!excludeTest || !p.isTest) &&
              (p.brandId == brand.id || p.linkedBrandIds.contains(brand.id)),
        )
        .toList();
    final brandContents =
        contents.where((c) => c.brandId == brand.id).toList();
    final fin = calculateFinanceSummary(
      financeEntries,
      targetCurrency,
      brandId: brand.id,
      excludeTest: excludeTest,
    );

    return BrandRollup(
      brand: brand,
      channelsCount: brandChannels.length,
      productsCount: brandProducts.length,
      approvedProductsCount:
          brandProducts.where((p) => p.status == ProductStatus.approved).length,
      contentsCount: brandContents.length,
      publishedContentsCount:
          brandContents.where((c) => c.status == ContentStatus.published).length,
      totalViews30d: brandChannels.fold<int>(0, (acc, c) => acc + c.views30d),
      confirmedCommercial: fin.confirmedCommercialResult,
      receivedCash: fin.receivedCashIn,
      pendingCommissions: fin.pendingCommissions,
      expenses: fin.expensesCashOut + fin.reinvestmentsCashOut,
    );
  }).toList();
}

List<ActivityEvent> filterActivities(
  List<ActivityEvent> activities, {
  String? brandId,
  ActivityCategory? category,
  PeriodFilter? period,
  String? query,
}) {
  final startDate =
      period != null ? getPeriodStartDate(period) : '1970-01-01';
  final q = (query ?? '').trim().toLowerCase();

  return activities.where((ev) {
    if (brandId != null && brandId != 'all' && ev.brandId != brandId) {
      return false;
    }
    if (category != null && ev.category != category) {
      return false;
    }
    final datePart =
        ev.timestamp.length >= 10 ? ev.timestamp.substring(0, 10) : ev.timestamp;
    if (datePart.compareTo(startDate) < 0) {
      return false;
    }
    if (q.isNotEmpty) {
      final hay =
          '${ev.action} ${ev.detail} ${ev.justification ?? ''} ${ev.actor}'
              .toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }).toList();
}
