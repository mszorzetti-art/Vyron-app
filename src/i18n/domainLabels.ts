import {
  ActivityCategory,
  AgentCategory,
  AgentExecutionLog,
  AgentRunState,
  AnalysisMethod,
  AutonomyLevel,
  BrandArchetype,
  BrandStatus,
  CommissionStage,
  ComplianceState,
  ContentCategory,
  ContentFormat,
  ContentMetrics,
  ContentStatus,
  ContentVersion,
  ContentVisibility,
  FinanceEntryType,
  IntegrationConfig,
  IntegrationStatus,
  JobRun,
  NotificationType,
  Product,
  ProductQualityGrade,
  ProductStatus,
  RiskRegisterEntry,
  SensitiveTopic,
  SystemControlState,
  ValidationStage,
} from '../types/vyron';
import { UiLanguage } from './types';

export function labelBrandStatus(status: BrandStatus, lang: UiLanguage): string {
  if (lang === 'EN-US') return status;
  switch (status) {
    case 'Active':
      return 'Ativo';
    case 'Paused':
      return 'Pausado';
    case 'Archived':
      return 'Arquivado';
  }
}

export function labelProductStatus(status: ProductStatus, lang: UiLanguage): string {
  if (lang === 'EN-US') return status;
  switch (status) {
    case 'Candidate':
      return 'Candidato';
    case 'Approved':
      return 'Aprovado';
    case 'Rejected':
      return 'Rejeitado';
    case 'Archived':
      return 'Arquivado';
  }
}

export function labelContentStatus(status: ContentStatus, lang: UiLanguage): string {
  if (lang === 'EN-US') {
    if (status === 'Brief') return 'Content Plan';
    return status;
  }
  switch (status) {
    case 'Brief':
      return 'Planejamento de conteúdo';
    case 'Draft':
      return 'Rascunho';
    case 'In Review':
      return 'Em revisão';
    case 'Approved':
      return 'Aprovado';
    case 'Published':
      return 'Publicado';
    case 'Rejected':
      return 'Rejeitado';
  }
}

export function labelComplianceState(state: ComplianceState, lang: UiLanguage): string {
  if (lang === 'EN-US') {
    switch (state) {
      case 'APPROVED':
        return 'Approved';
      case 'PENDING':
        return 'Pending';
      case 'BLOCKED':
        return 'Blocked';
      case 'NOT_APPLICABLE':
        return 'N/A';
    }
  }
  switch (state) {
    case 'APPROVED':
      return 'Aprovado';
    case 'PENDING':
      return 'Pendente';
    case 'BLOCKED':
      return 'Bloqueado';
    case 'NOT_APPLICABLE':
      return 'N/A';
  }
}

export function labelChannelIntegrationStatus(status: IntegrationStatus, lang: UiLanguage): string {
  if (lang === 'PT-BR') return status;
  switch (status) {
    case 'Configurado (Demo)':
      return 'Configured (Demo)';
    case 'Atenção':
      return 'Attention';
    case 'Desconectado':
      return 'Disconnected';
  }
}

export function labelIntegrationConfigStatus(
  status: IntegrationConfig['status'],
  lang: UiLanguage
): string {
  if (lang === 'PT-BR') return status;
  switch (status) {
    case 'Pronto (Mock)':
      return 'Ready (Demo)';
    case 'Pendente':
      return 'Pending';
    case 'Desativado':
      return 'Disabled';
  }
}

export function labelAgentState(state: AgentRunState, lang: UiLanguage): string {
  if (lang === 'EN-US') return state;
  switch (state) {
    case 'Idle':
      return 'Em espera';
    case 'Running':
      return 'Em execução';
    case 'Paused':
      return 'Pausado';
    case 'Waiting Approval':
      return 'Aguardando aprovação';
    case 'Error':
      return 'Falha';
  }
}

export function labelAgentExecutionStatus(
  status: AgentExecutionLog['status'],
  lang: UiLanguage
): string {
  if (lang === 'EN-US') return status;
  switch (status) {
    case 'Success':
      return 'Concluído';
    case 'Failed':
      return 'Falhou';
    case 'Paused':
      return 'Pausado';
    case 'Awaiting Approval':
      return 'Aguardando aprovação';
  }
}

export function labelJobStatus(status: JobRun['status'], lang: UiLanguage): string {
  if (lang === 'EN-US') {
    switch (status) {
      case 'running':
        return 'Running';
      case 'succeeded':
        return 'Succeeded';
      case 'failed':
        return 'Failed';
      case 'unknown':
        return 'Unknown';
    }
  }
  switch (status) {
    case 'running':
      return 'Em execução';
    case 'succeeded':
      return 'Concluído';
    case 'failed':
      return 'Falhou';
    case 'unknown':
      return 'Desconhecido';
  }
}

export function labelJobMode(mode: JobRun['mode'], lang: UiLanguage): string {
  if (lang === 'EN-US') {
    return mode === 'dry-run' ? 'Simulation' : 'Live commit';
  }
  return mode === 'dry-run' ? 'Simulação' : 'Gravação';
}

export function labelRiskStatus(status: RiskRegisterEntry['status'], lang: UiLanguage): string {
  if (lang === 'PT-BR') {
    switch (status) {
      case 'Mitigado (Demo)':
        return 'Mitigado no protótipo';
      case 'Pendente Infra':
        return 'Infraestrutura pendente';
      case 'Aberto':
        return 'Aberto';
    }
  }
  switch (status) {
    case 'Mitigado (Demo)':
      return 'Mitigated in prototype';
    case 'Pendente Infra':
      return 'Pending infrastructure';
    case 'Aberto':
      return 'Open';
  }
}

export function labelCommissionStage(stage: CommissionStage, lang: UiLanguage): string {
  if (lang === 'EN-US') return stage;
  switch (stage) {
    case 'Pending':
      return 'Pendente';
    case 'Confirmed':
      return 'Confirmado';
    case 'Received':
      return 'Recebido';
  }
}

export function labelFinanceType(type: FinanceEntryType, lang: UiLanguage): string {
  if (lang === 'EN-US') {
    switch (type) {
      case 'Commission':
        return 'Commission';
      case 'DirectRevenue':
        return 'Direct Revenue';
      case 'Expense':
        return 'Expense';
      case 'Reinvestment':
        return 'Reinvestment';
    }
  }
  switch (type) {
    case 'Commission':
      return 'Comissão';
    case 'DirectRevenue':
      return 'Receita direta';
    case 'Expense':
      return 'Despesa';
    case 'Reinvestment':
      return 'Reinvestimento';
  }
}

export function labelSystemControlState(
  state: SystemControlState['state'],
  lang: UiLanguage
): string {
  if (lang === 'EN-US') {
    return state === 'ACTIVE' ? 'Active' : 'Halted';
  }
  return state === 'ACTIVE' ? 'Ativo' : 'Interrompido';
}

export function labelBrandArchetype(archetype: BrandArchetype, lang: UiLanguage): string {
  if (lang === 'PT-BR') return archetype;
  switch (archetype) {
    case 'Descoberta & Autoridade':
      return 'Discovery & Authority';
    case 'Pesquisa & Intenção':
      return 'Search & Intent';
    case 'Híbrida':
      return 'Hybrid';
  }
}

export function labelValidationStage(stage: ValidationStage, lang: UiLanguage): string {
  if (lang === 'PT-BR') return stage;
  switch (stage) {
    case '1. Exploração':
      return '1. Exploration';
    case '2. Interesse':
      return '2. Interest';
    case '3. Validação de Conversão':
      return '3. Conversion Validation';
    case '4. Resultado Financeiro':
      return '4. Financial Result';
    case '5. Sustentabilidade':
      return '5. Sustainability';
  }
}

export function labelContentFormat(format: ContentFormat, lang: UiLanguage): string {
  if (lang === 'EN-US') return format;
  switch (format) {
    case 'Long-form':
      return 'Vídeo longo';
    case 'Shorts':
      return 'Shorts';
    case 'Article':
      return 'Artigo';
  }
}

export function labelContentCategory(category: ContentCategory, lang: UiLanguage): string {
  if (lang === 'PT-BR') return category;
  switch (category) {
    case 'Descoberta':
      return 'Discovery';
    case 'Conexão':
      return 'Connection';
    case 'Comercial contextual':
      return 'Contextual commercial';
  }
}

export function labelContentVisibility(visibility: ContentVisibility, lang: UiLanguage): string {
  if (lang === 'EN-US') {
    switch (visibility) {
      case 'private':
        return 'Private';
      case 'unlisted':
        return 'Unlisted';
      case 'public':
        return 'Public';
    }
  }
  switch (visibility) {
    case 'private':
      return 'Privado';
    case 'unlisted':
      return 'Não listado';
    case 'public':
      return 'Público';
  }
}

export function labelAnalysisMethod(method: AnalysisMethod, lang: UiLanguage): string {
  if (lang === 'PT-BR') return method;
  switch (method) {
    case 'Teste próprio':
      return 'Hands-on testing';
    case 'Análise documental':
      return 'Documentary analysis';
    case 'Comparativo de critérios':
      return 'Criteria comparison';
  }
}

export function labelSensitiveTopic(topic: SensitiveTopic, lang: UiLanguage): string {
  if (lang === 'PT-BR') return topic;
  switch (topic) {
    case 'Nenhum':
      return 'None';
    case 'Saúde':
      return 'Health';
    case 'Finanças':
      return 'Finance';
    case 'Apostas':
      return 'Gambling';
    case 'Infantil':
      return 'Children';
    case 'Segurança':
      return 'Safety';
  }
}

export function labelFeedbackCategory(
  cat: NonNullable<ContentVersion['feedbackCategory']>,
  lang: UiLanguage
): string {
  if (lang === 'PT-BR') return cat;
  switch (cat) {
    case 'Tom':
      return 'Tone';
    case 'Precisão/Fonte':
      return 'Accuracy / Source';
    case 'Estrutura':
      return 'Structure';
    case 'Divulgação':
      return 'Disclosure';
    case 'Conformidade':
      return 'Compliance';
    case 'Aprovação':
      return 'Approval';
  }
}

export function labelAgentCategory(category: AgentCategory, lang: UiLanguage): string {
  if (lang === 'EN-US') return category;
  switch (category) {
    case 'Research':
      return 'Pesquisa';
    case 'Product Intelligence':
      return 'Inteligência de Produtos';
    case 'Content':
      return 'Conteúdo';
    case 'Analytics':
      return 'Analytics';
    case 'Finance':
      return 'Financeiro';
    case 'Operations':
      return 'Operações';
  }
}

export function labelAutonomyLevel(level: AutonomyLevel, lang: UiLanguage): string {
  if (lang === 'EN-US') {
    switch (level) {
      case 0:
        return 'Manual';
      case 1:
        return 'Read-only';
      case 2:
        return 'Drafts / Index';
      case 3:
        return 'Approval required';
      case 4:
        return 'Policy-bounded';
    }
  }
  switch (level) {
    case 0:
      return 'Manual';
    case 1:
      return 'Leitura';
    case 2:
      return 'Rascunho / Índice';
    case 3:
      return 'Aprovação obrigatória';
    case 4:
      return 'Sob política';
  }
}

export function labelActivityCategory(cat: ActivityCategory, lang: UiLanguage): string {
  if (lang === 'PT-BR') {
    return cat === 'Job Run' ? 'Execução de tarefa' : cat;
  }
  switch (cat) {
    case 'Decisão':
      return 'Decision';
    case 'Autorização Hash':
      return 'Hash Authorization';
    case 'Stop All':
      return 'Stop All';
    case 'Job Run':
      return 'Job Run';
    case 'Produto':
      return 'Product';
    case 'Conteúdo':
      return 'Content';
    case 'Finanças':
      return 'Finance';
    case 'Automação':
      return 'Automation';
    case 'Sistema':
      return 'System';
  }
}

export function labelNotificationType(type: NotificationType, lang: UiLanguage): string {
  if (lang === 'EN-US') {
    switch (type) {
      case 'approval_pending':
        return 'Approval pending';
      case 'commission_received':
        return 'Commission received';
      case 'automation_error':
        return 'Operational failure';
      case 'opportunity':
        return 'Opportunity';
      case 'financial':
        return 'Financial';
      case 'operational':
        return 'Operational';
    }
  }
  switch (type) {
    case 'approval_pending':
      return 'Aprovação pendente';
    case 'commission_received':
      return 'Comissão recebida';
    case 'automation_error':
      return 'Falha operacional';
    case 'opportunity':
      return 'Oportunidade';
    case 'financial':
      return 'Financeiro';
    case 'operational':
      return 'Operacional';
  }
}

export function labelProductModel(
  model: Product['remunerationModel'],
  lang: UiLanguage
): string {
  if (lang === 'PT-BR') return model;
  switch (model) {
    case 'CPA':
      return 'CPA';
    case 'RevShare':
      return 'RevShare';
    case 'Híbrido':
      return 'Hybrid';
    case 'Direto':
      return 'Direct';
  }
}

export function labelDataConfidence(
  val: Product['dataConfidence'],
  lang: UiLanguage
): string {
  if (lang === 'PT-BR') return val;
  switch (val) {
    case 'Alta':
      return 'High';
    case 'Média':
      return 'Medium';
    case 'Baixa':
      return 'Low';
  }
}

export function labelCompetitionLevel(
  val: Product['competitionLevel'],
  lang: UiLanguage
): string {
  if (lang === 'PT-BR') return val;
  switch (val) {
    case 'Baixa':
      return 'Low';
    case 'Média':
      return 'Medium';
    case 'Alta':
      return 'High';
    case 'Desconhecida':
      return 'Unknown';
  }
}

export function labelComplianceMarket(market: string, lang: UiLanguage): string {
  if (lang === 'PT-BR') return market;
  if (market === 'Brasil') return 'Brazil';
  if (market === 'França / UE') return 'France / EU';
  if (market === 'França / UE & América do Norte') return 'France / EU & North America';
  return market;
}

export function labelProductGradeBadge(
  grade: ProductQualityGrade | null,
  lang: UiLanguage
): string {
  if (!grade) return lang === 'EN-US' ? 'Grade —' : 'Nota —';
  return lang === 'EN-US' ? `Grade ${grade}` : `Nota ${grade}`;
}

export function labelAttributionStatus(
  status: ContentMetrics['attributionStatus'],
  lang: UiLanguage
): string {
  if (lang === 'PT-BR') return status;
  switch (status) {
    case 'Estimativa [Em investigação]':
      return 'Estimate [Under review]';
    case 'Confirmada (Marca)':
      return 'Confirmed (Brand)';
    case 'Não atribuída':
      return 'Unattributed';
  }
}
