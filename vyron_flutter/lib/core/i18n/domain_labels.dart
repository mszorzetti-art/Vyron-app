import '../../domain/models/vyron_enums.dart';

String labelBrandStatus(BrandStatus status, UiLanguage lang) {
  if (lang == UiLanguage.enUS) return status.wire;
  switch (status) {
    case BrandStatus.active:
      return 'Ativo';
    case BrandStatus.paused:
      return 'Pausado';
    case BrandStatus.archived:
      return 'Arquivado';
  }
}

String labelProductStatus(ProductStatus status, UiLanguage lang) {
  if (lang == UiLanguage.enUS) return status.wire;
  switch (status) {
    case ProductStatus.candidate:
      return 'Candidato';
    case ProductStatus.approved:
      return 'Aprovado';
    case ProductStatus.rejected:
      return 'Rejeitado';
    case ProductStatus.archived:
      return 'Arquivado';
  }
}

String labelContentStatus(ContentStatus status, UiLanguage lang) {
  if (lang == UiLanguage.enUS) {
    if (status == ContentStatus.brief) return 'Content Plan';
    return status.wire;
  }
  switch (status) {
    case ContentStatus.brief:
      return 'Planejamento de conteúdo';
    case ContentStatus.draft:
      return 'Rascunho';
    case ContentStatus.inReview:
      return 'Em revisão';
    case ContentStatus.approved:
      return 'Aprovado';
    case ContentStatus.published:
      return 'Publicado';
    case ContentStatus.rejected:
      return 'Rejeitado';
  }
}

String labelComplianceState(ComplianceState state, UiLanguage lang) {
  if (lang == UiLanguage.enUS) {
    switch (state) {
      case ComplianceState.approved:
        return 'Approved';
      case ComplianceState.pending:
        return 'Pending';
      case ComplianceState.blocked:
        return 'Blocked';
      case ComplianceState.notApplicable:
        return 'N/A';
    }
  }
  switch (state) {
    case ComplianceState.approved:
      return 'Aprovado';
    case ComplianceState.pending:
      return 'Pendente';
    case ComplianceState.blocked:
      return 'Bloqueado';
    case ComplianceState.notApplicable:
      return 'N/A';
  }
}

String labelChannelIntegrationStatus(
  ChannelIntegrationStatus status,
  UiLanguage lang,
) {
  if (lang == UiLanguage.ptBR) return status.wire;
  switch (status) {
    case ChannelIntegrationStatus.configuradoDemo:
      return 'Configured (Demo)';
    case ChannelIntegrationStatus.atencao:
      return 'Attention';
    case ChannelIntegrationStatus.desconectado:
      return 'Disconnected';
  }
}

String labelIntegrationConfigStatus(
  IntegrationConfigStatus status,
  UiLanguage lang,
) {
  if (lang == UiLanguage.ptBR) return status.wire;
  switch (status) {
    case IntegrationConfigStatus.prontoMock:
      return 'Ready (Demo)';
    case IntegrationConfigStatus.pendente:
      return 'Pending';
    case IntegrationConfigStatus.desativado:
      return 'Disabled';
  }
}

String labelAgentState(AgentRunState state, UiLanguage lang) {
  if (lang == UiLanguage.enUS) return state.wire;
  switch (state) {
    case AgentRunState.idle:
      return 'Em espera';
    case AgentRunState.running:
      return 'Em execução';
    case AgentRunState.paused:
      return 'Pausado';
    case AgentRunState.waitingApproval:
      return 'Aguardando aprovação';
    case AgentRunState.error:
      return 'Falha';
  }
}

String labelAgentExecutionStatus(AgentExecutionStatus status, UiLanguage lang) {
  if (lang == UiLanguage.enUS) return status.wire;
  switch (status) {
    case AgentExecutionStatus.success:
      return 'Concluído';
    case AgentExecutionStatus.failed:
      return 'Falhou';
    case AgentExecutionStatus.paused:
      return 'Pausado';
    case AgentExecutionStatus.awaitingApproval:
      return 'Aguardando aprovação';
  }
}

String labelJobStatus(JobRunStatus status, UiLanguage lang) {
  if (lang == UiLanguage.enUS) {
    switch (status) {
      case JobRunStatus.running:
        return 'Running';
      case JobRunStatus.succeeded:
        return 'Succeeded';
      case JobRunStatus.failed:
        return 'Failed';
      case JobRunStatus.unknown:
        return 'Unknown';
    }
  }
  switch (status) {
    case JobRunStatus.running:
      return 'Em execução';
    case JobRunStatus.succeeded:
      return 'Concluído';
    case JobRunStatus.failed:
      return 'Falhou';
    case JobRunStatus.unknown:
      return 'Desconhecido';
  }
}

String labelJobMode(JobMode mode, UiLanguage lang) {
  if (lang == UiLanguage.enUS) {
    return mode == JobMode.dryRun ? 'Simulation' : 'Live commit';
  }
  return mode == JobMode.dryRun ? 'Simulação' : 'Gravação';
}

String labelRiskStatus(RiskStatus status, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) {
    switch (status) {
      case RiskStatus.mitigadoDemo:
        return 'Mitigado no protótipo';
      case RiskStatus.pendenteInfra:
        return 'Infraestrutura pendente';
      case RiskStatus.aberto:
        return 'Aberto';
    }
  }
  switch (status) {
    case RiskStatus.mitigadoDemo:
      return 'Mitigated in prototype';
    case RiskStatus.pendenteInfra:
      return 'Pending infrastructure';
    case RiskStatus.aberto:
      return 'Open';
  }
}

String labelCommissionStage(CommissionStage stage, UiLanguage lang) {
  if (lang == UiLanguage.enUS) return stage.wire;
  switch (stage) {
    case CommissionStage.pending:
      return 'Pendente';
    case CommissionStage.confirmed:
      return 'Confirmado';
    case CommissionStage.received:
      return 'Recebido';
  }
}

String labelFinanceType(FinanceEntryType type, UiLanguage lang) {
  if (lang == UiLanguage.enUS) {
    switch (type) {
      case FinanceEntryType.commission:
        return 'Commission';
      case FinanceEntryType.directRevenue:
        return 'Direct Revenue';
      case FinanceEntryType.expense:
        return 'Expense';
      case FinanceEntryType.reinvestment:
        return 'Reinvestment';
    }
  }
  switch (type) {
    case FinanceEntryType.commission:
      return 'Comissão';
    case FinanceEntryType.directRevenue:
      return 'Receita direta';
    case FinanceEntryType.expense:
      return 'Despesa';
    case FinanceEntryType.reinvestment:
      return 'Reinvestimento';
  }
}

String labelSystemControlState(SystemControlStatus state, UiLanguage lang) {
  if (lang == UiLanguage.enUS) {
    return state == SystemControlStatus.active ? 'Active' : 'Halted';
  }
  return state == SystemControlStatus.active ? 'Ativo' : 'Interrompido';
}

String labelBrandArchetype(BrandArchetype archetype, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return archetype.wire;
  switch (archetype) {
    case BrandArchetype.descobertaAutoridade:
      return 'Discovery & Authority';
    case BrandArchetype.pesquisaIntencao:
      return 'Search & Intent';
    case BrandArchetype.hibrida:
      return 'Hybrid';
  }
}

String labelValidationStage(ValidationStage stage, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return stage.wire;
  switch (stage) {
    case ValidationStage.exploracao:
      return '1. Exploration';
    case ValidationStage.interesse:
      return '2. Interest';
    case ValidationStage.validacaoConversao:
      return '3. Conversion Validation';
    case ValidationStage.resultadoFinanceiro:
      return '4. Financial Result';
    case ValidationStage.sustentabilidade:
      return '5. Sustainability';
  }
}

String labelContentFormat(ContentFormat format, UiLanguage lang) {
  if (lang == UiLanguage.enUS) return format.wire;
  switch (format) {
    case ContentFormat.longForm:
      return 'Vídeo longo';
    case ContentFormat.shorts:
      return 'Shorts';
    case ContentFormat.article:
      return 'Artigo';
  }
}

String labelContentCategory(ContentCategory category, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return category.wire;
  switch (category) {
    case ContentCategory.descoberta:
      return 'Discovery';
    case ContentCategory.conexao:
      return 'Connection';
    case ContentCategory.comercialContextual:
      return 'Contextual commercial';
  }
}

String labelContentVisibility(ContentVisibility visibility, UiLanguage lang) {
  if (lang == UiLanguage.enUS) {
    switch (visibility) {
      case ContentVisibility.privateVis:
        return 'Private';
      case ContentVisibility.unlisted:
        return 'Unlisted';
      case ContentVisibility.publicVis:
        return 'Public';
    }
  }
  switch (visibility) {
    case ContentVisibility.privateVis:
      return 'Privado';
    case ContentVisibility.unlisted:
      return 'Não listado';
    case ContentVisibility.publicVis:
      return 'Público';
  }
}

String labelAnalysisMethod(AnalysisMethod method, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return method.wire;
  switch (method) {
    case AnalysisMethod.testeProprio:
      return 'Hands-on testing';
    case AnalysisMethod.analiseDocumental:
      return 'Documentary analysis';
    case AnalysisMethod.comparativoCriterios:
      return 'Criteria comparison';
  }
}

String labelSensitiveTopic(SensitiveTopic topic, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return topic.wire;
  switch (topic) {
    case SensitiveTopic.nenhum:
      return 'None';
    case SensitiveTopic.saude:
      return 'Health';
    case SensitiveTopic.financas:
      return 'Finance';
    case SensitiveTopic.apostas:
      return 'Gambling';
    case SensitiveTopic.infantil:
      return 'Children';
    case SensitiveTopic.seguranca:
      return 'Safety';
  }
}

String labelFeedbackCategory(FeedbackCategory cat, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return cat.wire;
  switch (cat) {
    case FeedbackCategory.tom:
      return 'Tone';
    case FeedbackCategory.precisaoFonte:
      return 'Accuracy / Source';
    case FeedbackCategory.estrutura:
      return 'Structure';
    case FeedbackCategory.divulgacao:
      return 'Disclosure';
    case FeedbackCategory.conformidade:
      return 'Compliance';
    case FeedbackCategory.aprovacao:
      return 'Approval';
  }
}

String labelAgentCategory(AgentCategory category, UiLanguage lang) {
  if (lang == UiLanguage.enUS) return category.wire;
  switch (category) {
    case AgentCategory.research:
      return 'Pesquisa';
    case AgentCategory.productIntelligence:
      return 'Inteligência de Produtos';
    case AgentCategory.content:
      return 'Conteúdo';
    case AgentCategory.analytics:
      return 'Analytics';
    case AgentCategory.finance:
      return 'Financeiro';
    case AgentCategory.operations:
      return 'Operações';
  }
}

String labelAutonomyLevel(int level, UiLanguage lang) {
  if (lang == UiLanguage.enUS) {
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
      default:
        return 'Level $level';
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
    default:
      return 'Nível $level';
  }
}

String labelActivityCategory(ActivityCategory cat, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) {
    return cat == ActivityCategory.jobRun ? 'Execução de tarefa' : cat.wire;
  }
  switch (cat) {
    case ActivityCategory.decisao:
      return 'Decision';
    case ActivityCategory.autorizacaoHash:
      return 'Hash Authorization';
    case ActivityCategory.stopAll:
      return 'Stop All';
    case ActivityCategory.jobRun:
      return 'Job Run';
    case ActivityCategory.produto:
      return 'Product';
    case ActivityCategory.conteudo:
      return 'Content';
    case ActivityCategory.financas:
      return 'Finance';
    case ActivityCategory.automacao:
      return 'Automation';
    case ActivityCategory.sistema:
      return 'System';
  }
}

String labelNotificationType(NotificationType type, UiLanguage lang) {
  if (lang == UiLanguage.enUS) {
    switch (type) {
      case NotificationType.approvalPending:
        return 'Approval pending';
      case NotificationType.commissionReceived:
        return 'Commission received';
      case NotificationType.automationError:
        return 'Operational failure';
      case NotificationType.opportunity:
        return 'Opportunity';
      case NotificationType.financial:
        return 'Financial';
      case NotificationType.operational:
        return 'Operational';
    }
  }
  switch (type) {
    case NotificationType.approvalPending:
      return 'Aprovação pendente';
    case NotificationType.commissionReceived:
      return 'Comissão recebida';
    case NotificationType.automationError:
      return 'Falha operacional';
    case NotificationType.opportunity:
      return 'Oportunidade';
    case NotificationType.financial:
      return 'Financeiro';
    case NotificationType.operational:
      return 'Operacional';
  }
}

String labelProductModel(RemunerationModel model, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return model.wire;
  switch (model) {
    case RemunerationModel.cpa:
      return 'CPA';
    case RemunerationModel.revShare:
      return 'RevShare';
    case RemunerationModel.hibrido:
      return 'Hybrid';
    case RemunerationModel.direto:
      return 'Direct';
  }
}

String labelDataConfidence(DataConfidence val, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return val.wire;
  switch (val) {
    case DataConfidence.alta:
      return 'High';
    case DataConfidence.media:
      return 'Medium';
    case DataConfidence.baixa:
      return 'Low';
  }
}

String labelCompetitionLevel(CompetitionLevel val, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return val.wire;
  switch (val) {
    case CompetitionLevel.baixa:
      return 'Low';
    case CompetitionLevel.media:
      return 'Medium';
    case CompetitionLevel.alta:
      return 'High';
    case CompetitionLevel.desconhecida:
      return 'Unknown';
  }
}

String labelComplianceMarket(String market, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return market;
  if (market == 'Brasil') return 'Brazil';
  if (market == 'França / UE') return 'France / EU';
  if (market == 'França / UE & América do Norte') {
    return 'France / EU & North America';
  }
  return market;
}

String labelProductGradeBadge(ProductQualityGrade? grade, UiLanguage lang) {
  if (grade == null) return lang == UiLanguage.enUS ? 'Grade —' : 'Nota —';
  return lang == UiLanguage.enUS ? 'Grade ${grade.wire}' : 'Nota ${grade.wire}';
}

String labelAttributionStatus(AttributionStatus status, UiLanguage lang) {
  if (lang == UiLanguage.ptBR) return status.wire;
  switch (status) {
    case AttributionStatus.estimativaEmInvestigacao:
      return 'Estimate [Under review]';
    case AttributionStatus.confirmadaMarca:
      return 'Confirmed (Brand)';
    case AttributionStatus.naoAtribuida:
      return 'Unattributed';
  }
}
