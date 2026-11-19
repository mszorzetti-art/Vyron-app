export type ThemeMode = 'dark' | 'light';
export type CurrencyCode = 'BRL' | 'USD' | 'EUR';
export type PeriodFilter = '7d' | '30d' | '90d' | '12m';

export type NavModule =
  | 'overview'
  | 'brands'
  | 'products'
  | 'content'
  | 'channels'
  | 'analytics'
  | 'finance'
  | 'automations'
  | 'activity'
  | 'notifications'
  | 'settings';

export type BrandStatus = 'Active' | 'Paused' | 'Archived';
export type BrandArchetype = 'Descoberta & Autoridade' | 'Pesquisa & Intenção' | 'Híbrida';
export type ValidationStage =
  | '1. Exploração'
  | '2. Interesse'
  | '3. Validação de Conversão'
  | '4. Resultado Financeiro'
  | '5. Sustentabilidade';

export interface Brand {
  id: string;
  name: string;
  slug: string;
  niche: string;
  segment: string;
  market: string;
  language: string;
  timezone: string; // IANA timezone (ex: America/Sao_Paulo, Europe/Paris)
  publishWindow: string; // Local preferred window hypothesis (ex: 18:00-21:00)
  archetype: BrandArchetype;
  validationStage: ValidationStage;
  pillars: string[];
  status: BrandStatus;
  accentColor: string;
  secondaryColor: string;
  typographyNote: string;
  tagline: string;
  description: string;
  createdAt: string;
}

export type ProductStatus = 'Candidate' | 'Approved' | 'Rejected' | 'Archived';
export type ProductQualityGrade = 'A' | 'B' | 'C';
export type ComplianceState = 'PENDING' | 'APPROVED' | 'BLOCKED' | 'NOT_APPLICABLE';

export interface ProductEvidence {
  id: string;
  sourceName: string;
  url: string;
  summary: string;
  verifiedAt: string;
}

export interface ProductDecisionLog {
  id: string;
  previousStatus: ProductStatus;
  newStatus: ProductStatus;
  justification: string;
  actor: string;
  timestamp: string;
}

export interface Product {
  id: string;
  externalId: string; // Shared catalog ID across (platform, external_id)
  brandId: string; // Primary linked brand in UI context
  linkedBrandIds: string[]; // Shared catalog association across brands
  isTest: boolean; // Architecture Rule: test data separated from real operational metrics
  name: string;
  category: string;
  platform: string;
  remunerationModel: 'CPA' | 'RevShare' | 'Híbrido' | 'Direto';
  price: number | null;
  currency: CurrencyCode;
  commissionRatePct: number | null;
  cpaValue: number | null;
  epcValue: number | null; // Unknown stays null (never 0)
  cookieWindowDays: number | null;
  opportunityScore: number | null; // Deterministic score-6.1 (null when insufficient data)
  dataConfidence: 'Alta' | 'Média' | 'Baixa';
  qualityGrade: ProductQualityGrade | null; // Conceitual A/B/C quality classification
  complianceState: ComplianceState; // Conceitual Compliance Intelligence state
  complianceMarket: string; // Brasil | França/UE | Global
  demandTrendPct: number | null;
  competitionLevel: 'Baixa' | 'Média' | 'Alta' | 'Desconhecida';
  status: ProductStatus;
  evidence: ProductEvidence[];
  decisions: ProductDecisionLog[];
  updatedAt: string;
}

export type ContentStatus =
  | 'Brief'
  | 'Draft'
  | 'In Review'
  | 'Approved'
  | 'Published'
  | 'Rejected';

export type ContentFormat = 'Long-form' | 'Shorts' | 'Article';
export type ContentCategory = 'Descoberta' | 'Conexão' | 'Comercial contextual';
export type ContentVisibility = 'private' | 'unlisted' | 'public';
export type AnalysisMethod = 'Teste próprio' | 'Análise documental' | 'Comparativo de critérios';
export type SensitiveTopic =
  | 'Nenhum'
  | 'Saúde'
  | 'Finanças'
  | 'Apostas'
  | 'Infantil'
  | 'Segurança';

export interface DossierSource {
  id: string;
  claim: string;
  sourceTitle: string;
  level: 1 | 2 | 3 | 4; // 1: Peer-reviewed/Official, 2: Recognized, 3: Science media, 4: Forums (questions only)
  consultedAt: string;
}

export interface ContentVersion {
  version: string;
  manifestHash: string;
  author: string;
  note: string;
  feedbackCategory?: 'Tom' | 'Precisão/Fonte' | 'Estrutura' | 'Divulgação' | 'Conformidade' | 'Aprovação';
  timestamp: string;
  scriptSnapshot: string;
}

export interface ContentAuthorization {
  type: 'individual' | 'policy'; // MVP only allows 'individual'
  authorizedHash: string;
  actor: string;
  authorizedAt: string;
  expiresAt: string; // Explicit expiry timestamp with timezone
  rulesVersion: string;
  evidenceVerifiedAt: string;
  offerEndsAt?: string;
  revoked?: boolean;
  revokedReason?: string;
}

export interface ContentMetrics {
  views: number;
  retention30sPct: number;
  avgViewPct: number;
  clicks: number;
  conversions: number; // Explicitly labeled as Estimate [Em investigação]
  revenueGenerated: number;
  currency: CurrencyCode;
  trackingSrc: string;
  attributionStatus: 'Estimativa [Em investigação]' | 'Confirmada (Marca)' | 'Não atribuída';
}

export interface ContentItem {
  id: string;
  brandId: string;
  channelId: string;
  productId?: string;
  title: string;
  description: string;
  format: ContentFormat;
  category: ContentCategory;
  visibility: ContentVisibility;
  analysisMethod: AnalysisMethod;
  sensitiveTopic: SensitiveTopic;
  unclassifiedRiskFlag: boolean;
  status: ContentStatus;
  scheduledDate: string; // Operational schedule (outside manifest hash)
  publishedAt?: string;
  brief: string;
  angleIdea: string;
  script: string;
  affiliateLinkUrl: string;
  verifiedDestinationUrl: string;
  linkVerifiedAt: string;
  commercialConditionsVerifiedAt: string;
  offerEndsAt?: string;
  affiliateDisclosure: string;
  aiDisclosureRequired: boolean;
  aiDisclosureText: string;
  relevanceTestPassed: boolean; // 7-point relevance test
  editorialChecklistPassed: boolean; // 9-point editorial checklist
  humanHoursLogged: number; // Feeds Dimensão 2: Eficiência Operacional
  dossier: DossierSource[];
  references: string[];
  currentManifestHash: string;
  authorization: ContentAuthorization | null;
  versions: ContentVersion[];
  metrics?: ContentMetrics;
}

export type ChannelPlatform = 'YouTube' | 'Instagram' | 'TikTok' | 'Pinterest' | 'Website';
export type IntegrationStatus = 'Configurado (Demo)' | 'Atenção' | 'Desconectado';

export interface Channel {
  id: string;
  brandId: string;
  name: string;
  handle: string;
  platform: ChannelPlatform;
  language: string;
  advancedFeaturesUnlocked: boolean; // YouTube clickable links / related video eligibility
  integrationStatus: IntegrationStatus;
  followers: number;
  growthPct30d: number;
  views30d: number;
  reach30d: number;
  engagementRatePct: number;
  shortsToLongPct?: number; // Passagem Shorts -> Vídeo longo
  publications30d: number;
  lastSyncAt: string;
}

export type CommissionStage = 'Pending' | 'Confirmed' | 'Received';
export type FinanceEntryType = 'Commission' | 'DirectRevenue' | 'Expense' | 'Reinvestment';

export interface FinanceEntry {
  id: string;
  brandId: string;
  productId?: string;
  platform: string;
  description: string;
  type: FinanceEntryType;
  stage: CommissionStage;
  amount: number;
  currency: CurrencyCode;
  fxRateToBRL?: number;
  fxSource?: string;
  date: string;
  isTest?: boolean;
  isProjection?: boolean;
}

export type AgentCategory =
  | 'Research'
  | 'Product Intelligence'
  | 'Content'
  | 'Analytics'
  | 'Finance'
  | 'Operations';

export type AutonomyLevel = 0 | 1 | 2 | 3 | 4;
export type AgentRunState = 'Idle' | 'Running' | 'Paused' | 'Waiting Approval' | 'Error';

export interface AgentPolicyLimits {
  requireHumanApproval: boolean;
  maxActionsPerDay: number;
  maxDailySpendBRL: number;
  allowedModules: string[];
}

export interface AgentExecutionLog {
  id: string;
  timestamp: string;
  status: 'Success' | 'Failed' | 'Paused' | 'Awaiting Approval';
  durationSec: number;
  summary: string;
  recordsAffected: number;
}

export interface AutomationAgent {
  id: string;
  name: string;
  category: AgentCategory;
  autonomyLevel: AutonomyLevel; // 0=Manual, 1=ReadOnly, 2=Drafts/Score, 3=ApprovalReq, 4=Policy
  responsibility: string;
  state: AgentRunState;
  brandScope: string;
  dependencies: string[];
  flowSteps: string[];
  pendingApprovalCount: number;
  pendingApprovalSummary?: string;
  lastRunAt: string;
  lastError?: string;
  limits: AgentPolicyLimits;
  history: AgentExecutionLog[];
}

export interface JobRun {
  id: number;
  taskName: 'products.import' | 'products.score' | 'pipeline.run' | 'jobs.reconcile';
  mode: 'dry-run' | 'commit';
  status: 'running' | 'succeeded' | 'failed' | 'unknown';
  startedAt: string;
  finishedAt?: string;
  recordsProcessed: number;
  summary: string;
  error?: string;
}

export interface SystemControlState {
  state: 'ACTIVE' | 'HALTED';
  actor: string;
  reason: string;
  updatedAt: string;
  publishingEnabled: boolean; // Global PUBLISHING_ENABLED switch (off by default in safe mode)
  phaseBPublicAllowed: boolean; // Fase A (non-public only) vs Fase B (public authorized)
}

export interface RiskRegisterEntry {
  id: string;
  priority: 'P0' | 'P1' | 'P2';
  title: string;
  controlSummary: string;
  status: 'Mitigado (Demo)' | 'Pendente Infra' | 'Aberto';
}

export type ActivityCategory =
  | 'Decisão'
  | 'Autorização Hash'
  | 'Stop All'
  | 'Job Run'
  | 'Produto'
  | 'Conteúdo'
  | 'Finanças'
  | 'Automação'
  | 'Sistema';

export interface ActivityEvent {
  id: string;
  timestamp: string;
  brandId?: string;
  category: ActivityCategory;
  action: string;
  detail: string;
  justification?: string;
  actor: string;
  severity: 'info' | 'success' | 'warning' | 'error';
}

export type NotificationType =
  | 'financial'
  | 'commission_received'
  | 'opportunity'
  | 'approval_pending'
  | 'automation_error'
  | 'operational';

export interface NotificationItem {
  id: string;
  type: NotificationType;
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
  targetModule: NavModule;
  targetId?: string;
  brandId?: string;
  actionRequired?: boolean;
}

export interface IntegrationConfig {
  id: string;
  name: string;
  category: string;
  status: 'Pronto (Mock)' | 'Pendente' | 'Desativado';
  lastChecked: string;
  note?: string;
}

export interface OwnerSettings {
  ownerName: string;
  ownerEmail: string;
  roleLabel: string;
  theme: ThemeMode;
  uiLanguage: 'PT-BR' | 'EN-US';
  baseCurrency: CurrencyCode;
  globalAutonomyEnabled: boolean;
  emergencyStopActive: boolean;
  maxGlobalDailySpendBRL: number;
  requireApprovalForPublish: boolean;
  requireApprovalForProductStatus: boolean;
  defaultAuthValidityHours: number;
  evidenceFreshnessMaxHours: number;
  notificationPrefs: {
    financialAlerts: boolean;
    commissionsReceived: boolean;
    opportunities: boolean;
    pendingApprovals: boolean;
    automationFailures: boolean;
    operationalEvents: boolean;
  };
  integrations: IntegrationConfig[];
}

export interface VyronState {
  brands: Brand[];
  products: Product[];
  contents: ContentItem[];
  channels: Channel[];
  financeEntries: FinanceEntry[];
  automations: AutomationAgent[];
  jobRuns: JobRun[];
  systemControl: SystemControlState;
  risks: RiskRegisterEntry[];
  activities: ActivityEvent[];
  notifications: NotificationItem[];
  settings: OwnerSettings;
}
