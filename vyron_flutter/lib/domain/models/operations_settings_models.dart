import 'package:flutter/foundation.dart';

import 'brand_product_models.dart';
import 'content_channel_finance_models.dart';
import 'vyron_enums.dart';

@immutable
class AgentPolicyLimits {
  const AgentPolicyLimits({
    required this.requireHumanApproval,
    required this.maxActionsPerDay,
    required this.maxDailySpendBRL,
    required this.allowedModules,
  });

  final bool requireHumanApproval;
  final int maxActionsPerDay;
  final double maxDailySpendBRL;
  final List<String> allowedModules;

  Map<String, dynamic> toJson() => {
    'requireHumanApproval': requireHumanApproval,
    'maxActionsPerDay': maxActionsPerDay,
    'maxDailySpendBRL': maxDailySpendBRL,
    'allowedModules': allowedModules,
  };

  factory AgentPolicyLimits.fromJson(Map<String, dynamic> json) =>
      AgentPolicyLimits(
        requireHumanApproval: json['requireHumanApproval'] as bool? ?? true,
        maxActionsPerDay: (json['maxActionsPerDay'] as num).toInt(),
        maxDailySpendBRL: (json['maxDailySpendBRL'] as num).toDouble(),
        allowedModules: List<String>.from(
          json['allowedModules'] as List<dynamic>,
        ),
      );
}

@immutable
class AgentExecutionLog {
  const AgentExecutionLog({
    required this.id,
    required this.timestamp,
    required this.status,
    required this.durationSec,
    required this.summary,
    required this.recordsAffected,
  });

  final String id;
  final String timestamp;
  final AgentExecutionStatus status;
  final double durationSec;
  final String summary;
  final int recordsAffected;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'status': status.wire,
    'durationSec': durationSec,
    'summary': summary,
    'recordsAffected': recordsAffected,
  };

  factory AgentExecutionLog.fromJson(Map<String, dynamic> json) =>
      AgentExecutionLog(
        id: json['id'] as String,
        timestamp: json['timestamp'] as String,
        status: AgentExecutionStatus.fromWire(json['status'] as String?),
        durationSec: (json['durationSec'] as num).toDouble(),
        summary: json['summary'] as String,
        recordsAffected: (json['recordsAffected'] as num).toInt(),
      );
}

@immutable
class AutomationAgent {
  const AutomationAgent({
    required this.id,
    required this.name,
    required this.category,
    required this.autonomyLevel,
    required this.responsibility,
    required this.state,
    required this.brandScope,
    required this.dependencies,
    required this.flowSteps,
    required this.pendingApprovalCount,
    this.pendingApprovalSummary,
    required this.lastRunAt,
    this.lastError,
    required this.limits,
    required this.history,
  });

  final String id;
  final String name;
  final AgentCategory category;
  final int autonomyLevel; // 0..4
  final String responsibility;
  final AgentRunState state;
  final String brandScope;
  final List<String> dependencies;
  final List<String> flowSteps;
  final int pendingApprovalCount;
  final String? pendingApprovalSummary;
  final String lastRunAt;
  final String? lastError;
  final AgentPolicyLimits limits;
  final List<AgentExecutionLog> history;

  AutomationAgent copyWith({
    AgentRunState? state,
    int? pendingApprovalCount,
    String? pendingApprovalSummary,
    bool clearPendingSummary = false,
    String? lastRunAt,
    String? lastError,
    AgentPolicyLimits? limits,
    List<AgentExecutionLog>? history,
  }) {
    return AutomationAgent(
      id: id,
      name: name,
      category: category,
      autonomyLevel: autonomyLevel,
      responsibility: responsibility,
      state: state ?? this.state,
      brandScope: brandScope,
      dependencies: dependencies,
      flowSteps: flowSteps,
      pendingApprovalCount: pendingApprovalCount ?? this.pendingApprovalCount,
      pendingApprovalSummary: clearPendingSummary
          ? null
          : (pendingApprovalSummary ?? this.pendingApprovalSummary),
      lastRunAt: lastRunAt ?? this.lastRunAt,
      lastError: lastError ?? this.lastError,
      limits: limits ?? this.limits,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.wire,
    'autonomyLevel': autonomyLevel,
    'responsibility': responsibility,
    'state': state.wire,
    'brandScope': brandScope,
    'dependencies': dependencies,
    'flowSteps': flowSteps,
    'pendingApprovalCount': pendingApprovalCount,
    if (pendingApprovalSummary != null)
      'pendingApprovalSummary': pendingApprovalSummary,
    'lastRunAt': lastRunAt,
    if (lastError != null) 'lastError': lastError,
    'limits': limits.toJson(),
    'history': history.map((e) => e.toJson()).toList(),
  };

  factory AutomationAgent.fromJson(Map<String, dynamic> json) =>
      AutomationAgent(
        id: json['id'] as String,
        name: json['name'] as String,
        category: AgentCategory.fromWire(json['category'] as String?),
        autonomyLevel: (json['autonomyLevel'] as num).toInt(),
        responsibility: json['responsibility'] as String,
        state: AgentRunState.fromWire(json['state'] as String?),
        brandScope: json['brandScope'] as String,
        dependencies: List<String>.from(json['dependencies'] as List<dynamic>),
        flowSteps: List<String>.from(json['flowSteps'] as List<dynamic>),
        pendingApprovalCount: (json['pendingApprovalCount'] as num).toInt(),
        pendingApprovalSummary: json['pendingApprovalSummary'] as String?,
        lastRunAt: json['lastRunAt'] as String,
        lastError: json['lastError'] as String?,
        limits: AgentPolicyLimits.fromJson(
          json['limits'] as Map<String, dynamic>,
        ),
        history: (json['history'] as List<dynamic>)
            .map((e) => AgentExecutionLog.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class JobRun {
  const JobRun({
    required this.id,
    required this.taskName,
    required this.mode,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    required this.recordsProcessed,
    required this.summary,
    this.error,
  });

  final int id;
  final JobTaskName taskName;
  final JobMode mode;
  final JobRunStatus status;
  final String startedAt;
  final String? finishedAt;
  final int recordsProcessed;
  final String summary;
  final String? error;

  JobRun copyWith({
    JobRunStatus? status,
    String? finishedAt,
    int? recordsProcessed,
    String? summary,
    String? error,
  }) {
    return JobRun(
      id: id,
      taskName: taskName,
      mode: mode,
      status: status ?? this.status,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      recordsProcessed: recordsProcessed ?? this.recordsProcessed,
      summary: summary ?? this.summary,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskName': taskName.wire,
    'mode': mode.wire,
    'status': status.wire,
    'startedAt': startedAt,
    if (finishedAt != null) 'finishedAt': finishedAt,
    'recordsProcessed': recordsProcessed,
    'summary': summary,
    if (error != null) 'error': error,
  };

  factory JobRun.fromJson(Map<String, dynamic> json) => JobRun(
    id: (json['id'] as num).toInt(),
    taskName: JobTaskName.fromWire(json['taskName'] as String?),
    mode: JobMode.fromWire(json['mode'] as String?),
    status: JobRunStatus.fromWire(json['status'] as String?),
    startedAt: json['startedAt'] as String,
    finishedAt: json['finishedAt'] as String?,
    recordsProcessed: (json['recordsProcessed'] as num).toInt(),
    summary: json['summary'] as String,
    error: json['error'] as String?,
  );
}

@immutable
class SystemControlState {
  const SystemControlState({
    required this.state,
    required this.actor,
    required this.reason,
    required this.updatedAt,
    required this.publishingEnabled,
    required this.phaseBPublicAllowed,
  });

  final SystemControlStatus state;
  final String actor;
  final String reason;
  final String updatedAt;
  final bool publishingEnabled;
  final bool phaseBPublicAllowed;

  SystemControlState copyWith({
    SystemControlStatus? state,
    String? actor,
    String? reason,
    String? updatedAt,
    bool? publishingEnabled,
    bool? phaseBPublicAllowed,
  }) {
    return SystemControlState(
      state: state ?? this.state,
      actor: actor ?? this.actor,
      reason: reason ?? this.reason,
      updatedAt: updatedAt ?? this.updatedAt,
      publishingEnabled: publishingEnabled ?? this.publishingEnabled,
      phaseBPublicAllowed: phaseBPublicAllowed ?? this.phaseBPublicAllowed,
    );
  }

  Map<String, dynamic> toJson() => {
    'state': state.wire,
    'actor': actor,
    'reason': reason,
    'updatedAt': updatedAt,
    'publishingEnabled': publishingEnabled,
    'phaseBPublicAllowed': phaseBPublicAllowed,
  };

  factory SystemControlState.fromJson(Map<String, dynamic> json) =>
      SystemControlState(
        state: SystemControlStatus.fromWire(json['state'] as String?),
        actor: json['actor'] as String,
        reason: json['reason'] as String,
        updatedAt: json['updatedAt'] as String,
        publishingEnabled: json['publishingEnabled'] as bool? ?? false,
        phaseBPublicAllowed: json['phaseBPublicAllowed'] as bool? ?? false,
      );
}

@immutable
class RiskRegisterEntry {
  const RiskRegisterEntry({
    required this.id,
    required this.priority,
    required this.title,
    required this.controlSummary,
    required this.status,
  });

  final String id;
  final RiskPriority priority;
  final String title;
  final String controlSummary;
  final RiskStatus status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'priority': priority.wire,
    'title': title,
    'controlSummary': controlSummary,
    'status': status.wire,
  };

  factory RiskRegisterEntry.fromJson(Map<String, dynamic> json) =>
      RiskRegisterEntry(
        id: json['id'] as String,
        priority: RiskPriority.fromWire(json['priority'] as String?),
        title: json['title'] as String,
        controlSummary: json['controlSummary'] as String,
        status: RiskStatus.fromWire(json['status'] as String?),
      );
}

@immutable
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.timestamp,
    this.brandId,
    required this.category,
    required this.action,
    required this.detail,
    this.justification,
    required this.actor,
    required this.severity,
  });

  final String id;
  final String timestamp;
  final String? brandId;
  final ActivityCategory category;
  final String action;
  final String detail;
  final String? justification;
  final String actor;
  final ActivitySeverity severity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    if (brandId != null) 'brandId': brandId,
    'category': category.wire,
    'action': action,
    'detail': detail,
    if (justification != null) 'justification': justification,
    'actor': actor,
    'severity': severity.wire,
  };

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
    id: json['id'] as String,
    timestamp: json['timestamp'] as String,
    brandId: json['brandId'] as String?,
    category: ActivityCategory.fromWire(json['category'] as String?),
    action: json['action'] as String,
    detail: json['detail'] as String,
    justification: json['justification'] as String?,
    actor: json['actor'] as String,
    severity: ActivitySeverity.fromWire(json['severity'] as String?),
  );
}

@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.read,
    required this.targetModule,
    this.targetId,
    this.brandId,
    this.actionRequired,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String timestamp;
  final bool read;
  final NavModule targetModule;
  final String? targetId;
  final String? brandId;
  final bool? actionRequired;

  NotificationItem copyWith({bool? read}) => NotificationItem(
    id: id,
    type: type,
    title: title,
    message: message,
    timestamp: timestamp,
    read: read ?? this.read,
    targetModule: targetModule,
    targetId: targetId,
    brandId: brandId,
    actionRequired: actionRequired,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.wire,
    'title': title,
    'message': message,
    'timestamp': timestamp,
    'read': read,
    'targetModule': targetModule.wire,
    if (targetId != null) 'targetId': targetId,
    if (brandId != null) 'brandId': brandId,
    if (actionRequired != null) 'actionRequired': actionRequired,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        type: NotificationType.fromWire(json['type'] as String?),
        title: json['title'] as String,
        message: json['message'] as String,
        timestamp: json['timestamp'] as String,
        read: json['read'] as bool? ?? false,
        targetModule: NavModule.fromWire(json['targetModule'] as String?),
        targetId: json['targetId'] as String?,
        brandId: json['brandId'] as String?,
        actionRequired: json['actionRequired'] as bool?,
      );
}

@immutable
class IntegrationConfig {
  const IntegrationConfig({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.lastChecked,
    this.note,
  });

  final String id;
  final String name;
  final String category;
  final IntegrationConfigStatus status;
  final String lastChecked;
  final String? note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'status': status.wire,
    'lastChecked': lastChecked,
    if (note != null) 'note': note,
  };

  factory IntegrationConfig.fromJson(Map<String, dynamic> json) =>
      IntegrationConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        status: IntegrationConfigStatus.fromWire(json['status'] as String?),
        lastChecked: json['lastChecked'] as String,
        note: json['note'] as String?,
      );
}

@immutable
class NotificationPrefs {
  const NotificationPrefs({
    required this.financialAlerts,
    required this.commissionsReceived,
    required this.opportunities,
    required this.pendingApprovals,
    required this.automationFailures,
    required this.operationalEvents,
  });

  final bool financialAlerts;
  final bool commissionsReceived;
  final bool opportunities;
  final bool pendingApprovals;
  final bool automationFailures;
  final bool operationalEvents;

  NotificationPrefs copyWith({
    bool? financialAlerts,
    bool? commissionsReceived,
    bool? opportunities,
    bool? pendingApprovals,
    bool? automationFailures,
    bool? operationalEvents,
  }) {
    return NotificationPrefs(
      financialAlerts: financialAlerts ?? this.financialAlerts,
      commissionsReceived: commissionsReceived ?? this.commissionsReceived,
      opportunities: opportunities ?? this.opportunities,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      automationFailures: automationFailures ?? this.automationFailures,
      operationalEvents: operationalEvents ?? this.operationalEvents,
    );
  }

  Map<String, dynamic> toJson() => {
    'financialAlerts': financialAlerts,
    'commissionsReceived': commissionsReceived,
    'opportunities': opportunities,
    'pendingApprovals': pendingApprovals,
    'automationFailures': automationFailures,
    'operationalEvents': operationalEvents,
  };

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        financialAlerts: json['financialAlerts'] as bool? ?? true,
        commissionsReceived: json['commissionsReceived'] as bool? ?? true,
        opportunities: json['opportunities'] as bool? ?? true,
        pendingApprovals: json['pendingApprovals'] as bool? ?? true,
        automationFailures: json['automationFailures'] as bool? ?? true,
        operationalEvents: json['operationalEvents'] as bool? ?? true,
      );
}

@immutable
class OwnerSettings {
  const OwnerSettings({
    required this.ownerName,
    required this.ownerEmail,
    required this.roleLabel,
    required this.theme,
    required this.uiLanguage,
    required this.baseCurrency,
    required this.globalAutonomyEnabled,
    required this.emergencyStopActive,
    required this.maxGlobalDailySpendBRL,
    required this.requireApprovalForPublish,
    required this.requireApprovalForProductStatus,
    required this.defaultAuthValidityHours,
    required this.evidenceFreshnessMaxHours,
    required this.notificationPrefs,
    required this.integrations,
  });

  final String ownerName;
  final String ownerEmail;
  final String roleLabel;
  final VyronThemeMode theme;
  final UiLanguage uiLanguage;
  final CurrencyCode baseCurrency;
  final bool globalAutonomyEnabled;
  final bool emergencyStopActive;
  final double maxGlobalDailySpendBRL;
  final bool requireApprovalForPublish;
  final bool requireApprovalForProductStatus;
  final int defaultAuthValidityHours;
  final int evidenceFreshnessMaxHours;
  final NotificationPrefs notificationPrefs;
  final List<IntegrationConfig> integrations;

  OwnerSettings copyWith({
    String? ownerName,
    String? ownerEmail,
    String? roleLabel,
    VyronThemeMode? theme,
    UiLanguage? uiLanguage,
    CurrencyCode? baseCurrency,
    bool? globalAutonomyEnabled,
    bool? emergencyStopActive,
    double? maxGlobalDailySpendBRL,
    bool? requireApprovalForPublish,
    bool? requireApprovalForProductStatus,
    int? defaultAuthValidityHours,
    int? evidenceFreshnessMaxHours,
    NotificationPrefs? notificationPrefs,
    List<IntegrationConfig>? integrations,
  }) {
    return OwnerSettings(
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      roleLabel: roleLabel ?? this.roleLabel,
      theme: theme ?? this.theme,
      uiLanguage: uiLanguage ?? this.uiLanguage,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      globalAutonomyEnabled:
          globalAutonomyEnabled ?? this.globalAutonomyEnabled,
      emergencyStopActive: emergencyStopActive ?? this.emergencyStopActive,
      maxGlobalDailySpendBRL:
          maxGlobalDailySpendBRL ?? this.maxGlobalDailySpendBRL,
      requireApprovalForPublish:
          requireApprovalForPublish ?? this.requireApprovalForPublish,
      requireApprovalForProductStatus:
          requireApprovalForProductStatus ??
          this.requireApprovalForProductStatus,
      defaultAuthValidityHours:
          defaultAuthValidityHours ?? this.defaultAuthValidityHours,
      evidenceFreshnessMaxHours:
          evidenceFreshnessMaxHours ?? this.evidenceFreshnessMaxHours,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      integrations: integrations ?? this.integrations,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerName': ownerName,
    'ownerEmail': ownerEmail,
    'roleLabel': roleLabel,
    'theme': theme.wire,
    'uiLanguage': uiLanguage.wire,
    'baseCurrency': baseCurrency.wire,
    'globalAutonomyEnabled': globalAutonomyEnabled,
    'emergencyStopActive': emergencyStopActive,
    'maxGlobalDailySpendBRL': maxGlobalDailySpendBRL,
    'requireApprovalForPublish': requireApprovalForPublish,
    'requireApprovalForProductStatus': requireApprovalForProductStatus,
    'defaultAuthValidityHours': defaultAuthValidityHours,
    'evidenceFreshnessMaxHours': evidenceFreshnessMaxHours,
    'notificationPrefs': notificationPrefs.toJson(),
    'integrations': integrations.map((e) => e.toJson()).toList(),
  };

  factory OwnerSettings.fromJson(Map<String, dynamic> json) => OwnerSettings(
    ownerName: OwnerProfile.normalizeOwnerName(json['ownerName'] as String?),
    ownerEmail: (json['ownerEmail'] as String?)?.isNotEmpty == true
        ? json['ownerEmail'] as String
        : OwnerProfile.email,
    roleLabel: json['roleLabel'] as String? ?? OwnerProfile.roleLabel,
    theme: VyronThemeMode.fromWire(json['theme'] as String?),
    uiLanguage: UiLanguage.fromWire(json['uiLanguage'] as String?),
    baseCurrency: CurrencyCode.fromWire(json['baseCurrency'] as String?),
    globalAutonomyEnabled: json['globalAutonomyEnabled'] as bool? ?? false,
    emergencyStopActive: json['emergencyStopActive'] as bool? ?? false,
    maxGlobalDailySpendBRL:
        (json['maxGlobalDailySpendBRL'] as num?)?.toDouble() ?? 0,
    requireApprovalForPublish:
        json['requireApprovalForPublish'] as bool? ?? true,
    requireApprovalForProductStatus:
        json['requireApprovalForProductStatus'] as bool? ?? true,
    defaultAuthValidityHours:
        (json['defaultAuthValidityHours'] as num?)?.toInt() ?? 24,
    evidenceFreshnessMaxHours:
        (json['evidenceFreshnessMaxHours'] as num?)?.toInt() ?? 48,
    notificationPrefs: NotificationPrefs.fromJson(
      json['notificationPrefs'] as Map<String, dynamic>,
    ),
    integrations: (json['integrations'] as List<dynamic>)
        .map((e) => IntegrationConfig.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

@immutable
class VyronState {
  const VyronState({
    required this.brands,
    required this.products,
    required this.contents,
    required this.channels,
    required this.financeEntries,
    required this.automations,
    required this.jobRuns,
    required this.systemControl,
    required this.risks,
    required this.activities,
    required this.notifications,
    required this.settings,
  });

  final List<Brand> brands;
  final List<Product> products;
  final List<ContentItem> contents;
  final List<Channel> channels;
  final List<FinanceEntry> financeEntries;
  final List<AutomationAgent> automations;
  final List<JobRun> jobRuns;
  final SystemControlState systemControl;
  final List<RiskRegisterEntry> risks;
  final List<ActivityEvent> activities;
  final List<NotificationItem> notifications;
  final OwnerSettings settings;

  VyronState copyWith({
    List<Brand>? brands,
    List<Product>? products,
    List<ContentItem>? contents,
    List<Channel>? channels,
    List<FinanceEntry>? financeEntries,
    List<AutomationAgent>? automations,
    List<JobRun>? jobRuns,
    SystemControlState? systemControl,
    List<RiskRegisterEntry>? risks,
    List<ActivityEvent>? activities,
    List<NotificationItem>? notifications,
    OwnerSettings? settings,
  }) {
    return VyronState(
      brands: brands ?? this.brands,
      products: products ?? this.products,
      contents: contents ?? this.contents,
      channels: channels ?? this.channels,
      financeEntries: financeEntries ?? this.financeEntries,
      automations: automations ?? this.automations,
      jobRuns: jobRuns ?? this.jobRuns,
      systemControl: systemControl ?? this.systemControl,
      risks: risks ?? this.risks,
      activities: activities ?? this.activities,
      notifications: notifications ?? this.notifications,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
    'brands': brands.map((e) => e.toJson()).toList(),
    'products': products.map((e) => e.toJson()).toList(),
    'contents': contents.map((e) => e.toJson()).toList(),
    'channels': channels.map((e) => e.toJson()).toList(),
    'financeEntries': financeEntries.map((e) => e.toJson()).toList(),
    'automations': automations.map((e) => e.toJson()).toList(),
    'jobRuns': jobRuns.map((e) => e.toJson()).toList(),
    'systemControl': systemControl.toJson(),
    'risks': risks.map((e) => e.toJson()).toList(),
    'activities': activities.map((e) => e.toJson()).toList(),
    'notifications': notifications.map((e) => e.toJson()).toList(),
    'settings': settings.toJson(),
  };

  factory VyronState.fromJson(Map<String, dynamic> json) => VyronState(
    brands: (json['brands'] as List<dynamic>)
        .map((e) => Brand.fromJson(e as Map<String, dynamic>))
        .toList(),
    products: (json['products'] as List<dynamic>)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList(),
    contents: (json['contents'] as List<dynamic>)
        .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    channels: (json['channels'] as List<dynamic>)
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList(),
    financeEntries: (json['financeEntries'] as List<dynamic>)
        .map((e) => FinanceEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    automations: (json['automations'] as List<dynamic>)
        .map((e) => AutomationAgent.fromJson(e as Map<String, dynamic>))
        .toList(),
    jobRuns: (json['jobRuns'] as List<dynamic>)
        .map((e) => JobRun.fromJson(e as Map<String, dynamic>))
        .toList(),
    systemControl: SystemControlState.fromJson(
      json['systemControl'] as Map<String, dynamic>,
    ),
    risks: (json['risks'] as List<dynamic>)
        .map((e) => RiskRegisterEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    activities: (json['activities'] as List<dynamic>)
        .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
    notifications: (json['notifications'] as List<dynamic>)
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    settings: OwnerSettings.fromJson(json['settings'] as Map<String, dynamic>),
  );
}
