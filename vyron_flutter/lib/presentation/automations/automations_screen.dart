import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/formatters.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/routing/vyron_router.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/models/operations_settings_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';
import '../shell/system_control_modal.dart';

class AutomationsScreen extends ConsumerStatefulWidget {
  const AutomationsScreen({super.key, this.automationId});

  final String? automationId;

  @override
  ConsumerState<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends ConsumerState<AutomationsScreen> {
  String _tab = 'agents';
  AgentCategory? _catFilter;
  String? _runnerNotice;
  bool _runnerNoticeError = false;

  String _taskNameLabel(JobTaskName taskName, UiLanguage lang) {
    switch (taskName) {
      case JobTaskName.pipelineRun:
        return translate(lang, 'automations.jobs.taskPipelineRun');
      case JobTaskName.productsScore:
        return translate(lang, 'automations.jobs.taskProductsScore');
      case JobTaskName.productsImport:
        return translate(lang, 'automations.jobs.taskProductsImport');
      case JobTaskName.jobsReconcile:
        return translate(lang, 'automations.jobs.taskJobsReconcile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final notifier = ref.read(vyronStateProvider.notifier);
    final domain = appState.domain;
    final lang = domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHalted =
        domain.systemControl.state == SystemControlStatus.halted ||
        domain.settings.emergencyStopActive;

    final effectiveId = widget.automationId ?? appState.selectedAutomationId;
    if (effectiveId != null && effectiveId.isNotEmpty) {
      AutomationAgent? found;
      for (final a in domain.automations) {
        if (a.id == effectiveId) {
          found = a;
          break;
        }
      }
      if (found == null) {
        return VyronEmptyState(
          title: translate(lang, 'automations.detail.notFoundTitle'),
          description: translate(lang, 'automations.detail.notFoundDesc'),
          actionLabel: translate(lang, 'automations.detail.back'),
          onAction: () => navigateToVyronModule(
            ref,
            NavModule.automations,
            automationId: null,
            setAutomationId: true,
          ),
        );
      }

      return _AutomationDetailView(
        agent: localizeAgent(found, lang),
        language: lang,
        isHalted: isHalted,
        onBack: () => navigateToVyronModule(
          ref,
          NavModule.automations,
          automationId: null,
          setAutomationId: true,
        ),
      );
    }

    final localizedAgents = domain.automations
        .map((a) => localizeAgent(a, lang))
        .toList();
    final filteredAgents = _catFilter == null
        ? localizedAgents
        : localizedAgents.where((a) => a.category == _catFilter).toList();

    final activeAgentsCount = domain.automations
        .where(
          (a) =>
              a.state == AgentRunState.running || a.state == AgentRunState.idle,
        )
        .length;
    final pendingApprovals = domain.automations.fold<int>(
      0,
      (acc, a) => acc + a.pendingApprovalCount,
    );
    final blockingJobs = domain.jobRuns
        .where(
          (j) =>
              j.status == JobRunStatus.running ||
              j.status == JobRunStatus.unknown,
        )
        .toList();
    final localizedJobRuns = domain.jobRuns
        .map((j) => localizeJobRun(j, lang))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: translate(lang, 'automations.title'),
          subtitle: translate(lang, 'automations.subtitle'),
          actions: [
            ElevatedButton.icon(
              key: const Key('automations-system-control-btn'),
              onPressed: () {
                showSystemControlModal(
                  context: context,
                  mode: isHalted
                      ? SystemControlModalMode.resume
                      : SystemControlModalMode.halt,
                  language: lang,
                  initialActor: domain.settings.ownerName,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isHalted
                    ? VyronColors.electricCobalt
                    : (isDark
                          ? VyronColors.crimson
                          : VyronColors.crimsonLightButton),
                foregroundColor: Colors.white,
              ),
              icon: Icon(
                isHalted
                    ? Icons.play_arrow_rounded
                    : Icons.stop_circle_outlined,
                size: 16,
              ),
              label: Text(
                translate(
                  lang,
                  isHalted
                      ? 'automations.haltedResume'
                      : 'automations.stopAllImmediate',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 4 KPIs
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 960
                ? 4
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            const spacing = 12.0;
            final cardWidth =
                (constraints.maxWidth - (cols - 1) * spacing) / cols;
            final cards = [
              VyronMetricBlock(
                key: const Key('automations-kpi-controls'),
                label: translate(lang, 'automations.kpi.controls'),
                value: labelSystemControlState(
                  domain.systemControl.state,
                  lang,
                ),
                helper: translate(lang, 'automations.kpi.actor', {
                  'actor': localizeActor(domain.systemControl.actor, lang),
                }),
                tone: isHalted
                    ? VyronMetricTone.crimson
                    : VyronMetricTone.emerald,
              ),
              VyronMetricBlock(
                label: translate(lang, 'automations.kpi.activeAgents'),
                value: '$activeAgentsCount',
                helper: translate(lang, 'automations.kpi.activeAgentsHelper', {
                  'total': domain.automations.length,
                }),
                tone: VyronMetricTone.neutral,
              ),
              VyronMetricBlock(
                label: translate(lang, 'automations.kpi.approvals'),
                value: '$pendingApprovals',
                helper: translate(lang, 'automations.kpi.approvalsHelper'),
                tone: VyronMetricTone.amber,
              ),
              VyronMetricBlock(
                key: const Key('automations-kpi-pending-jobs'),
                label: translate(lang, 'automations.kpi.pendingJobs'),
                value: '${blockingJobs.length}',
                helper: translate(
                  lang,
                  blockingJobs.isNotEmpty
                      ? 'automations.kpi.pendingJobsBlocked'
                      : 'automations.kpi.pendingJobsOk',
                ),
                tone: blockingJobs.isNotEmpty
                    ? VyronMetricTone.amber
                    : VyronMetricTone.emerald,
              ),
            ];
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final c in cards) SizedBox(width: cardWidth, child: c),
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Tab switcher + Optional category filter
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            VyronSegmentedControl<String>(
              options: [
                VyronSegmentOption(
                  value: 'agents',
                  label: translate(lang, 'automations.tabAgents', {
                    'count': domain.automations.length,
                  }),
                ),
                VyronSegmentOption(
                  value: 'jobs',
                  label: translate(lang, 'automations.tabJobs', {
                    'count': domain.jobRuns.length,
                  }),
                ),
              ],
              value: _tab,
              onChanged: (v) => setState(() => _tab = v),
            ),
            if (_tab == 'agents')
              VyronSegmentedControl<AgentCategory?>(
                options: [
                  VyronSegmentOption(
                    value: null,
                    label: translate(lang, 'automations.allCategories'),
                  ),
                  for (final c in AgentCategory.values)
                    VyronSegmentOption(
                      value: c,
                      label: labelAgentCategory(c, lang),
                    ),
                ],
                value: _catFilter,
                onChanged: (c) => setState(() => _catFilter = c),
              ),
          ],
        ),

        if (_runnerNotice != null && _runnerNotice!.isNotEmpty) ...[
          const SizedBox(height: 14),
          VyronFeedbackBanner(
            key: const Key('automations-runner-notice'),
            message: _runnerNotice!,
            tone: _runnerNoticeError
                ? VyronMetricTone.crimson
                : VyronMetricTone.emerald,
            dismissLabel: translate(lang, 'common.close'),
            onDismiss: () => setState(() => _runnerNotice = null),
          ),
        ],
        const SizedBox(height: 16),

        if (_tab == 'agents')
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 780 ? 2 : 1;
              const spacing = 14.0;
              final cardWidth =
                  (constraints.maxWidth - (cols - 1) * spacing) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final agent in filteredAgents)
                    SizedBox(
                      width: cardWidth,
                      child: VyronSurfacePanel(
                        key: Key('agent-card-${agent.id}'),
                        padding: VyronPanelPadding.md,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        agent.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${labelAgentCategory(agent.category, lang)} · ${translate(lang, 'automations.card.meta', {'level': agent.autonomyLevel, 'max': agent.limits.maxActionsPerDay})}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: palette.textMuted,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                VyronStatusLabel(
                                  status: labelAgentState(agent.state, lang),
                                  statusKey: agent.state.wire,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              agent.responsibility,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.textMuted),
                            ),
                            if (agent.lastError != null &&
                                agent.lastError!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: VyronColors.crimson.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: VyronColors.crimson.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  translate(
                                    lang,
                                    'automations.card.errorPrefix',
                                    {'error': agent.lastError!},
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? VyronColors.crimsonDarkText
                                            : VyronColors.crimsonLightText,
                                      ),
                                ),
                              ),
                            ],
                            if (agent.pendingApprovalCount > 0 &&
                                agent.pendingApprovalSummary != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: VyronColors.amber.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: VyronColors.amber.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  agent.pendingApprovalSummary!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isDark
                                            ? VyronColors.amberDarkText
                                            : VyronColors.amberLightText,
                                      ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.only(top: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: palette.panelBorder),
                                ),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  VyronToggleSwitch(
                                    key: Key('agent-toggle-${agent.id}'),
                                    value: agent.state == AgentRunState.running,
                                    compact: true,
                                    enabled: !isHalted,
                                    label: translate(
                                      lang,
                                      agent.state == AgentRunState.running
                                          ? 'automations.card.pause'
                                          : 'automations.card.runDemo',
                                    ),
                                    onChanged: isHalted
                                        ? null
                                        : (_) =>
                                              notifier.toggleAgentRun(agent.id),
                                  ),
                                  TextButton(
                                    key: Key('agent-detail-${agent.id}'),
                                    onPressed: () => navigateToVyronModule(
                                      ref,
                                      NavModule.automations,
                                      automationId: agent.id,
                                      setAutomationId: true,
                                    ),
                                    child: Text(
                                      translate(
                                        lang,
                                        'automations.card.detailsLimits',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        else ...[
          // Jobs & System Controls Tab
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              final sysControlCard = VyronSurfacePanel(
                padding: VyronPanelPadding.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            translate(
                              lang,
                              'automations.jobs.controlStateTitle',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        VyronStatusLabel(
                          status: labelSystemControlState(
                            domain.systemControl.state,
                            lang,
                          ),
                          statusKey: domain.systemControl.state.wire,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _KeyValueLine(
                      label: translate(lang, 'automations.jobs.lastActor'),
                      value: localizeActor(domain.systemControl.actor, lang),
                    ),
                    const SizedBox(height: 6),
                    _KeyValueLine(
                      label: translate(lang, 'automations.jobs.updatedAt'),
                      value: formatDateTimeForLang(
                        domain.systemControl.updatedAt,
                        lang,
                      ),
                      monoValue: true,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? VyronColors.obsidianBlack.withValues(alpha: 0.65)
                            : palette.surfaceAlt.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.panelBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(lang, 'automations.jobs.reason'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: palette.textMuted,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizeSystemControlReason(
                              domain.systemControl.reason,
                              lang,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    if (blockingJobs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: VyronColors.amber.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: VyronColors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translate(
                                lang,
                                'automations.jobs.resumeLockTitle',
                              ),
                              style: TextStyle(
                                fontFamily: VyronTypography.sans,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? VyronColors.amberDarkText
                                    : VyronColors.amberLightText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              canResumeSystemControl(
                                    domain.jobRuns,
                                    language: lang,
                                  ).reason ??
                                  '',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              key: const Key('jobs-inline-reconcile-btn'),
                              onPressed: () {
                                final count = notifier.reconcileJobsDemo();
                                setState(() {
                                  _runnerNoticeError = false;
                                  _runnerNotice = translate(
                                    lang,
                                    count > 0
                                        ? 'automations.feedback.reconciled'
                                        : 'automations.feedback.reconciledNone',
                                    {'count': count},
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VyronColors.amber,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 34),
                              ),
                              child: Text(
                                translate(
                                  lang,
                                  'automations.jobs.reconcileBtn',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        showSystemControlModal(
                          context: context,
                          mode: isHalted
                              ? SystemControlModalMode.resume
                              : SystemControlModalMode.halt,
                          language: lang,
                          initialActor: domain.settings.ownerName,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHalted
                            ? VyronColors.electricCobalt
                            : (isDark
                                  ? VyronColors.crimson
                                  : VyronColors.crimsonLightButton),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        translate(
                          lang,
                          isHalted
                              ? 'automations.jobs.cliResume'
                              : 'automations.jobs.cliHalt',
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final runnerCard = VyronSurfacePanel(
                padding: VyronPanelPadding.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VyronSectionTitle(
                      title: translate(lang, 'automations.jobs.runnerTitle'),
                      subtitle: translate(lang, 'automations.jobs.runnerDesc'),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, cmdCons) {
                        final cols = cmdCons.maxWidth >= 460 ? 2 : 1;
                        const spacing = 10.0;
                        final btnWidth =
                            (cmdCons.maxWidth - (cols - 1) * spacing) / cols;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            SizedBox(
                              width: btnWidth,
                              child: _RunnerCommandTile(
                                key: const Key('job-cmd-dry-run'),
                                title: translate(
                                  lang,
                                  'automations.jobs.cmdDryRunTitle',
                                ),
                                subtitle: translate(
                                  lang,
                                  'automations.jobs.cmdDryRunDesc',
                                ),
                                onTap: () {
                                  final res = notifier.runPipelineDemo(
                                    JobMode.dryRun,
                                  );
                                  setState(() {
                                    _runnerNoticeError = !res.ok;
                                    _runnerNotice = res.message;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: btnWidth,
                              child: _RunnerCommandTile(
                                key: const Key('job-cmd-commit'),
                                title: translate(
                                  lang,
                                  'automations.jobs.cmdCommitTitle',
                                ),
                                subtitle: translate(
                                  lang,
                                  'automations.jobs.cmdCommitDesc',
                                ),
                                dangerBorder: isHalted,
                                onTap: () {
                                  final res = notifier.runPipelineDemo(
                                    JobMode.commit,
                                  );
                                  setState(() {
                                    _runnerNoticeError = !res.ok;
                                    _runnerNotice = res.message;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: btnWidth,
                              child: _RunnerCommandTile(
                                key: const Key('job-cmd-score'),
                                title: translate(
                                  lang,
                                  'automations.jobs.cmdScoreTitle',
                                ),
                                subtitle: translate(
                                  lang,
                                  'automations.jobs.cmdScoreDesc',
                                ),
                                dangerBorder: isHalted,
                                onTap: () {
                                  final res = notifier.runPipelineDemo(
                                    JobMode.commit,
                                    taskName: JobTaskName.productsScore,
                                  );
                                  setState(() {
                                    _runnerNoticeError = !res.ok;
                                    _runnerNotice = res.message;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: btnWidth,
                              child: _RunnerCommandTile(
                                key: const Key('job-cmd-reconcile'),
                                title: translate(
                                  lang,
                                  'automations.jobs.cmdReconcileTitle',
                                ),
                                subtitle: translate(
                                  lang,
                                  'automations.jobs.cmdReconcileDesc',
                                ),
                                amberBorder: blockingJobs.isNotEmpty,
                                onTap: () {
                                  final count = notifier.reconcileJobsDemo();
                                  setState(() {
                                    _runnerNoticeError = false;
                                    _runnerNotice = translate(
                                      lang,
                                      count > 0
                                          ? 'automations.feedback.reconciled'
                                          : 'automations.feedback.reconciledNone',
                                      {'count': count},
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: sysControlCard),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: runnerCard),
                  ],
                );
              }
              return Column(
                children: [
                  sysControlCard,
                  const SizedBox(height: 14),
                  runnerCard,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Job Runs Ledger
          VyronSurfacePanel(
            padding: VyronPanelPadding.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  translate(lang, 'automations.jobs.ledgerTitle', {
                    'count': domain.jobRuns.length,
                  }),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children: [
                          for (final job in localizedJobRuns)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: palette.surfaceAlt.withValues(
                                  alpha: 0.25,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: palette.panelBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '#${job.id} · ${_taskNameLabel(job.taskName, lang)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontSize: 13),
                                      ),
                                      VyronStatusLabel(
                                        status: labelJobStatus(
                                          job.status,
                                          lang,
                                        ),
                                        statusKey: job.status.wire,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${labelJobMode(job.mode, lang)} · ${formatDateTimeForLang(job.startedAt, lang)} · ${job.recordsProcessed}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: palette.textMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    job.summary,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  if (job.error != null &&
                                      job.error!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      job.error!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? VyronColors.crimsonDarkText
                                                : VyronColors.crimsonLightText,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: math.max(constraints.maxWidth - 4, 780),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: palette.panelBorder,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      translate(lang, 'automations.jobs.colId'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(
                                        lang,
                                        'automations.jobs.colTask',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(
                                        lang,
                                        'automations.jobs.colMode',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(lang, 'common.status'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      translate(
                                        lang,
                                        'automations.jobs.colStarted',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      translate(
                                        lang,
                                        'automations.jobs.colRecords',
                                      ),
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      translate(
                                        lang,
                                        'automations.jobs.colSummary',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: palette.textMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final job in localizedJobRuns)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: palette.panelBorder.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      child: Text(
                                        '#${job.id}',
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 12,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _taskNameLabel(job.taskName, lang),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: palette.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: VyronToneBadge(
                                          label: labelJobMode(job.mode, lang),
                                          tone: job.mode == JobMode.commit
                                              ? VyronMetricTone.cobalt
                                              : VyronMetricTone.neutral,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: VyronStatusLabel(
                                        status: labelJobStatus(
                                          job.status,
                                          lang,
                                        ),
                                        statusKey: job.status.wire,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formatDateTimeForLang(
                                          job.startedAt,
                                          lang,
                                        ),
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 11,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 72,
                                      child: Text(
                                        '${job.recordsProcessed}',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontFamily: VyronTypography.mono,
                                          fontSize: 12,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job.summary,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: palette.textMuted,
                                                ),
                                          ),
                                          if (job.error != null &&
                                              job.error!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              job.error!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? VyronColors
                                                              .crimsonDarkText
                                                        : VyronColors
                                                              .crimsonLightText,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyValueLine extends StatelessWidget {
  const _KeyValueLine({
    required this.label,
    required this.value,
    this.monoValue = false,
  });

  final String label;
  final String value;
  final bool monoValue;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: palette.textMuted),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: monoValue
                  ? VyronTypography.mono
                  : VyronTypography.sans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RunnerCommandTile extends StatelessWidget {
  const _RunnerCommandTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dangerBorder = false,
    this.amberBorder = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dangerBorder;
  final bool amberBorder;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final borderColor = dangerBorder
        ? VyronColors.crimson.withValues(alpha: 0.45)
        : amberBorder
        ? VyronColors.amber.withValues(alpha: 0.45)
        : palette.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surfaceAlt.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: palette.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutomationDetailView extends ConsumerStatefulWidget {
  const _AutomationDetailView({
    required this.agent,
    required this.language,
    required this.isHalted,
    required this.onBack,
  });

  final AutomationAgent agent;
  final UiLanguage language;
  final bool isHalted;
  final VoidCallback onBack;

  @override
  ConsumerState<_AutomationDetailView> createState() =>
      _AutomationDetailViewState();
}

class _AutomationDetailViewState extends ConsumerState<_AutomationDetailView> {
  late final TextEditingController _maxActionsController;
  late final TextEditingController _maxSpendController;

  @override
  void initState() {
    super.initState();
    _maxActionsController = TextEditingController(
      text: '${widget.agent.limits.maxActionsPerDay}',
    );
    _maxSpendController = TextEditingController(
      text: '${widget.agent.limits.maxDailySpendBRL.round()}',
    );
  }

  @override
  void didUpdateWidget(covariant _AutomationDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agent.id != widget.agent.id) {
      _maxActionsController.text = '${widget.agent.limits.maxActionsPerDay}';
      _maxSpendController.text =
          '${widget.agent.limits.maxDailySpendBRL.round()}';
    }
  }

  @override
  void dispose() {
    _maxActionsController.dispose();
    _maxSpendController.dispose();
    super.dispose();
  }

  String _moduleLabel(String mod, UiLanguage lang) {
    switch (mod) {
      case 'brands':
        return translate(lang, 'nav.brands');
      case 'products':
        return translate(lang, 'nav.products');
      case 'content':
        return translate(lang, 'nav.content');
      case 'channels':
        return translate(lang, 'nav.channels');
      case 'analytics':
        return translate(lang, 'nav.analytics');
      case 'finance':
        return translate(lang, 'nav.finance');
      case 'automations':
        return translate(lang, 'nav.automations');
      default:
        return mod;
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final lang = widget.language;
    final notifier = ref.read(vyronStateProvider.notifier);
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('automation-back-btn'),
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(translate(lang, 'automations.detail.back')),
          ),
        ),
        const SizedBox(height: 8),
        VyronPageHeader(
          title: agent.name,
          subtitle: translate(lang, 'automations.detail.subtitle', {
            'category': labelAgentCategory(agent.category, lang),
            'level': agent.autonomyLevel,
            'levelLabel': labelAutonomyLevel(agent.autonomyLevel, lang),
            'scope': agent.brandScope == 'all'
                ? translate(lang, 'automations.detail.allBrands')
                : agent.brandScope,
          }),
          actions: [
            if (agent.pendingApprovalCount > 0)
              ElevatedButton(
                key: const Key('automation-approve-btn'),
                onPressed: () => notifier.approveAgentPending(agent.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VyronColors.amber,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  translate(lang, 'automations.detail.approveQueue', {
                    'count': agent.pendingApprovalCount,
                  }),
                ),
              ),
            OutlinedButton(
              key: const Key('automation-toggle-btn'),
              onPressed: widget.isHalted
                  ? null
                  : () => notifier.toggleAgentRun(agent.id),
              child: Text(
                translate(
                  lang,
                  agent.state == AgentRunState.running
                      ? 'automations.detail.pauseDemo'
                      : 'automations.detail.startDemo',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (agent.lastError != null && agent.lastError!.isNotEmpty) ...[
          VyronSurfacePanel(
            borderColor: VyronColors.crimson.withValues(alpha: 0.45),
            backgroundColor: VyronColors.crimson.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translate(lang, 'automations.detail.errorTitle'),
                  style: TextStyle(
                    fontFamily: VyronTypography.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? VyronColors.crimsonDarkText
                        : VyronColors.crimsonLightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  agent.lastError!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (agent.pendingApprovalCount > 0 &&
            agent.pendingApprovalSummary != null) ...[
          VyronSurfacePanel(
            borderColor: VyronColors.amber.withValues(alpha: 0.45),
            backgroundColor: VyronColors.amber.withValues(alpha: 0.1),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translate(lang, 'automations.detail.pendingTitle'),
                        style: TextStyle(
                          fontFamily: VyronTypography.sans,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? VyronColors.amberDarkText
                              : VyronColors.amberLightText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        agent.pendingApprovalSummary!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => notifier.approveAgentPending(agent.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VyronColors.amber,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    translate(lang, 'automations.detail.authorizeActions'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 880;
            final flowCard = VyronSurfacePanel(
              padding: VyronPanelPadding.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          translate(lang, 'automations.detail.flowTitle'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      VyronToneBadge(
                        label: translate(
                          lang,
                          'automations.detail.levelBadge',
                          {'level': agent.autonomyLevel},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    agent.responsibility,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.textMuted),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    translate(lang, 'automations.detail.dependencies'),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: palette.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final dep in agent.dependencies)
                        VyronToneBadge(label: dep),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (var idx = 0; idx < agent.flowSteps.length; idx++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.panelBorder),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '0${idx + 1}',
                            style: TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              agent.flowSteps[idx],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );

            final policyCard = VyronSurfacePanel(
              padding: VyronPanelPadding.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    translate(lang, 'automations.detail.policiesTitle'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  VyronToggleSwitch(
                    key: const Key('automation-require-approval-toggle'),
                    value: agent.limits.requireHumanApproval,
                    label: translate(
                      lang,
                      'automations.detail.requireApproval',
                    ),
                    onChanged: (v) {
                      notifier.updateAgentLimits(
                        agent.id,
                        AgentPolicyLimits(
                          requireHumanApproval: v,
                          maxActionsPerDay: agent.limits.maxActionsPerDay,
                          maxDailySpendBRL: agent.limits.maxDailySpendBRL,
                          allowedModules: agent.limits.allowedModules,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translate(lang, 'automations.detail.maxActions'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: palette.textMuted,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              key: const Key('automation-limit-actions'),
                              controller: _maxActionsController,
                              keyboardType: TextInputType.number,
                              onChanged: (raw) {
                                final val = int.tryParse(raw.trim());
                                if (val != null) {
                                  notifier.updateAgentLimits(
                                    agent.id,
                                    AgentPolicyLimits(
                                      requireHumanApproval:
                                          agent.limits.requireHumanApproval,
                                      maxActionsPerDay: math.max(1, val),
                                      maxDailySpendBRL:
                                          agent.limits.maxDailySpendBRL,
                                      allowedModules:
                                          agent.limits.allowedModules,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translate(lang, 'automations.detail.maxSpend'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: palette.textMuted,
                                    fontSize: 11,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              key: const Key('automation-limit-spend'),
                              controller: _maxSpendController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (raw) {
                                final val = double.tryParse(
                                  raw.trim().replaceAll(',', '.'),
                                );
                                if (val != null) {
                                  notifier.updateAgentLimits(
                                    agent.id,
                                    AgentPolicyLimits(
                                      requireHumanApproval:
                                          agent.limits.requireHumanApproval,
                                      maxActionsPerDay:
                                          agent.limits.maxActionsPerDay,
                                      maxDailySpendBRL: math.max(0.0, val),
                                      allowedModules:
                                          agent.limits.allowedModules,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    translate(lang, 'automations.detail.allowedModules'),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: palette.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final mod in agent.limits.allowedModules)
                        VyronToneBadge(label: _moduleLabel(mod, lang)),
                    ],
                  ),
                ],
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: flowCard),
                  const SizedBox(width: 14),
                  Expanded(child: policyCard),
                ],
              );
            }
            return Column(
              children: [flowCard, const SizedBox(height: 14), policyCard],
            );
          },
        ),
        const SizedBox(height: 16),
        VyronSurfacePanel(
          padding: VyronPanelPadding.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                translate(lang, 'automations.detail.historyTitle'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final log in agent.history)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: palette.panelBorder),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.summary,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatDateTimeForLang(log.timestamp, lang)} · ${log.durationSec.toStringAsFixed(0)}s · ${log.recordsAffected} ${translate(lang, 'automations.detail.colRecords').toLowerCase()}',
                            style: TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 11,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      VyronStatusLabel(
                        status: labelAgentExecutionStatus(log.status, lang),
                        statusKey: log.status.wire,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
