enum VyronThemeMode {
  dark('dark'),
  light('light');

  const VyronThemeMode(this.wire);
  final String wire;

  static VyronThemeMode fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => VyronThemeMode.dark);
}

enum CurrencyCode {
  brl('BRL'),
  usd('USD'),
  eur('EUR');

  const CurrencyCode(this.wire);
  final String wire;

  static CurrencyCode fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => CurrencyCode.brl);
}

enum PeriodFilter {
  d7('7d'),
  d30('30d'),
  d90('90d'),
  m12('12m');

  const PeriodFilter(this.wire);
  final String wire;

  static PeriodFilter fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => PeriodFilter.d30);
}

enum UiLanguage {
  ptBR('PT-BR'),
  enUS('EN-US');

  const UiLanguage(this.wire);
  final String wire;

  static UiLanguage fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => UiLanguage.ptBR);
}

enum NavModule {
  overview('overview'),
  brands('brands'),
  products('products'),
  content('content'),
  channels('channels'),
  analytics('analytics'),
  finance('finance'),
  automations('automations'),
  activity('activity'),
  notifications('notifications'),
  settings('settings');

  const NavModule(this.wire);
  final String wire;

  static NavModule fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => NavModule.overview);
}

enum BrandStatus {
  active('Active'),
  paused('Paused'),
  archived('Archived');

  const BrandStatus(this.wire);
  final String wire;

  static BrandStatus fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => BrandStatus.active);
}

enum BrandArchetype {
  descobertaAutoridade('Descoberta & Autoridade'),
  pesquisaIntencao('Pesquisa & Intenção'),
  hibrida('Híbrida');

  const BrandArchetype(this.wire);
  final String wire;

  static BrandArchetype fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => BrandArchetype.hibrida,
      );
}

enum ValidationStage {
  exploracao('1. Exploração'),
  interesse('2. Interesse'),
  validacaoConversao('3. Validação de Conversão'),
  resultadoFinanceiro('4. Resultado Financeiro'),
  sustentabilidade('5. Sustentabilidade');

  const ValidationStage(this.wire);
  final String wire;

  static ValidationStage fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ValidationStage.exploracao,
      );
}

enum ProductStatus {
  candidate('Candidate'),
  approved('Approved'),
  rejected('Rejected'),
  archived('Archived');

  const ProductStatus(this.wire);
  final String wire;

  static ProductStatus fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => ProductStatus.candidate);
}

enum ProductQualityGrade {
  a('A'),
  b('B'),
  c('C');

  const ProductQualityGrade(this.wire);
  final String wire;

  static ProductQualityGrade? fromWire(String? v) {
    if (v == null) return null;
    for (final e in values) {
      if (e.wire == v) return e;
    }
    return null;
  }
}

enum ComplianceState {
  pending('PENDING'),
  approved('APPROVED'),
  blocked('BLOCKED'),
  notApplicable('NOT_APPLICABLE');

  const ComplianceState(this.wire);
  final String wire;

  static ComplianceState fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ComplianceState.pending,
      );
}

enum RemunerationModel {
  cpa('CPA'),
  revShare('RevShare'),
  hibrido('Híbrido'),
  direto('Direto');

  const RemunerationModel(this.wire);
  final String wire;

  static RemunerationModel fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => RemunerationModel.revShare,
      );
}

enum DataConfidence {
  alta('Alta'),
  media('Média'),
  baixa('Baixa');

  const DataConfidence(this.wire);
  final String wire;

  static DataConfidence fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => DataConfidence.media);
}

enum CompetitionLevel {
  baixa('Baixa'),
  media('Média'),
  alta('Alta'),
  desconhecida('Desconhecida');

  const CompetitionLevel(this.wire);
  final String wire;

  static CompetitionLevel fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => CompetitionLevel.desconhecida,
      );
}

enum ContentStatus {
  brief('Brief'),
  draft('Draft'),
  inReview('In Review'),
  approved('Approved'),
  published('Published'),
  rejected('Rejected');

  const ContentStatus(this.wire);
  final String wire;

  static ContentStatus fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => ContentStatus.draft);
}

enum ContentFormat {
  longForm('Long-form'),
  shorts('Shorts'),
  article('Article');

  const ContentFormat(this.wire);
  final String wire;

  static ContentFormat fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => ContentFormat.longForm);
}

enum ContentCategory {
  descoberta('Descoberta'),
  conexao('Conexão'),
  comercialContextual('Comercial contextual');

  const ContentCategory(this.wire);
  final String wire;

  static ContentCategory fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ContentCategory.descoberta,
      );
}

enum ContentVisibility {
  privateVis('private'),
  unlisted('unlisted'),
  publicVis('public');

  const ContentVisibility(this.wire);
  final String wire;

  static ContentVisibility fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ContentVisibility.unlisted,
      );
}

enum AnalysisMethod {
  testeProprio('Teste próprio'),
  analiseDocumental('Análise documental'),
  comparativoCriterios('Comparativo de critérios');

  const AnalysisMethod(this.wire);
  final String wire;

  static AnalysisMethod fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => AnalysisMethod.analiseDocumental,
      );
}

enum SensitiveTopic {
  nenhum('Nenhum'),
  saude('Saúde'),
  financas('Finanças'),
  apostas('Apostas'),
  infantil('Infantil'),
  seguranca('Segurança');

  const SensitiveTopic(this.wire);
  final String wire;

  static SensitiveTopic fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => SensitiveTopic.nenhum);
}

enum FeedbackCategory {
  tom('Tom'),
  precisaoFonte('Precisão/Fonte'),
  estrutura('Estrutura'),
  divulgacao('Divulgação'),
  conformidade('Conformidade'),
  aprovacao('Aprovação');

  const FeedbackCategory(this.wire);
  final String wire;

  static FeedbackCategory? fromWire(String? v) {
    if (v == null) return null;
    for (final e in values) {
      if (e.wire == v) return e;
    }
    return null;
  }
}

enum AuthorizationType {
  individual('individual'),
  policy('policy');

  const AuthorizationType(this.wire);
  final String wire;

  static AuthorizationType fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => AuthorizationType.individual,
      );
}

enum AttributionStatus {
  estimativaEmInvestigacao('Estimativa [Em investigação]'),
  confirmadaMarca('Confirmada (Marca)'),
  naoAtribuida('Não atribuída');

  const AttributionStatus(this.wire);
  final String wire;

  static AttributionStatus fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => AttributionStatus.estimativaEmInvestigacao,
      );
}

enum ChannelPlatform {
  youtube('YouTube'),
  instagram('Instagram'),
  tiktok('TikTok'),
  pinterest('Pinterest'),
  website('Website');

  const ChannelPlatform(this.wire);
  final String wire;

  static ChannelPlatform fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ChannelPlatform.youtube,
      );
}

enum ChannelIntegrationStatus {
  configuradoDemo('Configurado (Demo)'),
  atencao('Atenção'),
  desconectado('Desconectado');

  const ChannelIntegrationStatus(this.wire);
  final String wire;

  static ChannelIntegrationStatus fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ChannelIntegrationStatus.configuradoDemo,
      );
}

enum CommissionStage {
  pending('Pending'),
  confirmed('Confirmed'),
  received('Received');

  const CommissionStage(this.wire);
  final String wire;

  static CommissionStage fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => CommissionStage.pending,
      );
}

enum FinanceEntryType {
  commission('Commission'),
  directRevenue('DirectRevenue'),
  expense('Expense'),
  reinvestment('Reinvestment');

  const FinanceEntryType(this.wire);
  final String wire;

  static FinanceEntryType fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => FinanceEntryType.commission,
      );
}

enum AgentCategory {
  research('Research'),
  productIntelligence('Product Intelligence'),
  content('Content'),
  analytics('Analytics'),
  finance('Finance'),
  operations('Operations');

  const AgentCategory(this.wire);
  final String wire;

  static AgentCategory fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => AgentCategory.operations,
      );
}

enum AgentRunState {
  idle('Idle'),
  running('Running'),
  paused('Paused'),
  waitingApproval('Waiting Approval'),
  error('Error');

  const AgentRunState(this.wire);
  final String wire;

  static AgentRunState fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => AgentRunState.idle);
}

enum AgentExecutionStatus {
  success('Success'),
  failed('Failed'),
  paused('Paused'),
  awaitingApproval('Awaiting Approval');

  const AgentExecutionStatus(this.wire);
  final String wire;

  static AgentExecutionStatus fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => AgentExecutionStatus.success,
      );
}

enum JobTaskName {
  productsImport('products.import'),
  productsScore('products.score'),
  pipelineRun('pipeline.run'),
  jobsReconcile('jobs.reconcile');

  const JobTaskName(this.wire);
  final String wire;

  static JobTaskName fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => JobTaskName.pipelineRun);
}

enum JobMode {
  dryRun('dry-run'),
  commit('commit');

  const JobMode(this.wire);
  final String wire;

  static JobMode fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => JobMode.dryRun);
}

enum JobRunStatus {
  running('running'),
  succeeded('succeeded'),
  failed('failed'),
  unknown('unknown');

  const JobRunStatus(this.wire);
  final String wire;

  static JobRunStatus fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => JobRunStatus.unknown);
}

enum SystemControlStatus {
  active('ACTIVE'),
  halted('HALTED');

  const SystemControlStatus(this.wire);
  final String wire;

  static SystemControlStatus fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => SystemControlStatus.active,
      );
}

enum RiskPriority {
  p0('P0'),
  p1('P1'),
  p2('P2');

  const RiskPriority(this.wire);
  final String wire;

  static RiskPriority fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => RiskPriority.p1);
}

enum RiskStatus {
  mitigadoDemo('Mitigado (Demo)'),
  pendenteInfra('Pendente Infra'),
  aberto('Aberto');

  const RiskStatus(this.wire);
  final String wire;

  static RiskStatus fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => RiskStatus.aberto);
}

enum ActivityCategory {
  decisao('Decisão'),
  autorizacaoHash('Autorização Hash'),
  stopAll('Stop All'),
  jobRun('Job Run'),
  produto('Produto'),
  conteudo('Conteúdo'),
  financas('Finanças'),
  automacao('Automação'),
  sistema('Sistema');

  const ActivityCategory(this.wire);
  final String wire;

  static ActivityCategory fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ActivityCategory.sistema,
      );
}

enum ActivitySeverity {
  info('info'),
  success('success'),
  warning('warning'),
  error('error');

  const ActivitySeverity(this.wire);
  final String wire;

  static ActivitySeverity fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ActivitySeverity.info,
      );
}

enum NotificationType {
  financial('financial'),
  commissionReceived('commission_received'),
  opportunity('opportunity'),
  approvalPending('approval_pending'),
  automationError('automation_error'),
  operational('operational');

  const NotificationType(this.wire);
  final String wire;

  static NotificationType fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => NotificationType.operational,
      );
}

enum IntegrationConfigStatus {
  prontoMock('Pronto (Mock)'),
  pendente('Pendente'),
  desativado('Desativado');

  const IntegrationConfigStatus(this.wire);
  final String wire;

  static IntegrationConfigStatus fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        orElse: () => IntegrationConfigStatus.pendente,
      );
}
