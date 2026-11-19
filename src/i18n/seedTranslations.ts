import {
  ActivityEvent,
  AutomationAgent,
  Brand,
  ContentItem,
  FinanceEntry,
  IntegrationConfig,
  JobRun,
  NotificationItem,
  Product,
  RiskRegisterEntry,
} from '../types/vyron';
import { UiLanguage } from './types';

/**
 * Pure translation helper for seed records:
 * - In PT-BR, returns the cleaned/current PT-BR display text.
 * - In EN-US, returns the EN-US translation ONLY when `currentVal === seedPt`
 *   (so any user-edited or newly created text is preserved verbatim without mutating state).
 */
export function txSeed(
  lang: UiLanguage,
  seedPt: string | undefined,
  enText: string | undefined,
  currentVal: string
): string {
  if (lang === 'EN-US' && seedPt !== undefined && enText !== undefined && currentVal === seedPt) {
    return enText;
  }
  return currentVal;
}

export function localizeActor(actor: string, lang: UiLanguage): string {
  const trimmed = actor.trim();
  if (trimmed === 'Proprietário' || trimmed === 'Owner') {
    return lang === 'EN-US' ? 'Owner' : 'Proprietário';
  }
  return actor;
}

export function localizeSystemControlReason(reason: string, lang: UiLanguage): string {
  const trimmed = reason.trim();
  if (
    trimmed === 'Operação controlada em Fase A (publicação automática desligada).' ||
    trimmed === 'Controlled Phase A operation (automated publishing disabled).'
  ) {
    return lang === 'EN-US'
      ? 'Controlled Phase A operation (automated publishing disabled).'
      : 'Operação controlada em Fase A (publicação automática desligada).';
  }
  if (
    trimmed === 'Stop All acionado pelo proprietário via Settings.' ||
    trimmed === 'Stop All triggered by owner via Settings.'
  ) {
    return lang === 'EN-US'
      ? 'Stop All triggered by owner via Settings.'
      : 'Stop All acionado pelo proprietário via Settings.';
  }
  if (
    trimmed === 'Retomada após reconciliação via Settings.' ||
    trimmed === 'Resumed after reconciliation via Settings.'
  ) {
    return lang === 'EN-US'
      ? 'Resumed after reconciliation via Settings.'
      : 'Retomada após reconciliação via Settings.';
  }
  return reason;
}

const BRAND_TRANSLATIONS: Record<
  string,
  {
    pt?: Partial<Pick<Brand, 'niche' | 'segment' | 'tagline' | 'description' | 'typographyNote'>> & {
      pillars?: string[];
    };
    en: Partial<Pick<Brand, 'niche' | 'segment' | 'tagline' | 'description' | 'typographyNote'>> & {
      pillars?: string[];
    };
  }
> = {
  'brand-apex': {
    en: {
      niche: 'Hardware & Productivity Setups',
      segment: 'Tech Reviews & High-Ticket Affiliate',
      tagline: 'Applied engineering for the workspace.',
      description:
        'Editorial and commercial operation focused on mechanical keyboards, OLED monitors, and high-precision ergonomics for tech professionals in Brazil (CDC/CONAR compliance).',
      typographyNote: 'Plus Jakarta Sans + JetBrains Mono for benchmarks',
      pillars: [
        'Desk Ergonomics & Biomechanics',
        'Precision Peripherals & Latency',
        'Monitors & Color Accuracy for Code',
        'Cable Architecture & USB-C Hubs',
      ],
    },
  },
  'brand-nordic': {
    en: {
      niche: 'Minimalist Workspace & Industrial Design',
      segment: 'Digital Products & Curated Gear Affiliate',
      tagline: 'Quiet precision for modern work.',
      description:
        'International brand prepared for the EU/France pilot (Loi 2023-451 / DSA), focused on architectural desk setups and digital ergonomics guides.',
      typographyNote: 'Manrope + tabular numerals',
      pillars: [
        'Asymmetric Lighting & OLED Contrast',
        'Industrial Design & Durable Materials',
        'Digital Workstation Blueprints',
      ],
    },
  },
  'brand-kinetix': {
    en: {
      niche: 'Acoustics, IEMs & Audio Production',
      segment: 'Audio Gear & Software Plugins',
      tagline: 'Clarity measured in decibels.',
      description:
        'Technical channel and portal specializing in audio interfaces, dynamic microphones, and DSP suites monetized via PartnerStack and Amazon Global.',
      typographyNote: 'Outfit + IBM Plex Mono',
      pillars: [
        'Vocal Capture in Untreated Rooms',
        'DSP & Real-Time Signal Processing',
        'Reference Monitoring & Acoustics',
      ],
    },
  },
  'brand-veloce': {
    en: {
      niche: 'Home Automation & Smart Living',
      segment: 'Connected Home',
      tagline: 'Quiet domestic routines.',
      description:
        'Vertical on tactical pause for Matter/Thread portfolio review and direct partnership renegotiation.',
      typographyNote: 'DM Sans',
      pillars: [
        'Local Matter & Thread Protocol',
        'Residential Energy Efficiency',
        'Silent Cloud-Free Automation',
      ],
    },
  },
};

export function localizeBrand(brand: Brand, lang: UiLanguage): Brand {
  const map = BRAND_TRANSLATIONS[brand.id];
  if (!map || lang === 'PT-BR') return brand;
  const { en } = map;
  return {
    ...brand,
    niche: en.niche ?? brand.niche,
    segment: en.segment ?? brand.segment,
    tagline: en.tagline ?? brand.tagline,
    description: en.description ?? brand.description,
    typographyNote: en.typographyNote ?? brand.typographyNote,
    pillars: en.pillars ?? brand.pillars,
  };
}

const PRODUCT_TRANSLATIONS: Record<
  string,
  {
    ptName?: string;
    enName?: string;
    enCategory?: string;
    enEvidenceSummaries?: Record<string, string>;
    enDecisionJustifications?: Record<string, string>;
  }
> = {
  'prod-keychron-q1': {
    enCategory: 'Mechanical Keyboards',
    enEvidenceSummaries: {
      'ev-1': '+24% search growth for "wireless custom keyboard" over the last 90 days.',
      'ev-2': '4.8% average conversion rate across comparative reviews over 12 minutes.',
    },
    enDecisionJustifications: {
      'dec-1': 'EPC above R$ 2.00 with strong retention among software engineering audiences.',
    },
  },
  'prod-dell-oled': {
    enName: 'Dell UltraSharp 32" 4K Monitor',
    enCategory: 'Professional Monitors',
    enEvidenceSummaries: {
      'ev-3': 'Extended 30-day cookie window + CPA bonus on corporate orders.',
    },
    enDecisionJustifications: {
      'dec-2': 'High ticket with a 30-day cookie and low saturation on Brazilian YouTube.',
    },
  },
  'prod-benq-halo': {
    enCategory: 'Desk Lighting',
    enEvidenceSummaries: {
      'ev-4': 'Minimalist desk setup pins with ScreenBar achieve 2.3x account average CTR.',
    },
    enDecisionJustifications: {
      'dec-3': 'Recurring conversion via Pinterest and YouTube Shorts for US/EU audiences.',
    },
  },
  'prod-ergo-chair-x': {
    enCategory: 'Ergonomic Chairs',
    enEvidenceSummaries: {
      'ev-5': 'Signal spotted across 14 r/battlestations threads with explicit purchase intent.',
    },
  },
  'prod-shure-mv7x': {
    enCategory: 'Dynamic Microphones',
    enEvidenceSummaries: {
      'ev-6': 'Monthly search volume grew 22% with low supply in practical comparisons.',
    },
    enDecisionJustifications: {
      'dec-4': 'Strong synergy with acoustic treatment scripts for creators.',
    },
  },
  'prod-izotope-rx': {
    enCategory: 'DSP Software',
    enEvidenceSummaries: {
      'ev-7': '18% commission with low refund rate (1.2%) on digital licenses.',
    },
  },
  'prod-unknown-epc': {
    enName: 'Loupedeck CT Console (EU Batch)',
    enCategory: 'Workflow Controllers',
    enEvidenceSummaries: {
      'ev-unknown': 'EPC and cookie window omitted by advertiser in initial feed (kept as null).',
    },
  },
  'prod-cheap-hub': {
    enName: 'Generic 11-in-1 USB Hub',
    enCategory: 'Accessories',
    enEvidenceSummaries: {
      'ev-8': 'Net margin per click well below Apex operational floor (R$ 1.00 EPC).',
    },
    enDecisionJustifications: {
      'dec-5': 'Low ticket, high return rate, and Grade C quality misaligned with positioning.',
    },
  },
  'prod-aqara-hub': {
    enCategory: 'Smart Home',
    enDecisionJustifications: {
      'dec-6': 'Temporarily archived due to tactical pause of the Veloce Casa brand.',
    },
  },
  'prod-seed-test': {
    ptName: '[TESTE] Produto Seed Pipeline Lote 5',
    enName: '[TEST] Seed Pipeline Batch 5 Product',
    enCategory: 'QA Sandbox',
  },
};

export function localizeProduct(product: Product, lang: UiLanguage): Product {
  const map = PRODUCT_TRANSLATIONS[product.id];
  if (!map || lang === 'PT-BR') return product;
  return {
    ...product,
    name: map.enName ?? product.name,
    category: map.enCategory ?? product.category,
    evidence: product.evidence.map((ev) => ({
      ...ev,
      summary: map.enEvidenceSummaries?.[ev.id] ?? ev.summary,
    })),
    decisions: product.decisions.map((dec) => ({
      ...dec,
      justification: map.enDecisionJustifications?.[dec.id] ?? dec.justification,
    })),
  };
}

const CONTENT_DISPLAY_MAP: Record<
  string,
  {
    enTitle?: string;
    enBrief?: string;
    enDescription?: string;
    enAiDisclosureText?: string;
    enVersionNotes?: Record<string, string>;
    enDossierClaims?: Record<string, string>;
  }
> = {
  'cnt-1': {
    enTitle: 'Keychron Q1 Pro after 90 days: worth it in Brazil?',
    enBrief: 'Technical review of wireless latency, gasket mount acoustics, and local/import cost.',
    enDescription:
      'Technical evaluation after 90 days of coding and design work, with real Bluetooth/2.4GHz latency and acoustic measurements.',
    enVersionNotes: {
      'v2.0': 'Approved and published with tracked link cards.',
      'v1.0': 'Initial script structured from the product brief.',
    },
    enDossierClaims: {
      'dos-1': '1000Hz wired polling latency vs 90Hz BT 5.1',
    },
  },
  'cnt-2': {
    enTitle: '4K Monitor for Code & Design: Dell UltraSharp 32 in practice',
    enBrief: 'Demonstrate text sharpness (subpixel layout), built-in Thunderbolt hub, and sRGB calibration.',
    enDescription:
      'Evaluation of subpixel layout for crisp text, 90W Thunderbolt hub, and factory sRGB/DCI-P3 calibration.',
    enVersionNotes: {
      'v1.1': 'Refined intro to emphasize visual ergonomics.',
    },
    enDossierClaims: {
      'dos-2': '2000:1 IPS Black static contrast measured with Calibrite colorimeter',
      'dos-3': 'Native HiDPI scaling on macOS Sonoma/Sequoia',
    },
  },
  'cnt-3': {
    enTitle: 'Sound Test: Banana vs Brown Switch in CNC Aluminum',
    enBrief: '42-second vertical cut focused on binaural audio with no background music.',
    enDescription:
      'Direct binaural comparison between tactile switches with zero soundtrack, aimed at 8h/day workers.',
    enVersionNotes: {
      'v1.0': 'Approved for private/unlisted delivery in Phase A.',
    },
    enDossierClaims: {
      'dos-4': '57gf vs 55gf actuation force measured by dynamometer',
    },
  },
  'cnt-4': {
    enVersionNotes: {
      'v2.0': 'Published across YouTube & Pinterest embed.',
    },
    enDossierClaims: {
      'dos-5': 'Recommended 500 lux illuminance on work surface',
    },
  },
  'cnt-5': {
    enAiDisclosureText:
      'Conceptual diagrams assisted by synthetic rendering (labeled per YouTube/EU standard).',
    enVersionNotes: {
      'v1.0': 'Draft generated from weekly content plan.',
    },
  },
  'cnt-6': {
    enVersionNotes: {
      'v1.0': 'Initial brief opened.',
    },
  },
  'cnt-7': {
    enTitle: 'Definitive Guide: Pixel Density (PPI) for macOS and Windows',
    enBrief: 'Evergreen technical guide with comparative 1440p vs 4K vs 5K scaling calculator.',
    enDescription:
      'Evergreen technical article with HiDPI scaling tables for 27" and 32" 4K monitors.',
    enVersionNotes: {
      'v1.0': 'Technical review completed; awaiting final hash.',
    },
    enDossierClaims: {
      'dos-6': 'PPI calculation and fractional scaling factor in macOS Quartz',
    },
  },
  'cnt-8': {
    enBrief: 'Fast short-form cut with before-and-after desk transition.',
    enVersionNotes: {
      'v1.0': 'Rejected in review: sensationalist tone misaligned with Nordic Desk editorial aesthetic.',
    },
  },
};

export function localizeContentDisplay(item: ContentItem, lang: UiLanguage): {
  title: string;
  brief: string;
  description: string;
  aiDisclosureText: string;
  dossier: ContentItem['dossier'];
  versions: ContentItem['versions'];
} {
  const map = CONTENT_DISPLAY_MAP[item.id];
  if (!map || lang === 'PT-BR') {
    return {
      title: item.title,
      brief: item.brief,
      description: item.description,
      aiDisclosureText: item.aiDisclosureText,
      dossier: item.dossier,
      versions: item.versions.map((v) => ({
        ...v,
        author: localizeActor(v.author, lang),
      })),
    };
  }
  return {
    title: map.enTitle ?? item.title,
    brief: map.enBrief ?? item.brief,
    description: map.enDescription ?? item.description,
    aiDisclosureText: map.enAiDisclosureText ?? item.aiDisclosureText,
    dossier: item.dossier.map((d) => ({
      ...d,
      claim: map.enDossierClaims?.[d.id] ?? d.claim,
    })),
    versions: item.versions.map((v) => ({
      ...v,
      author: localizeActor(v.author, lang),
      note: map.enVersionNotes?.[v.version] ?? v.note,
    })),
  };
}

const FINANCE_TRANSLATIONS: Record<
  string,
  { ptDesc: string; enDesc: string; ptPlatform?: string; enPlatform?: string; ptFx?: string; enFx?: string }
> = {
  'fin-1': {
    ptDesc: 'Repasse liquidado — Comissões Outubro/2026',
    enDesc: 'Settled payout — October 2026 commissions',
    ptFx: 'Nativo BRL',
    enFx: 'Native BRL',
  },
  'fin-2': {
    ptDesc: 'Payout mensal confirmado em conta USD',
    enDesc: 'Monthly payout confirmed in USD account',
    ptFx: 'PTAX Referência Demo',
    enFx: 'PTAX Demo Reference',
  },
  'fin-3': {
    ptDesc: 'Liquidação lote Q4 — Software & Áudio',
    enDesc: 'Q4 batch settlement — Software & Audio',
    ptFx: 'PTAX Referência Demo',
    enFx: 'PTAX Demo Reference',
  },
  'fin-4': {
    ptDesc: 'Venda direta: Desk Blueprint Digital Guide',
    enDesc: 'Direct sale: Desk Blueprint Digital Guide',
    ptFx: 'BCE Referência Demo',
    enFx: 'ECB Demo Reference',
  },
  'fin-5': {
    ptDesc: '14 conversões aprovadas pós-garantia (ciclo Novembro)',
    enDesc: '14 approved conversions post-warranty (November cycle)',
    ptFx: 'Nativo BRL',
    enFx: 'Native BRL',
  },
  'fin-6': {
    ptDesc: 'Lote verificado sem chargeback — pagamento dia 25',
    enDesc: 'Verified batch with zero chargebacks — payout on the 25th',
    ptFx: 'PTAX Referência Demo',
    enFx: 'PTAX Demo Reference',
  },
  'fin-7': {
    ptDesc: 'Pedidos aguardando janela de devolução (14d)',
    enDesc: 'Orders awaiting return window (14d)',
    ptFx: 'Nativo BRL',
    enFx: 'Native BRL',
  },
  'fin-8': {
    ptDesc: 'Cliques convertidos aguardando validação do anunciante',
    enDesc: 'Converted clicks awaiting advertiser validation',
    ptFx: 'PTAX Referência Demo',
    enFx: 'PTAX Demo Reference',
  },
  'fin-9': {
    ptDesc: 'Edição técnica e captação de áudio (Novembro)',
    enDesc: 'Technical editing and audio recording (November)',
    ptPlatform: 'Infra & Estúdio',
    enPlatform: 'Infra & Studio',
    ptFx: 'Nativo BRL',
    enFx: 'Native BRL',
  },
  'fin-10': {
    ptDesc: 'Hospedagem CDN, domínio e suíte analítica',
    enDesc: 'CDN hosting, domain, and analytics suite',
    ptPlatform: 'Cloud & Ferramentas',
    enPlatform: 'Cloud & Tools',
    ptFx: 'PTAX Referência Demo',
    enFx: 'PTAX Demo Reference',
  },
  'fin-11': {
    ptDesc: 'Reinvestimento: Colorímetro e lente macro para reviews',
    enDesc: 'Reinvestment: Colorimeter and macro lens for reviews',
    ptPlatform: 'Equipamento',
    enPlatform: 'Equipment',
    ptFx: 'Nativo BRL',
    enFx: 'Native BRL',
  },
  'fin-12': {
    ptDesc: 'Projeção Black Friday / Dezembro (base histórico)',
    enDesc: 'Black Friday / December projection (historical baseline)',
    ptPlatform: 'Modelo Conservador',
    enPlatform: 'Conservative Model',
  },
  'fin-13': {
    ptDesc: 'Projeção Q4 EUA/EU (Impact + Gumroad)',
    enDesc: 'Q4 US/EU projection (Impact + Gumroad)',
    ptPlatform: 'Modelo Conservador',
    enPlatform: 'Conservative Model',
  },
  'fin-test-1': {
    ptDesc: '[TESTE] Lançamento sintético de validação de teste',
    enDesc: '[TEST] Synthetic test-record validation entry',
  },
};

export function localizeFinanceEntry(entry: FinanceEntry, lang: UiLanguage): FinanceEntry {
  const map = FINANCE_TRANSLATIONS[entry.id];
  if (!map) return entry;
  // Clean raw internal identifier `is_test` even in PT-BR display
  const cleanPtDesc =
    entry.id === 'fin-test-1' && entry.description.includes('is_test')
      ? '[TESTE] Lançamento sintético de validação de registro de teste'
      : entry.description;
  if (lang === 'PT-BR') {
    return { ...entry, description: cleanPtDesc };
  }
  return {
    ...entry,
    description: map.enDesc,
    platform: map.enPlatform ?? entry.platform,
    fxSource: map.enFx ?? entry.fxSource,
  };
}

const AGENT_TRANSLATIONS: Record<
  string,
  {
    ptName?: string;
    ptResp?: string;
    ptDeps?: string[];
    ptError?: string;
    enName: string;
    enResp: string;
    enDeps: string[];
    enSteps: string[];
    enPending?: string;
    enError?: string;
    enHistorySummaries?: Record<string, string>;
  }
> = {
  'ag-research': {
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
  },
  'ag-product-intel': {
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
      'h-3': 'Index computed; gated by policy before changing status to Approved.',
    },
  },
  'ag-content-brief': {
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
  },
  'ag-analytics-anom': {
    enName: 'Anomaly & Attribution Detector',
    enResp: 'Monitors 30s retention drops, Shorts → Long-form bridge, and validates tracking tags (V1–V5).',
    enDeps: ['Channels Sync', 'Content Metrics'],
    enSteps: [
      'Normalize time series by IANA timezone',
      'Detect > 2-sigma deviations in retention or CTR',
      'Label attributions as Estimate until V1–V5 validation',
    ],
    enHistorySummaries: {
      'h-5': 'Positive anomaly detected: Nordic Pinterest +18.3% reach over 30d.',
    },
  },
  'ag-finance-reconcile': {
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
  },
  'ag-ops-sync': {
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
  },
};

export function localizeAgent(agent: AutomationAgent, lang: UiLanguage): AutomationAgent {
  const map = AGENT_TRANSLATIONS[agent.id];
  if (!map) return agent;

  if (lang === 'PT-BR') {
    const cleanDependencies = agent.dependencies.map((d) =>
      d === 'job_runs'
        ? 'Execuções de tarefas'
        : d.includes('score-6.1')
        ? d.replace(' (score-6.1)', '')
        : d
    );
    const cleanSteps = agent.flowSteps.map((s) =>
      s
        .replace('job_runs', 'execuções de tarefas')
        .replace('registros is_test', 'registros de teste')
    );
    return {
      ...agent,
      name: map.ptName ?? agent.name,
      responsibility: map.ptResp ?? agent.responsibility,
      dependencies: map.ptDeps ?? cleanDependencies,
      flowSteps: cleanSteps,
      lastError: agent.lastError && map.ptError ? map.ptError : agent.lastError,
      history: agent.history.map((h) => ({
        ...h,
        summary: h.summary.replace('registro is_test', 'registro de teste'),
      })),
    };
  }

  return {
    ...agent,
    name: map.enName,
    responsibility: map.enResp,
    dependencies: map.enDeps,
    flowSteps: map.enSteps,
    pendingApprovalSummary: map.enPending ?? agent.pendingApprovalSummary,
    lastError: agent.lastError ? map.enError ?? agent.lastError : agent.lastError,
    history: agent.history.map((h) => ({
      ...h,
      summary: map.enHistorySummaries?.[h.id] ?? h.summary,
    })),
  };
}

const JOB_RUN_TRANSLATIONS: Record<
  number,
  { ptSummary: string; enSummary: string }
> = {
  104: {
    ptSummary:
      'Execução interrompida por limite de tempo (pendente — requer reconciliação antes de retomar o sistema).',
    enSummary:
      'Run interrupted by runner timeout (stalled — requires reconciliation before resuming the system).',
  },
  103: {
    ptSummary:
      'Índice de avaliação recalculado por moeda nativa (BRL, USD, EUR); campos sem dados preservados.',
    enSummary:
      'Evaluation index recalculated per native currency (BRL, USD, EUR); missing fields preserved.',
  },
  102: {
    ptSummary: 'Catálogo compartilhado deduplicado por plataforma e identificador externo.',
    enSummary: 'Shared catalog deduplicated by platform and external identifier.',
  },
  101: {
    ptSummary: 'Simulação padrão concluída sem gravação persistente.',
    enSummary: 'Default simulation completed with no persistent writes.',
  },
};

export function localizeJobRun(job: JobRun, lang: UiLanguage): JobRun {
  const map = JOB_RUN_TRANSLATIONS[job.id];
  if (!map) return job;
  return {
    ...job,
    summary: lang === 'EN-US' ? map.enSummary : map.ptSummary,
  };
}

const RISK_TRANSLATIONS: Record<
  string,
  {
    ptTitle: string;
    ptControl: string;
    enTitle: string;
    enControl: string;
  }
> = {
  'R-04': {
    ptTitle: 'Autorização vinculada ao hash SHA-256 da versão',
    ptControl:
      'Herança zero: qualquer edição no manifesto invalida aprovação anterior e retorna peça para Em revisão.',
    enTitle: 'Version-bound SHA-256 hash authorization',
    enControl:
      'Zero inheritance: any edit to the manifest invalidates prior approval and returns the item to In Review.',
  },
  'R-05': {
    ptTitle: 'Stop All com bloqueio seguro e trilha permanente',
    ptControl:
      'Controles do sistema (Ativo / Interrompido) com registro de auditoria; retomada bloqueada enquanto houver execução pendente.',
    enTitle: 'Fail-closed Stop All with permanent audit trail',
    enControl:
      'System controls (Active / Halted) with audit logging; resume blocked while pending runs remain.',
  },
  'R-07': {
    ptTitle: 'Separação financeira rigorosa (Pendente vs Confirmado vs Caixa)',
    ptControl:
      'Reinvestimentos autorizados apenas sobre caixa realizado líquido; registros de teste permanecem isolados.',
    enTitle: 'Strict financial separation (Pending vs Confirmed vs Cash)',
    enControl:
      'Reinvestments authorized strictly from net realized cash; test records remain isolated.',
  },
  'R-08': {
    ptTitle: 'Conformidade comercial & IA generativa (Brasil CDC/CONAR + França/UE)',
    ptControl:
      'Divulgações obrigatórias no manifesto e bloqueio para temas sensíveis sem autorização individual.',
    enTitle: 'Commercial & generative AI compliance (Brazil CDC/CONAR + France/EU)',
    enControl:
      'Mandatory disclosures in manifest and gate blocking sensitive topics without individual approval.',
  },
  'R-11': {
    ptTitle: 'Proteção contra publicação pública acidental no YouTube',
    ptControl:
      'Visibilidade explícita obrigatória; publicação pública bloqueada no ambiente privado (apenas privado/não listado).',
    enTitle: 'Guard against accidental public YouTube publishing',
    enControl:
      'Explicit visibility required; public visibility blocked in the private environment (private/unlisted only).',
  },
  'R-12': {
    ptTitle: 'Banco de dados hospedado e proveniência de automação (Condição C3)',
    ptControl:
      'Núcleo validado em ambiente efêmero; gravação em produção exigirá executor autorizado.',
    enTitle: 'Hosted database & automation provenance (Condition C3)',
    enControl:
      'Core validated in ephemeral environment; production writes require an authorized runner.',
  },
  'R-24': {
    ptTitle: 'Reconciliação de execuções pendentes (Débito M2)',
    ptControl:
      'A reconciliação marca execuções travadas como falhas antes de liberar a retomada do sistema.',
    enTitle: 'Pending run reconciliation (Debt M2)',
    enControl:
      'Reconciliation marks stalled runs as failed before allowing system resume.',
  },
  'R-29': {
    ptTitle: 'Atribuição real por peça via rastreamento (Protocolo V1-V5)',
    ptControl:
      'Métricas por conteúdo rotuladas como Estimativa [Em investigação] até validação V1–V5 no Bloco 9.',
    enTitle: 'Per-item real attribution via tracking (Protocol V1-V5)',
    enControl:
      'Per-content metrics labeled as Estimate [Under review] until V1–V5 validation in Block 9.',
  },
  'R-31': {
    ptTitle: 'Ranking de produtos sem conversão cambial prematura',
    ptControl:
      'O índice de avaliação ranqueia estritamente por moeda nativa e mantém campos ausentes sem dados.',
    enTitle: 'Product ranking without premature FX conversion',
    enControl:
      'The evaluation index ranks strictly by native currency and preserves missing fields as no-data.',
  },
};

export function localizeRisk(risk: RiskRegisterEntry, lang: UiLanguage): RiskRegisterEntry {
  const map = RISK_TRANSLATIONS[risk.id];
  if (!map) return risk;
  return {
    ...risk,
    title: lang === 'EN-US' ? map.enTitle : map.ptTitle,
    controlSummary: lang === 'EN-US' ? map.enControl : map.ptControl,
  };
}

const ACTIVITY_TRANSLATIONS: Record<
  string,
  {
    ptAction?: string;
    ptDetail?: string;
    enAction: string;
    enDetail: string;
    enJustification?: string;
  }
> = {
  'act-1': {
    ptDetail: 'Token de leitura expirado no canal TikTok @nordic.desk e execução #104 detectada como pendente.',
    enAction: 'Failure in Channel Health Monitor',
    enDetail: 'Expired read token on TikTok @nordic.desk and run #104 flagged as pending.',
  },
  'act-2': {
    ptAction: 'Candidato qualificado no índice de avaliação',
    enAction: 'Candidate qualified in evaluation index',
    enDetail: 'Herman Miller Embody (Refurb) scored 82/100 (USD) and awaits human approval.',
  },
  'act-3': {
    ptAction: 'Autorização individual emitida (Ambiente privado · não listado)',
    enAction: 'Individual authorization issued (Private env · unlisted)',
    enDetail: 'Sound Test: Banana vs Brown Switch bound to SHA-256 hash until 2026-11-22.',
    enJustification: '6 pre-send checks passed.',
  },
  'act-4': {
    ptAction: 'Roteiro atualizado para Em revisão',
    enAction: 'Script updated to In Review',
    enDetail: '4K Monitor for Code & Design: Dell UltraSharp 32 (v1.1).',
    enJustification: 'Improved technical clarity in the opening hook.',
  },
  'act-5': {
    enAction: 'Commission confirmed by platform (12.1.1)',
    enDetail: 'Dell Affiliate Program confirmed R$ 5,790.00 (14 conversions). Awaiting cash payout.',
  },
  'act-6': {
    ptDetail: 'Status alterado de Candidato para Aprovado (Nota A · Conformidade aprovada).',
    enAction: 'Product approved: Dell UltraSharp 32" 4K Monitor',
    enDetail: 'Status changed from Candidate to Approved (Grade A · Compliance Approved).',
    enJustification: 'High ticket with a 30-day cookie and low saturation on Brazilian YouTube.',
  },
  'act-7': {
    ptDetail: 'Status alterado de Candidato para Rejeitado (Nota C · Conformidade bloqueada).',
    enAction: 'Product rejected: Generic 11-in-1 USB Hub',
    enDetail: 'Status changed from Candidate to Rejected (Grade C · Blocked).',
    enJustification: 'Low ticket, high return rate, and misalignment with premium positioning.',
  },
};

export function localizeActivity(ev: ActivityEvent, lang: UiLanguage): ActivityEvent {
  const localizedActor = localizeActor(ev.actor, lang);
  const map = ACTIVITY_TRANSLATIONS[ev.id];
  if (!map) {
    return localizedActor === ev.actor ? ev : { ...ev, actor: localizedActor };
  }
  if (lang === 'PT-BR') {
    return {
      ...ev,
      actor: localizedActor,
      action: map.ptAction ?? ev.action,
      detail: map.ptDetail ?? ev.detail,
    };
  }
  return {
    ...ev,
    actor: localizedActor,
    action: map.enAction,
    detail: map.enDetail,
    justification: map.enJustification ?? ev.justification,
  };
}

const NOTIFICATION_TRANSLATIONS: Record<
  string,
  { ptTitle?: string; ptMessage?: string; enTitle: string; enMessage: string }
> = {
  'not-1': {
    ptMessage: 'Herman Miller Embody, iZotope RX 11 e 2 roteiros em revisão exigem decisão individual.',
    enTitle: '2 candidate products and 2 scripts await approval',
    enMessage: 'Herman Miller Embody, iZotope RX 11, and 2 scripts in review require individual decision.',
  },
  'not-2': {
    ptTitle: 'Execução pendente #104 & atenção no TikTok (@nordic.desk)',
    ptMessage: 'Reconcilie as execuções pendentes no executor de lotes e revise o token do canal @nordic.desk.',
    enTitle: 'Pending run #104 & attention on TikTok (@nordic.desk)',
    enMessage: 'Reconcile pending runs in the batch runner and review the @nordic.desk channel token.',
  },
  'not-3': {
    enTitle: 'Payout received in cash (PartnerStack)',
    enMessage: 'US$ 1,640.00 settled and reconciled for Kinetix Audio.',
  },
  'not-4': {
    enTitle: 'Positive anomaly on Pinterest (Nordic Desk)',
    enMessage: 'Reach grew +18.3% over 30 days driven by ScreenBar lighting pins.',
  },
};

export function localizeNotification(item: NotificationItem, lang: UiLanguage): NotificationItem {
  const map = NOTIFICATION_TRANSLATIONS[item.id];
  if (!map) return item;
  if (lang === 'PT-BR') {
    return {
      ...item,
      title: map.ptTitle ?? item.title,
      message: map.ptMessage ?? item.message,
    };
  }
  return {
    ...item,
    title: map.enTitle,
    message: map.enMessage,
  };
}

const INTEGRATION_TRANSLATIONS: Record<
  string,
  { enName: string; enCategory: string; enLastChecked?: string }
> = {
  'int-pg': {
    enName: 'PostgreSQL + Migrator (Batch 2/3)',
    enCategory: 'Core Backend',
    enLastChecked: 'CI Ephemeral OK · Hosted Pending',
  },
  'int-gh': {
    enName: 'GitHub Actions Scheduler (C3)',
    enCategory: 'Orchestration',
    enLastChecked: 'Scheduler disabled (Phase 1)',
  },
  'int-yt': {
    enName: 'YouTube Data & Analytics (Block 7)',
    enCategory: 'Channels',
  },
  'int-ig': {
    enName: 'Instagram Graph API',
    enCategory: 'Channels',
  },
  'int-tt': {
    enName: 'TikTok Creator Insights',
    enCategory: 'Channels',
  },
  'int-amz': {
    enName: 'Amazon Associates Reporting',
    enCategory: 'Commissions',
  },
  'int-ps': {
    enName: 'PartnerStack Ledger',
    enCategory: 'Commissions',
  },
};

export function localizeIntegration(item: IntegrationConfig, lang: UiLanguage): IntegrationConfig {
  const map = INTEGRATION_TRANSLATIONS[item.id];
  if (!map || lang === 'PT-BR') return item;
  return {
    ...item,
    name: map.enName,
    category: map.enCategory,
    lastChecked: map.enLastChecked ?? item.lastChecked,
  };
}
