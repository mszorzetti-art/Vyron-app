import '../../domain/models/brand_product_models.dart';
import '../../domain/models/content_channel_finance_models.dart';
import '../../domain/models/operations_settings_models.dart';
import '../../domain/models/vyron_enums.dart';

/// Pure translation helper for seed records:
/// - In PT-BR, returns the cleaned/current PT-BR display text.
/// - In EN-US, returns the EN-US translation ONLY when [currentVal] == [seedPt]
///   (so user-edited or newly created text stays verbatim without mutating state).
String txSeed(
  UiLanguage lang,
  String? seedPt,
  String? enText,
  String currentVal,
) {
  if (lang == UiLanguage.enUS &&
      seedPt != null &&
      enText != null &&
      currentVal == seedPt) {
    return enText;
  }
  return currentVal;
}

String localizeActor(String actor, UiLanguage lang) {
  final trimmed = actor.trim();
  if (trimmed == 'Proprietário' || trimmed == 'Owner') {
    return lang == UiLanguage.enUS ? 'Owner' : 'Proprietário';
  }
  return actor;
}

String localizeSystemControlReason(String reason, UiLanguage lang) {
  final trimmed = reason.trim();
  if (trimmed ==
          'Operação controlada em Fase A (publicação automática desligada).' ||
      trimmed ==
          'Controlled Phase A operation (automated publishing disabled).') {
    return lang == UiLanguage.enUS
        ? 'Controlled Phase A operation (automated publishing disabled).'
        : 'Operação controlada em Fase A (publicação automática desligada).';
  }
  if (trimmed == 'Stop All acionado pelo proprietário via Settings.' ||
      trimmed == 'Stop All triggered by owner via Settings.') {
    return lang == UiLanguage.enUS
        ? 'Stop All triggered by owner via Settings.'
        : 'Stop All acionado pelo proprietário via Settings.';
  }
  if (trimmed == 'Retomada após reconciliação via Settings.' ||
      trimmed == 'Resumed after reconciliation via Settings.') {
    return lang == UiLanguage.enUS
        ? 'Resumed after reconciliation via Settings.'
        : 'Retomada após reconciliação via Settings.';
  }
  return reason;
}

class _BrandEnTranslation {
  const _BrandEnTranslation({
    required this.niche,
    required this.segment,
    required this.tagline,
    required this.description,
    required this.typographyNote,
    required this.pillars,
  });

  final String niche;
  final String segment;
  final String tagline;
  final String description;
  final String typographyNote;
  final List<String> pillars;
}

const Map<String, _BrandEnTranslation> _brandTranslations = {
  'brand-apex': _BrandEnTranslation(
    niche: 'Hardware & Productivity Setups',
    segment: 'Tech Reviews & High-Ticket Affiliate',
    tagline: 'Applied engineering for the workspace.',
    description: 'Editorial and commercial operation focused on mechanical keyboards, OLED monitors, and high-precision ergonomics for tech professionals in Brazil (CDC/CONAR compliance).',
    typographyNote: 'Plus Jakarta Sans + JetBrains Mono for benchmarks',
    pillars: [
      'Desk Ergonomics & Biomechanics',
      'Precision Peripherals & Latency',
      'Monitors & Color Accuracy for Code',
      'Cable Architecture & USB-C Hubs',
    ],
  ),
  'brand-nordic': _BrandEnTranslation(
    niche: 'Minimalist Workspace & Industrial Design',
    segment: 'Digital Products & Curated Gear Affiliate',
    tagline: 'Quiet precision for modern work.',
    description: 'International brand prepared for the EU/France pilot (Loi 2023-451 / DSA), focused on architectural desk setups and digital ergonomics guides.',
    typographyNote: 'Manrope + tabular numerals',
    pillars: [
      'Asymmetric Lighting & OLED Contrast',
      'Industrial Design & Durable Materials',
      'Digital Workstation Blueprints',
    ],
  ),
  'brand-kinetix': _BrandEnTranslation(
    niche: 'Acoustics, IEMs & Audio Production',
    segment: 'Audio Gear & Software Plugins',
    tagline: 'Clarity measured in decibels.',
    description: 'Technical channel and portal specializing in audio interfaces, dynamic microphones, and DSP suites monetized via PartnerStack and Amazon Global.',
    typographyNote: 'Outfit + IBM Plex Mono',
    pillars: [
      'Vocal Capture in Untreated Rooms',
      'DSP & Real-Time Signal Processing',
      'Reference Monitoring & Acoustics',
    ],
  ),
  'brand-veloce': _BrandEnTranslation(
    niche: 'Home Automation & Smart Living',
    segment: 'Connected Home',
    tagline: 'Quiet domestic routines.',
    description: 'Vertical on tactical pause for Matter/Thread portfolio review and direct partnership renegotiation.',
    typographyNote: 'DM Sans',
    pillars: [
      'Local Matter & Thread Protocol',
      'Residential Energy Efficiency',
      'Silent Cloud-Free Automation',
    ],
  ),
};

Brand localizeBrand(Brand brand, UiLanguage lang) {
  final map = _brandTranslations[brand.id];
  if (map == null || lang == UiLanguage.ptBR) return brand;
  return brand.copyWith(
    niche: map.niche,
    segment: map.segment,
    tagline: map.tagline,
    description: map.description,
    typographyNote: map.typographyNote,
    pillars: map.pillars,
  );
}

class _ProductTranslation {
  const _ProductTranslation({
    this.enName,
    this.enCategory,
    this.enEvidenceSummaries = const {},
    this.enDecisionJustifications = const {},
  });

  final String? enName;
  final String? enCategory;
  final Map<String, String> enEvidenceSummaries;
  final Map<String, String> enDecisionJustifications;
}

const Map<String, _ProductTranslation> _productTranslations = {
  'prod-keychron-q1': _ProductTranslation(
    enCategory: 'Mechanical Keyboards',
    enEvidenceSummaries: {
      'ev-1': '+24% search growth for "wireless custom keyboard" over the last 90 days.',
      'ev-2': '4.8% average conversion rate across comparative reviews over 12 minutes.',
    },
    enDecisionJustifications: {
      'dec-1': r'EPC above R$ 2.00 with strong retention among software engineering audiences.',
    },
  ),
  'prod-dell-oled': _ProductTranslation(
    enName: 'Dell UltraSharp 32" 4K Monitor',
    enCategory: 'Professional Monitors',
    enEvidenceSummaries: {
      'ev-3': 'Extended 30-day cookie window + CPA bonus on corporate orders.',
    },
    enDecisionJustifications: {
      'dec-2': 'High ticket with a 30-day cookie and low saturation on Brazilian YouTube.',
    },
  ),
  'prod-benq-halo': _ProductTranslation(
    enCategory: 'Desk Lighting',
    enEvidenceSummaries: {
      'ev-4': 'Minimalist desk setup pins with ScreenBar achieve 2.3x account average CTR.',
    },
    enDecisionJustifications: {
      'dec-3': 'Recurring conversion via Pinterest and YouTube Shorts for US/EU audiences.',
    },
  ),
  'prod-ergo-chair-x': _ProductTranslation(
    enCategory: 'Ergonomic Chairs',
    enEvidenceSummaries: {
      'ev-5': 'Signal spotted across 14 r/battlestations threads with explicit purchase intent.',
    },
  ),
  'prod-shure-mv7x': _ProductTranslation(
    enCategory: 'Dynamic Microphones',
    enEvidenceSummaries: {
      'ev-6': 'Monthly search volume grew 22% with low supply in practical comparisons.',
    },
    enDecisionJustifications: {
      'dec-4': 'Strong synergy with acoustic treatment scripts for creators.',
    },
  ),
  'prod-izotope-rx': _ProductTranslation(
    enCategory: 'DSP Software',
    enEvidenceSummaries: {
      'ev-7': '18% commission with low refund rate (1.2%) on digital licenses.',
    },
  ),
  'prod-unknown-epc': _ProductTranslation(
    enName: 'Loupedeck CT Console (EU Batch)',
    enCategory: 'Workflow Controllers',
    enEvidenceSummaries: {
      'ev-unknown': 'EPC and cookie window omitted by advertiser in initial feed (kept as null).',
    },
  ),
  'prod-cheap-hub': _ProductTranslation(
    enName: 'Generic 11-in-1 USB Hub',
    enCategory: 'Accessories',
    enEvidenceSummaries: {
      'ev-8': r'Net margin per click well below Apex operational floor (R$ 1.00 EPC).',
    },
    enDecisionJustifications: {
      'dec-5': 'Low ticket, high return rate, and Grade C quality misaligned with positioning.',
    },
  ),
  'prod-aqara-hub': _ProductTranslation(
    enCategory: 'Smart Home',
    enDecisionJustifications: {
      'dec-6': 'Temporarily archived due to tactical pause of the Veloce Casa brand.',
    },
  ),
  'prod-seed-test': _ProductTranslation(
    enName: '[TEST] Seed Pipeline Batch 5 Product',
    enCategory: 'QA Sandbox',
  ),
};

Product localizeProduct(Product product, UiLanguage lang) {
  final map = _productTranslations[product.id];
  if (map == null || lang == UiLanguage.ptBR) return product;
  return product.copyWith(
    name: map.enName ?? product.name,
    category: map.enCategory ?? product.category,
    evidence: product.evidence
        .map(
          (ev) => ProductEvidence(
            id: ev.id,
            sourceName: ev.sourceName,
            url: ev.url,
            summary: map.enEvidenceSummaries[ev.id] ?? ev.summary,
            verifiedAt: ev.verifiedAt,
          ),
        )
        .toList(),
    decisions: product.decisions
        .map(
          (dec) => ProductDecisionLog(
            id: dec.id,
            previousStatus: dec.previousStatus,
            newStatus: dec.newStatus,
            justification:
                map.enDecisionJustifications[dec.id] ?? dec.justification,
            actor: dec.actor,
            timestamp: dec.timestamp,
          ),
        )
        .toList(),
  );
}

class _ContentDisplayTranslation {
  const _ContentDisplayTranslation({
    this.enTitle,
    this.enBrief,
    this.enDescription,
    this.enAiDisclosureText,
    this.enVersionNotes = const {},
    this.enDossierClaims = const {},
  });

  final String? enTitle;
  final String? enBrief;
  final String? enDescription;
  final String? enAiDisclosureText;
  final Map<String, String> enVersionNotes;
  final Map<String, String> enDossierClaims;
}

const Map<String, _ContentDisplayTranslation> _contentDisplayMap = {
  'cnt-1': _ContentDisplayTranslation(
    enTitle: 'Keychron Q1 Pro after 90 days: worth it in Brazil?',
    enBrief: 'Technical review of wireless latency, gasket mount acoustics, and local/import cost.',
    enDescription: 'Technical evaluation after 90 days of coding and design work, with real Bluetooth/2.4GHz latency and acoustic measurements.',
    enVersionNotes: {
      'v2.0': 'Approved and published with tracked link cards.',
      'v1.0': 'Initial script structured from the product brief.',
    },
    enDossierClaims: {'dos-1': '1000Hz wired polling latency vs 90Hz BT 5.1'},
  ),
  'cnt-2': _ContentDisplayTranslation(
    enTitle: '4K Monitor for Code & Design: Dell UltraSharp 32 in practice',
    enBrief: 'Demonstrate text sharpness (subpixel layout), built-in Thunderbolt hub, and sRGB calibration.',
    enDescription: 'Evaluation of subpixel layout for crisp text, 90W Thunderbolt hub, and factory sRGB/DCI-P3 calibration.',
    enVersionNotes: {'v1.1': 'Refined intro to emphasize visual ergonomics.'},
    enDossierClaims: {
      'dos-2': '2000:1 IPS Black static contrast measured with Calibrite colorimeter',
      'dos-3': 'Native HiDPI scaling on macOS Sonoma/Sequoia',
    },
  ),
  'cnt-3': _ContentDisplayTranslation(
    enTitle: 'Sound Test: Banana vs Brown Switch in CNC Aluminum',
    enBrief: '42-second vertical cut focused on binaural audio with no background music.',
    enDescription: 'Direct binaural comparison between tactile switches with zero soundtrack, aimed at 8h/day workers.',
    enVersionNotes: {
      'v1.0': 'Approved for private/unlisted delivery in Phase A.',
    },
    enDossierClaims: {
      'dos-4': '57gf vs 55gf actuation force measured by dynamometer',
    },
  ),
  'cnt-4': _ContentDisplayTranslation(
    enVersionNotes: {'v2.0': 'Published across YouTube & Pinterest embed.'},
    enDossierClaims: {
      'dos-5': 'Recommended 500 lux illuminance on work surface',
    },
  ),
  'cnt-5': _ContentDisplayTranslation(
    enAiDisclosureText: 'Conceptual diagrams assisted by synthetic rendering (labeled per YouTube/EU standard).',
    enVersionNotes: {'v1.0': 'Draft generated from weekly content plan.'},
  ),
  'cnt-6': _ContentDisplayTranslation(
    enVersionNotes: {'v1.0': 'Initial brief opened.'},
  ),
  'cnt-7': _ContentDisplayTranslation(
    enTitle: 'Definitive Guide: Pixel Density (PPI) for macOS and Windows',
    enBrief: 'Evergreen technical guide with comparative 1440p vs 4K vs 5K scaling calculator.',
    enDescription: 'Evergreen technical article with HiDPI scaling tables for 27" and 32" 4K monitors.',
    enVersionNotes: {
      'v1.0': 'Technical review completed; awaiting final hash.',
    },
    enDossierClaims: {
      'dos-6': 'PPI calculation and fractional scaling factor in macOS Quartz',
    },
  ),
  'cnt-8': _ContentDisplayTranslation(
    enBrief: 'Fast short-form cut with before-and-after desk transition.',
    enVersionNotes: {
      'v1.0': 'Rejected in review: sensationalist tone misaligned with Nordic Desk editorial aesthetic.',
    },
  ),
};

class LocalizedContentDisplay {
  const LocalizedContentDisplay({
    required this.title,
    required this.brief,
    required this.description,
    required this.aiDisclosureText,
    required this.dossier,
    required this.versions,
  });

  final String title;
  final String brief;
  final String description;
  final String aiDisclosureText;
  final List<DossierSource> dossier;
  final List<ContentVersion> versions;
}

LocalizedContentDisplay localizeContentDisplay(
  ContentItem item,
  UiLanguage lang,
) {
  final map = _contentDisplayMap[item.id];
  if (map == null || lang == UiLanguage.ptBR) {
    return LocalizedContentDisplay(
      title: item.title,
      brief: item.brief,
      description: item.description,
      aiDisclosureText: item.aiDisclosureText,
      dossier: item.dossier,
      versions: item.versions
          .map(
            (v) => ContentVersion(
              version: v.version,
              manifestHash: v.manifestHash,
              author: localizeActor(v.author, lang),
              note: v.note,
              feedbackCategory: v.feedbackCategory,
              timestamp: v.timestamp,
              scriptSnapshot: v.scriptSnapshot,
            ),
          )
          .toList(),
    );
  }
  return LocalizedContentDisplay(
    title: map.enTitle ?? item.title,
    brief: map.enBrief ?? item.brief,
    description: map.enDescription ?? item.description,
    aiDisclosureText: map.enAiDisclosureText ?? item.aiDisclosureText,
    dossier: item.dossier
        .map(
          (d) => DossierSource(
            id: d.id,
            claim: map.enDossierClaims[d.id] ?? d.claim,
            sourceTitle: d.sourceTitle,
            level: d.level,
            consultedAt: d.consultedAt,
          ),
        )
        .toList(),
    versions: item.versions
        .map(
          (v) => ContentVersion(
            version: v.version,
            manifestHash: v.manifestHash,
            author: localizeActor(v.author, lang),
            note: map.enVersionNotes[v.version] ?? v.note,
            feedbackCategory: v.feedbackCategory,
            timestamp: v.timestamp,
            scriptSnapshot: v.scriptSnapshot,
          ),
        )
        .toList(),
  );
}

class _FinanceTranslation {
  const _FinanceTranslation({required this.enDesc, this.enPlatform, this.enFx});

  final String enDesc;
  final String? enPlatform;
  final String? enFx;
}

const Map<String, _FinanceTranslation> _financeTranslations = {
  'fin-1': _FinanceTranslation(
    enDesc: 'Settled payout — October 2026 commissions',
    enFx: 'Native BRL',
  ),
  'fin-2': _FinanceTranslation(
    enDesc: 'Monthly payout confirmed in USD account',
    enFx: 'PTAX Demo Reference',
  ),
  'fin-3': _FinanceTranslation(
    enDesc: 'Q4 batch settlement — Software & Audio',
    enFx: 'PTAX Demo Reference',
  ),
  'fin-4': _FinanceTranslation(
    enDesc: 'Direct sale: Desk Blueprint Digital Guide',
    enFx: 'ECB Demo Reference',
  ),
  'fin-5': _FinanceTranslation(
    enDesc: '14 approved conversions post-warranty (November cycle)',
    enFx: 'Native BRL',
  ),
  'fin-6': _FinanceTranslation(
    enDesc: 'Verified batch with zero chargebacks — payout on the 25th',
    enFx: 'PTAX Demo Reference',
  ),
  'fin-7': _FinanceTranslation(
    enDesc: 'Orders awaiting return window (14d)',
    enFx: 'Native BRL',
  ),
  'fin-8': _FinanceTranslation(
    enDesc: 'Converted clicks awaiting advertiser validation',
    enFx: 'PTAX Demo Reference',
  ),
  'fin-9': _FinanceTranslation(
    enDesc: 'Technical editing and audio recording (November)',
    enPlatform: 'Infra & Studio',
    enFx: 'Native BRL',
  ),
  'fin-10': _FinanceTranslation(
    enDesc: 'CDN hosting, domain, and analytics suite',
    enPlatform: 'Cloud & Tools',
    enFx: 'PTAX Demo Reference',
  ),
  'fin-11': _FinanceTranslation(
    enDesc: 'Reinvestment: Colorimeter and macro lens for reviews',
    enPlatform: 'Equipment',
    enFx: 'Native BRL',
  ),
  'fin-12': _FinanceTranslation(
    enDesc: 'Black Friday / December projection (historical baseline)',
    enPlatform: 'Conservative Model',
  ),
  'fin-13': _FinanceTranslation(
    enDesc: 'Q4 US/EU projection (Impact + Gumroad)',
    enPlatform: 'Conservative Model',
  ),
  'fin-test-1': _FinanceTranslation(
    enDesc: '[TEST] Synthetic test-record validation entry',
  ),
};

FinanceEntry localizeFinanceEntry(FinanceEntry entry, UiLanguage lang) {
  final map = _financeTranslations[entry.id];
  if (map == null) return entry;
  final cleanPtDesc =
      entry.id == 'fin-test-1' && entry.description.contains('is_test')
      ? '[TESTE] Lançamento sintético de validação de registro de teste'
      : entry.description;

  if (lang == UiLanguage.ptBR) {
    return FinanceEntry(
      id: entry.id,
      brandId: entry.brandId,
      productId: entry.productId,
      platform: entry.platform,
      description: cleanPtDesc,
      type: entry.type,
      stage: entry.stage,
      amount: entry.amount,
      currency: entry.currency,
      fxRateToBRL: entry.fxRateToBRL,
      fxSource: entry.fxSource,
      date: entry.date,
      isTest: entry.isTest,
      isProjection: entry.isProjection,
    );
  }

  return FinanceEntry(
    id: entry.id,
    brandId: entry.brandId,
    productId: entry.productId,
    platform: map.enPlatform ?? entry.platform,
    description: map.enDesc,
    type: entry.type,
    stage: entry.stage,
    amount: entry.amount,
    currency: entry.currency,
    fxRateToBRL: entry.fxRateToBRL,
    fxSource: map.enFx ?? entry.fxSource,
    date: entry.date,
    isTest: entry.isTest,
    isProjection: entry.isProjection,
  );
}

class _AgentTranslation {
  const _AgentTranslation({
    this.ptName,
    this.ptResp,
    this.ptDeps,
    this.ptError,
    required this.enName,
    required this.enResp,
    required this.enDeps,
    required this.enSteps,
    this.enPending,
    this.enError,
    this.enHistorySummaries = const {},
  });

  final String? ptName;
  final String? ptResp;
  final List<String>? ptDeps;
  final String? ptError;
  final String enName;
  final String enResp;
  final List<String> enDeps;
  final List<String> enSteps;
  final String? enPending;
  final String? enError;
  final Map<String, String> enHistorySummaries;
}

const Map<String, _AgentTranslation> _agentTranslations = {
  'ag-research': _AgentTranslation(
    enName: 'Demand & Trends Observer',
    enResp: 'Monitors search shifts, product launches, and editorial gaps by market and language (read-only).',
    enDeps: ['Google Trends Connector (Demo)', 'Brand Registry'],
    enSteps: [
      'Collect terms by niche and language',
      'Filter seasonal noise (< 10% variance)',
      'Cross-reference with shared catalog',
      'Push signals into the Products queue',
    ],
    enHistorySummaries: {
      'h-1': '14 demand signals evaluated; 2 opportunities scored above 80.',
      'h-2': 'Daily scan completed with zero anomalies.',
    },
  ),
  'ag-product-intel': _AgentTranslation(
    ptName: 'Qualificador Comercial',
    ptResp: 'Calcula o índice de avaliação do produto por moeda nativa mantendo campos sem dados explícitos e submete candidatos.',
    ptDeps: ['Observador de Demanda & Tendências', 'Catálogo Compartilhado'],
    enName: 'Commercial Qualifier',
    enResp: 'Computes the product evaluation index per native currency preserving missing fields and submits candidates.',
    enDeps: ['Demand & Trends Observer', 'Shared Catalog'],
    enSteps: [
      'Extract price and rate without mixing currencies',
      'Preserve missing inputs as no-data (never 0)',
      'Compute native-currency evaluation index',
      'Submit candidate for mandatory human approval',
    ],
    enPending: '2 candidate products (Herman Miller Embody Refurb and iZotope RX 11) await human decision.',
    enHistorySummaries: {
      'h-3':
          'Index computed; gated by policy before changing status to Approved.',
    },
  ),
  'ag-content-brief': _AgentTranslation(
    enName: 'Brief & Dossier Structurer (Block 6)',
    enResp: 'Generates drafts, source dossiers (levels 1–4), and computes the SHA-256 manifest awaiting individual authorization.',
    enDeps: ['Commercial Qualifier', 'Editorial Calendar'],
    enSteps: [
      'Read approved products clear of compliance blocks',
      'Assemble source dossier and mandatory disclosures',
      'Compute manifest SHA-256 hash',
      'Submit to Individual Approval Panel',
    ],
    enPending: '2 scripts in In Review (Dell 32 4K Monitor and PPI Guide) await individual hash approval.',
    enHistorySummaries: {
      'h-4': '1 new draft created for Nordic Workspace Boards.',
    },
  ),
  'ag-analytics-anom': _AgentTranslation(
    enName: 'Anomaly & Attribution Detector',
    enResp: 'Monitors 30s retention drops, Shorts → Long-form bridge, and validates tracking tags (V1–V5).',
    enDeps: ['Channels Sync', 'Content Metrics'],
    enSteps: [
      'Normalize time series by IANA timezone',
      'Detect > 2-sigma deviations in retention or CTR',
      'Label attributions as Estimate until V1–V5 validation',
    ],
    enHistorySummaries: {
      'h-5':
          'Positive anomaly detected: Nordic Pinterest +18.3% reach over 30d.',
    },
  ),
  'ag-finance-reconcile': _AgentTranslation(
    ptResp: 'Separa Pendente, Confirmado e Recebido em caixa, mantendo registros de teste isolados.',
    enName: 'Commission & Cash Reconciler',
    enResp: 'Separates Pending, Confirmed, and Received cash while keeping test records isolated.',
    enDeps: ['Financial Ledger', 'FX Rate Table'],
    enSteps: [
      'Audit settlement stage by platform',
      'Block reinvestments above net realized cash',
      'Isolate projections and test records',
    ],
    enHistorySummaries: {
      'h-6': '13 real entries reconciled (1 test record isolated).',
    },
  ),
  'ag-ops-sync': _AgentTranslation(
    ptName: 'Monitor de Saúde de Canais & Execuções',
    ptResp: 'Verifica tokens de leitura, recursos avançados no YouTube e identifica execuções pendentes para reconciliação.',
    ptDeps: ['Registro de Canais', 'Execuções de tarefas'],
    ptError: 'Canal TikTok (@nordic.desk) retornou token expirado; 1 execução pendente (#104) detectada.',
    enName: 'Channel Health & Runs Monitor',
    enResp: 'Checks read tokens, YouTube advanced features, and detects stalled runs for reconciliation.',
    enDeps: ['Channel Registry', 'Job Runs'],
    enSteps: [
      'Run read-only handshake per channel',
      'Detect running jobs past SLA threshold',
      'Report failure immediately to the owner',
    ],
    enError: 'TikTok channel (@nordic.desk) returned an expired token; 1 pending run (#104) detected.',
    enHistorySummaries: {
      'h-7': 'Failed to validate demo token for channel @nordic.desk.',
    },
  ),
};

AutomationAgent localizeAgent(AutomationAgent agent, UiLanguage lang) {
  final map = _agentTranslations[agent.id];
  if (map == null) return agent;

  if (lang == UiLanguage.ptBR) {
    final cleanDeps = agent.dependencies
        .map(
          (d) => d == 'job_runs'
              ? 'Execuções de tarefas'
              : d.contains('score-6.1')
              ? d.replaceAll(' (score-6.1)', '')
              : d,
        )
        .toList();
    final cleanSteps = agent.flowSteps
        .map(
          (s) => s
              .replaceAll('job_runs', 'execuções de tarefas')
              .replaceAll('registros is_test', 'registros de teste'),
        )
        .toList();
    return AutomationAgent(
      id: agent.id,
      name: map.ptName ?? agent.name,
      category: agent.category,
      autonomyLevel: agent.autonomyLevel,
      responsibility: map.ptResp ?? agent.responsibility,
      state: agent.state,
      brandScope: agent.brandScope,
      dependencies: map.ptDeps ?? cleanDeps,
      flowSteps: cleanSteps,
      pendingApprovalCount: agent.pendingApprovalCount,
      pendingApprovalSummary: agent.pendingApprovalSummary,
      lastRunAt: agent.lastRunAt,
      lastError: agent.lastError != null && map.ptError != null
          ? map.ptError
          : agent.lastError,
      limits: agent.limits,
      history: agent.history
          .map(
            (h) => AgentExecutionLog(
              id: h.id,
              timestamp: h.timestamp,
              status: h.status,
              durationSec: h.durationSec,
              summary: h.summary.replaceAll(
                'registro is_test',
                'registro de teste',
              ),
              recordsAffected: h.recordsAffected,
            ),
          )
          .toList(),
    );
  }

  return AutomationAgent(
    id: agent.id,
    name: map.enName,
    category: agent.category,
    autonomyLevel: agent.autonomyLevel,
    responsibility: map.enResp,
    state: agent.state,
    brandScope: agent.brandScope,
    dependencies: map.enDeps,
    flowSteps: map.enSteps,
    pendingApprovalCount: agent.pendingApprovalCount,
    pendingApprovalSummary: map.enPending ?? agent.pendingApprovalSummary,
    lastRunAt: agent.lastRunAt,
    lastError: agent.lastError != null
        ? (map.enError ?? agent.lastError)
        : agent.lastError,
    limits: agent.limits,
    history: agent.history
        .map(
          (h) => AgentExecutionLog(
            id: h.id,
            timestamp: h.timestamp,
            status: h.status,
            durationSec: h.durationSec,
            summary: map.enHistorySummaries[h.id] ?? h.summary,
            recordsAffected: h.recordsAffected,
          ),
        )
        .toList(),
  );
}

const Map<int, ({String ptSummary, String enSummary})> _jobRunTranslations = {
  104: (
    ptSummary: 'Execução interrompida por limite de tempo (pendente — requer reconciliação antes de retomar o sistema).',
    enSummary: 'Run interrupted by runner timeout (stalled — requires reconciliation before resuming the system).',
  ),
  103: (
    ptSummary: 'Índice de avaliação recalculado por moeda nativa (BRL, USD, EUR); campos sem dados preservados.',
    enSummary: 'Evaluation index recalculated per native currency (BRL, USD, EUR); missing fields preserved.',
  ),
  102: (
    ptSummary: 'Catálogo compartilhado deduplicado por plataforma e identificador externo.',
    enSummary:
        'Shared catalog deduplicated by platform and external identifier.',
  ),
  101: (
    ptSummary: 'Simulação padrão concluída sem gravação persistente.',
    enSummary: 'Default simulation completed with no persistent writes.',
  ),
};

JobRun localizeJobRun(JobRun job, UiLanguage lang) {
  final map = _jobRunTranslations[job.id];
  if (map == null) return job;
  return job.copyWith(
    summary: lang == UiLanguage.enUS ? map.enSummary : map.ptSummary,
  );
}

class _RiskTranslation {
  const _RiskTranslation({
    required this.ptTitle,
    required this.ptControl,
    required this.enTitle,
    required this.enControl,
  });

  final String ptTitle;
  final String ptControl;
  final String enTitle;
  final String enControl;
}

const Map<String, _RiskTranslation> _riskTranslations = {
  'R-04': _RiskTranslation(
    ptTitle: 'Autorização vinculada ao hash SHA-256 da versão',
    ptControl: 'Herança zero: qualquer edição no manifesto invalida aprovação anterior e retorna peça para Em revisão.',
    enTitle: 'Version-bound SHA-256 hash authorization',
    enControl: 'Zero inheritance: any edit to the manifest invalidates prior approval and returns the item to In Review.',
  ),
  'R-05': _RiskTranslation(
    ptTitle: 'Stop All com bloqueio seguro e trilha permanente',
    ptControl: 'Controles do sistema (Ativo / Interrompido) com registro de auditoria; retomada bloqueada enquanto houver execução pendente.',
    enTitle: 'Fail-closed Stop All with permanent audit trail',
    enControl: 'System controls (Active / Halted) with audit logging; resume blocked while pending runs remain.',
  ),
  'R-07': _RiskTranslation(
    ptTitle: 'Separação financeira rigorosa (Pendente vs Confirmado vs Caixa)',
    ptControl: 'Reinvestimentos autorizados apenas sobre caixa realizado líquido; registros de teste permanecem isolados.',
    enTitle: 'Strict financial separation (Pending vs Confirmed vs Cash)',
    enControl: 'Reinvestments authorized strictly from net realized cash; test records remain isolated.',
  ),
  'R-08': _RiskTranslation(
    ptTitle:
        'Conformidade comercial & IA generativa (Brasil CDC/CONAR + França/UE)',
    ptControl: 'Divulgações obrigatórias no manifesto e bloqueio para temas sensíveis sem autorização individual.',
    enTitle:
        'Commercial & generative AI compliance (Brazil CDC/CONAR + France/EU)',
    enControl: 'Mandatory disclosures in manifest and gate blocking sensitive topics without individual approval.',
  ),
  'R-11': _RiskTranslation(
    ptTitle: 'Proteção contra publicação pública acidental no YouTube',
    ptControl: 'Visibilidade explícita obrigatória; publicação pública bloqueada no ambiente privado (apenas privado/não listado).',
    enTitle: 'Guard against accidental public YouTube publishing',
    enControl: 'Explicit visibility required; public visibility blocked in the private environment (private/unlisted only).',
  ),
  'R-12': _RiskTranslation(
    ptTitle:
        'Banco de dados hospedado e proveniência de automação (Condição C3)',
    ptControl: 'Núcleo validado em ambiente efêmero; gravação em produção exigirá executor autorizado.',
    enTitle: 'Hosted database & automation provenance (Condition C3)',
    enControl: 'Core validated in ephemeral environment; production writes require an authorized runner.',
  ),
  'R-24': _RiskTranslation(
    ptTitle: 'Reconciliação de execuções pendentes (Débito M2)',
    ptControl: 'A reconciliação marca execuções travadas como falhas antes de liberar a retomada do sistema.',
    enTitle: 'Pending run reconciliation (Debt M2)',
    enControl: 'Reconciliation marks stalled runs as failed before allowing system resume.',
  ),
  'R-29': _RiskTranslation(
    ptTitle: 'Atribuição real por peça via rastreamento (Protocolo V1-V5)',
    ptControl: 'Métricas por conteúdo rotuladas como Estimativa [Em investigação] até validação V1–V5 no Bloco 9.',
    enTitle: 'Per-item real attribution via tracking (Protocol V1-V5)',
    enControl: 'Per-content metrics labeled as Estimate [Under review] until V1–V5 validation in Block 9.',
  ),
  'R-31': _RiskTranslation(
    ptTitle: 'Ranking de produtos sem conversão cambial prematura',
    ptControl: 'O índice de avaliação ranqueia estritamente por moeda nativa e mantém campos ausentes sem dados.',
    enTitle: 'Product ranking without premature FX conversion',
    enControl: 'The evaluation index ranks strictly by native currency and preserves missing fields as no-data.',
  ),
};

RiskRegisterEntry localizeRisk(RiskRegisterEntry risk, UiLanguage lang) {
  final map = _riskTranslations[risk.id];
  if (map == null) return risk;
  return RiskRegisterEntry(
    id: risk.id,
    priority: risk.priority,
    title: lang == UiLanguage.enUS ? map.enTitle : map.ptTitle,
    controlSummary: lang == UiLanguage.enUS ? map.enControl : map.ptControl,
    status: risk.status,
  );
}

class _ActivityTranslation {
  const _ActivityTranslation({
    this.ptAction,
    this.ptDetail,
    required this.enAction,
    required this.enDetail,
    this.enJustification,
  });

  final String? ptAction;
  final String? ptDetail;
  final String enAction;
  final String enDetail;
  final String? enJustification;
}

const Map<String, _ActivityTranslation> _activityTranslations = {
  'act-1': _ActivityTranslation(
    ptDetail: 'Token de leitura expirado no canal TikTok @nordic.desk e execução #104 detectada como pendente.',
    enAction: 'Failure in Channel Health Monitor',
    enDetail: 'Expired read token on TikTok @nordic.desk and run #104 flagged as pending.',
  ),
  'act-2': _ActivityTranslation(
    ptAction: 'Candidato qualificado no índice de avaliação',
    enAction: 'Candidate qualified in evaluation index',
    enDetail: 'Herman Miller Embody (Refurb) scored 82/100 (USD) and awaits human approval.',
  ),
  'act-3': _ActivityTranslation(
    ptAction: 'Autorização individual emitida (Ambiente privado · não listado)',
    enAction: 'Individual authorization issued (Private env · unlisted)',
    enDetail: 'Sound Test: Banana vs Brown Switch bound to SHA-256 hash until 2026-11-22.',
    enJustification: '6 pre-send checks passed.',
  ),
  'act-4': _ActivityTranslation(
    ptAction: 'Roteiro atualizado para Em revisão',
    enAction: 'Script updated to In Review',
    enDetail: '4K Monitor for Code & Design: Dell UltraSharp 32 (v1.1).',
    enJustification: 'Improved technical clarity in the opening hook.',
  ),
  'act-5': _ActivityTranslation(
    enAction: 'Commission confirmed by platform (12.1.1)',
    enDetail: r'Dell Affiliate Program confirmed R$ 5,790.00 (14 conversions). Awaiting cash payout.',
  ),
  'act-6': _ActivityTranslation(
    ptDetail: 'Status alterado de Candidato para Aprovado (Nota A · Conformidade aprovada).',
    enAction: 'Product approved: Dell UltraSharp 32" 4K Monitor',
    enDetail: 'Status changed from Candidate to Approved (Grade A · Compliance Approved).',
    enJustification: 'High ticket with a 30-day cookie and low saturation on Brazilian YouTube.',
  ),
  'act-7': _ActivityTranslation(
    ptDetail: 'Status alterado de Candidato para Rejeitado (Nota C · Conformidade bloqueada).',
    enAction: 'Product rejected: Generic 11-in-1 USB Hub',
    enDetail: 'Status changed from Candidate to Rejected (Grade C · Blocked).',
    enJustification: 'Low ticket, high return rate, and misalignment with premium positioning.',
  ),
};

ActivityEvent localizeActivity(ActivityEvent ev, UiLanguage lang) {
  final localizedActor = localizeActor(ev.actor, lang);
  final map = _activityTranslations[ev.id];
  if (map == null) {
    if (localizedActor == ev.actor) return ev;
    return ActivityEvent(
      id: ev.id,
      timestamp: ev.timestamp,
      brandId: ev.brandId,
      category: ev.category,
      action: ev.action,
      detail: ev.detail,
      justification: ev.justification,
      actor: localizedActor,
      severity: ev.severity,
    );
  }
  if (lang == UiLanguage.ptBR) {
    return ActivityEvent(
      id: ev.id,
      timestamp: ev.timestamp,
      brandId: ev.brandId,
      category: ev.category,
      action: map.ptAction ?? ev.action,
      detail: map.ptDetail ?? ev.detail,
      justification: ev.justification,
      actor: localizedActor,
      severity: ev.severity,
    );
  }
  return ActivityEvent(
    id: ev.id,
    timestamp: ev.timestamp,
    brandId: ev.brandId,
    category: ev.category,
    action: map.enAction,
    detail: map.enDetail,
    justification: map.enJustification ?? ev.justification,
    actor: localizedActor,
    severity: ev.severity,
  );
}

class _NotificationTranslation {
  const _NotificationTranslation({
    this.ptTitle,
    this.ptMessage,
    required this.enTitle,
    required this.enMessage,
  });

  final String? ptTitle;
  final String? ptMessage;
  final String enTitle;
  final String enMessage;
}

const Map<String, _NotificationTranslation> _notificationTranslations = {
  'not-1': _NotificationTranslation(
    ptMessage: 'Herman Miller Embody, iZotope RX 11 e 2 roteiros em revisão exigem decisão individual.',
    enTitle: '2 candidate products and 2 scripts await approval',
    enMessage: 'Herman Miller Embody, iZotope RX 11, and 2 scripts in review require individual decision.',
  ),
  'not-2': _NotificationTranslation(
    ptTitle: 'Execução pendente #104 & atenção no TikTok (@nordic.desk)',
    ptMessage: 'Reconcilie as execuções pendentes no executor de lotes e revise o token do canal @nordic.desk.',
    enTitle: 'Pending run #104 & attention on TikTok (@nordic.desk)',
    enMessage: 'Reconcile pending runs in the batch runner and review the @nordic.desk channel token.',
  ),
  'not-3': _NotificationTranslation(
    enTitle: 'Payout received in cash (PartnerStack)',
    enMessage: r'US$ 1,640.00 settled and reconciled for Kinetix Audio.',
  ),
  'not-4': _NotificationTranslation(
    enTitle: 'Positive anomaly on Pinterest (Nordic Desk)',
    enMessage:
        'Reach grew +18.3% over 30 days driven by ScreenBar lighting pins.',
  ),
};

NotificationItem localizeNotification(NotificationItem item, UiLanguage lang) {
  final map = _notificationTranslations[item.id];
  if (map == null) return item;
  return NotificationItem(
    id: item.id,
    type: item.type,
    title: lang == UiLanguage.enUS ? map.enTitle : (map.ptTitle ?? item.title),
    message: lang == UiLanguage.enUS
        ? map.enMessage
        : (map.ptMessage ?? item.message),
    timestamp: item.timestamp,
    read: item.read,
    targetModule: item.targetModule,
    targetId: item.targetId,
    brandId: item.brandId,
    actionRequired: item.actionRequired,
  );
}

class _IntegrationTranslation {
  const _IntegrationTranslation({
    required this.enName,
    required this.enCategory,
    this.enLastChecked,
  });

  final String enName;
  final String enCategory;
  final String? enLastChecked;
}

const Map<String, _IntegrationTranslation> _integrationTranslations = {
  'int-pg': _IntegrationTranslation(
    enName: 'PostgreSQL + Migrator (Batch 2/3)',
    enCategory: 'Core Backend',
    enLastChecked: 'CI Ephemeral OK · Hosted Pending',
  ),
  'int-gh': _IntegrationTranslation(
    enName: 'GitHub Actions Scheduler (C3)',
    enCategory: 'Orchestration',
    enLastChecked: 'Scheduler disabled (Phase 1)',
  ),
  'int-yt': _IntegrationTranslation(
    enName: 'YouTube Data & Analytics (Block 7)',
    enCategory: 'Channels',
  ),
  'int-ig': _IntegrationTranslation(
    enName: 'Instagram Graph API',
    enCategory: 'Channels',
  ),
  'int-tt': _IntegrationTranslation(
    enName: 'TikTok Creator Insights',
    enCategory: 'Channels',
  ),
  'int-amz': _IntegrationTranslation(
    enName: 'Amazon Associates Reporting',
    enCategory: 'Commissions',
  ),
  'int-ps': _IntegrationTranslation(
    enName: 'PartnerStack Ledger',
    enCategory: 'Commissions',
  ),
};

IntegrationConfig localizeIntegration(IntegrationConfig item, UiLanguage lang) {
  final map = _integrationTranslations[item.id];
  if (map == null || lang == UiLanguage.ptBR) return item;
  return IntegrationConfig(
    id: item.id,
    name: map.enName,
    category: map.enCategory,
    status: item.status,
    lastChecked: map.enLastChecked ?? item.lastChecked,
    note: item.note,
  );
}
