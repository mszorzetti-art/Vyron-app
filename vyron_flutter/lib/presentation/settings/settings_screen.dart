import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_access_notifier.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/domain_labels.dart';
import '../../core/i18n/seed_translations.dart';
import '../../core/i18n/translate.dart';
import '../../core/security/vyron_access_rules.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/models/operations_settings_models.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _ownerEmailCtrl = TextEditingController();
  final TextEditingController _authHoursCtrl = TextEditingController();
  final TextEditingController _evHoursCtrl = TextEditingController();
  final TextEditingController _maxSpendCtrl = TextEditingController();
  final TextEditingController _currentPwdCtrl = TextEditingController();
  final TextEditingController _newPwdCtrl = TextEditingController();

  final FocusNode _ownerNameFocus = FocusNode();
  final FocusNode _ownerEmailFocus = FocusNode();
  final FocusNode _authHoursFocus = FocusNode();
  final FocusNode _evHoursFocus = FocusNode();
  final FocusNode _maxSpendFocus = FocusNode();

  String _haltNotice = '';
  bool _haltNoticeError = false;
  String _reconcileNotice = '';
  String _pwdMsg = '';
  bool _pwdMsgError = false;

  @override
  void initState() {
    super.initState();
    _syncControllers(ref.read(vyronStateProvider).domain.settings);
  }

  void _syncControllers(OwnerSettings settings) {
    if (!_ownerNameFocus.hasFocus &&
        _ownerNameCtrl.text != settings.ownerName) {
      _ownerNameCtrl.text = settings.ownerName;
    }
    if (!_ownerEmailFocus.hasFocus &&
        _ownerEmailCtrl.text != settings.ownerEmail) {
      _ownerEmailCtrl.text = settings.ownerEmail;
    }
    final authText = '${settings.defaultAuthValidityHours}';
    if (!_authHoursFocus.hasFocus && _authHoursCtrl.text != authText) {
      _authHoursCtrl.text = authText;
    }
    final evText = '${settings.evidenceFreshnessMaxHours}';
    if (!_evHoursFocus.hasFocus && _evHoursCtrl.text != evText) {
      _evHoursCtrl.text = evText;
    }
    final spendText = '${settings.maxGlobalDailySpendBRL.round()}';
    if (!_maxSpendFocus.hasFocus && _maxSpendCtrl.text != spendText) {
      _maxSpendCtrl.text = spendText;
    }
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _authHoursCtrl.dispose();
    _evHoursCtrl.dispose();
    _maxSpendCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _ownerNameFocus.dispose();
    _ownerEmailFocus.dispose();
    _authHoursFocus.dispose();
    _evHoursFocus.dispose();
    _maxSpendFocus.dispose();
    super.dispose();
  }

  String _idleTimeoutLabel(int minutes, UiLanguage lang) {
    return translate(lang, 'access.timeout.$minutes');
  }

  Future<void> _handleUpdatePassword(UiLanguage lang) async {
    final accessNotifier = ref.read(vyronAccessProvider.notifier);
    final res = await accessNotifier.updateAccessPassword(
      _currentPwdCtrl.text,
      _newPwdCtrl.text,
    );
    if (!mounted) return;
    if (res.ok) {
      _currentPwdCtrl.clear();
      _newPwdCtrl.clear();
      setState(() {
        _pwdMsgError = false;
        _pwdMsg = translate(lang, 'settings.access.pwdUpdated');
      });
      return;
    }

    final errKey = switch (res.errorCode) {
      AccessErrorCode.currentWrong => 'access.error.currentWrong',
      AccessErrorCode.newTooShort => 'access.error.newTooShort',
      _ => 'settings.access.pwdErrorFallback',
    };
    setState(() {
      _pwdMsgError = true;
      _pwdMsg = translate(lang, errKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final notifier = ref.read(vyronStateProvider.notifier);
    final accessState = ref.watch(vyronAccessProvider);
    final accessNotifier = ref.read(vyronAccessProvider.notifier);
    final domain = appState.domain;
    final settings = domain.settings;
    final lang = settings.uiLanguage;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHalted = domain.systemControl.state == SystemControlStatus.halted ||
        settings.emergencyStopActive;

    _syncControllers(settings);

    final localizedRisks =
        domain.risks.map((r) => localizeRisk(r, lang)).toList();
    final localizedIntegrations =
        settings.integrations.map((i) => localizeIntegration(i, lang)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VyronPageHeader(
          title: translate(lang, 'settings.title'),
          subtitle: translate(lang, 'settings.subtitle'),
          actions: [
            OutlinedButton.icon(
              key: const Key('settings-reset-demo-btn'),
              onPressed: () async {
                await notifier.resetDemoData();
                if (!mounted) return;
                _syncControllers(
                  ref.read(vyronStateProvider).domain.settings,
                );
                setState(() {
                  _haltNotice = '';
                  _reconcileNotice = '';
                });
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(translate(lang, 'settings.resetDemo')),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Row 1: Profile & Policies
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;

            final profileCard = VyronSurfacePanel(
              padding: VyronPanelPadding.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    translate(lang, 'settings.profileTitle'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, fieldCons) {
                      final twoCols = fieldCons.maxWidth >= 420;
                      final nameField = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(lang, 'settings.ownerNameLabel'),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: palette.textMuted,
                                      fontSize: 11,
                                    ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key('settings-owner-name'),
                            controller: _ownerNameCtrl,
                            focusNode: _ownerNameFocus,
                            onChanged: (v) => notifier.updateSettings(
                              OwnerSettingsPatch(ownerName: v),
                            ),
                          ),
                        ],
                      );
                      final emailField = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(lang, 'settings.ownerEmailLabel'),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: palette.textMuted,
                                      fontSize: 11,
                                    ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key('settings-owner-email'),
                            controller: _ownerEmailCtrl,
                            focusNode: _ownerEmailFocus,
                            onChanged: (v) => notifier.updateSettings(
                              OwnerSettingsPatch(ownerEmail: v),
                            ),
                          ),
                        ],
                      );
                      if (twoCols) {
                        return Row(
                          children: [
                            Expanded(child: nameField),
                            const SizedBox(width: 10),
                            Expanded(child: emailField),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          nameField,
                          const SizedBox(height: 10),
                          emailField,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _PreferenceSwitchRow(
                    title: translate(lang, 'settings.themeLabel'),
                    subtitle: translate(lang, 'settings.themeDesc'),
                    control: VyronSegmentedControl<VyronThemeMode>(
                      options: [
                        VyronSegmentOption(
                          value: VyronThemeMode.dark,
                          label: translate(lang, 'settings.themeDark'),
                        ),
                        VyronSegmentOption(
                          value: VyronThemeMode.light,
                          label: translate(lang, 'settings.themeLight'),
                        ),
                      ],
                      value: settings.theme,
                      onChanged: notifier.setTheme,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PreferenceSwitchRow(
                    title: translate(lang, 'settings.currencyLabel'),
                    subtitle: translate(lang, 'settings.currencyDesc'),
                    control: VyronSegmentedControl<CurrencyCode>(
                      options: const [
                        VyronSegmentOption(
                          value: CurrencyCode.brl,
                          label: 'BRL',
                        ),
                        VyronSegmentOption(
                          value: CurrencyCode.usd,
                          label: 'USD',
                        ),
                        VyronSegmentOption(
                          value: CurrencyCode.eur,
                          label: 'EUR',
                        ),
                      ],
                      value: settings.baseCurrency,
                      onChanged: notifier.setBaseCurrency,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PreferenceSwitchRow(
                    title: translate(lang, 'settings.languageLabel'),
                    subtitle: translate(lang, 'settings.languageDesc'),
                    control: VyronSegmentedControl<UiLanguage>(
                      options: const [
                        VyronSegmentOption(
                          value: UiLanguage.ptBR,
                          label: 'PT-BR',
                        ),
                        VyronSegmentOption(
                          value: UiLanguage.enUS,
                          label: 'EN-US',
                        ),
                      ],
                      value: settings.uiLanguage,
                      onChanged: (nextLang) => notifier.updateSettings(
                        OwnerSettingsPatch(uiLanguage: nextLang),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final policiesCard = VyronSurfacePanel(
              padding: VyronPanelPadding.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    translate(lang, 'settings.policiesTitle'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _PolicyCheckboxBox(
                    value: domain.systemControl.publishingEnabled,
                    title: translate(lang, 'settings.publishingLabel'),
                    subtitle: translate(lang, 'settings.publishingDesc'),
                    onChanged: (v) => notifier.toggleSystemFlags(
                      publishingEnabled: v,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PolicyCheckboxBox(
                    value: domain.systemControl.phaseBPublicAllowed,
                    title: translate(lang, 'settings.publicAllowedLabel'),
                    subtitle: translate(lang, 'settings.publicAllowedDesc'),
                    onChanged: (v) => notifier.toggleSystemFlags(
                      phaseBPublicAllowed: v,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, numCons) {
                      final cols = numCons.maxWidth >= 460 ? 3 : 1;
                      const spacing = 10.0;
                      final width =
                          (numCons.maxWidth - (cols - 1) * spacing) / cols;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: width,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  translate(
                                    lang,
                                    'settings.authValidityLabel',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: palette.textMuted,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _authHoursCtrl,
                                  focusNode: _authHoursFocus,
                                  keyboardType: TextInputType.number,
                                  onChanged: (raw) {
                                    final parsed = int.tryParse(raw.trim());
                                    if (parsed != null) {
                                      notifier.updateSettings(
                                        OwnerSettingsPatch(
                                          defaultAuthValidityHours:
                                              math.max(1, parsed),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  translate(
                                    lang,
                                    'settings.evidenceFreshnessLabel',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: palette.textMuted,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _evHoursCtrl,
                                  focusNode: _evHoursFocus,
                                  keyboardType: TextInputType.number,
                                  onChanged: (raw) {
                                    final parsed = int.tryParse(raw.trim());
                                    if (parsed != null) {
                                      notifier.updateSettings(
                                        OwnerSettingsPatch(
                                          evidenceFreshnessMaxHours:
                                              math.max(1, parsed),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  translate(
                                    lang,
                                    'settings.maxDailySpendLabel',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: palette.textMuted,
                                        fontSize: 11,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _maxSpendCtrl,
                                  focusNode: _maxSpendFocus,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (raw) {
                                    final parsed = double.tryParse(
                                      raw.trim().replaceAll(',', '.'),
                                    );
                                    if (parsed != null) {
                                      notifier.updateSettings(
                                        OwnerSettingsPatch(
                                          maxGlobalDailySpendBRL:
                                              math.max(0.0, parsed),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Emergency Stop All box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isHalted
                          ? VyronColors.crimson.withValues(alpha: 0.1)
                          : (isDark
                              ? VyronColors.obsidianBlack.withValues(alpha: 0.65)
                              : palette.surfaceAlt.withValues(alpha: 0.45)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHalted
                            ? VyronColors.crimson.withValues(alpha: 0.45)
                            : palette.panelBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    translate(lang, 'settings.emergencyTitle', {
                                      'controls':
                                          translate(lang, 'controls.title'),
                                      'state': labelSystemControlState(
                                        domain.systemControl.state,
                                        lang,
                                      ),
                                    }),
                                    style: TextStyle(
                                      fontFamily: VyronTypography.sans,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isHalted
                                          ? (isDark
                                              ? VyronColors.crimsonDarkText
                                              : VyronColors.crimsonLightText)
                                          : palette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    translate(lang, 'settings.emergencyDesc'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: palette.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              key: const Key('settings-stop-all-btn'),
                              onPressed: () {
                                if (isHalted) {
                                  final res = notifier.resumeSystemControl(
                                    settings.ownerName,
                                    translate(lang, 'settings.resumeReason'),
                                  );
                                  setState(() {
                                    _reconcileNotice = '';
                                    if (!res.ok) {
                                      _haltNoticeError = true;
                                      _haltNotice = res.reason ??
                                          translate(
                                            lang,
                                            'settings.resumeBlockedFallback',
                                          );
                                    } else {
                                      _haltNoticeError = false;
                                      _haltNotice = translate(
                                        lang,
                                        'settings.resumeFeedback',
                                      );
                                    }
                                  });
                                } else {
                                  final count = notifier.haltSystemControl(
                                    settings.ownerName,
                                    translate(lang, 'settings.haltReason'),
                                  );
                                  setState(() {
                                    _reconcileNotice = '';
                                    _haltNoticeError = true;
                                    _haltNotice = translate(
                                      lang,
                                      'settings.haltFeedback',
                                      {'count': count},
                                    );
                                  });
                                }
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
                                      ? 'settings.releaseAutonomy'
                                      : 'settings.triggerStopAll',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_haltNotice.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _haltNotice,
                            key: const Key('settings-halt-notice'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: _haltNoticeError
                                      ? (isDark
                                          ? VyronColors.amberDarkText
                                          : VyronColors.amberLightText)
                                      : (isDark
                                          ? VyronColors.emeraldDarkText
                                          : VyronColors.emeraldLightText),
                                ),
                          ),
                          if (_haltNoticeError &&
                              !canResumeSystemControl(
                                domain.jobRuns,
                                language: lang,
                              ).allowed) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton(
                                key: const Key('settings-inline-reconcile-btn'),
                                onPressed: () {
                                  final count = notifier.reconcileJobsDemo();
                                  setState(() {
                                    _haltNotice = '';
                                    _reconcileNotice = translate(
                                      lang,
                                      'settings.reconciledNotice',
                                      {'count': count},
                                    );
                                  });
                                },
                                child: Text(
                                  translate(lang, 'settings.reconcileNow'),
                                ),
                              ),
                            ),
                          ],
                        ],
                        if (_reconcileNotice.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _reconcileNotice,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? VyronColors.emeraldDarkText
                                      : VyronColors.emeraldLightText,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: profileCard),
                  const SizedBox(width: 14),
                  Expanded(child: policiesCard),
                ],
              );
            }
            return Column(
              children: [
                profileCard,
                const SizedBox(height: 14),
                policiesCard,
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Architecture Roadmap
        VyronSurfacePanel(
          padding: VyronPanelPadding.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translate(lang, 'settings.arch.title'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        translate(lang, 'settings.arch.subtitle'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: palette.textMuted),
                      ),
                    ],
                  ),
                  VyronToneBadge(
                    label: translate(
                      lang,
                      domain.systemControl.phaseBPublicAllowed
                          ? 'settings.arch.phaseB'
                          : 'settings.arch.phaseA',
                    ),
                    tone: VyronMetricTone.cobalt,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, archCons) {
                  final cols = archCons.maxWidth >= 860 ? 3 : 1;
                  const spacing = 12.0;
                  final width =
                      (archCons.maxWidth - (cols - 1) * spacing) / cols;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: width,
                        child: _ArchGroupCard(
                          title: translate(lang, 'settings.arch.grp1Title'),
                          titleColor: isDark
                              ? VyronColors.emeraldDarkText
                              : VyronColors.emeraldLightText,
                          items: [
                            translate(lang, 'settings.arch.grp1Item1'),
                            translate(lang, 'settings.arch.grp1Item2'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _ArchGroupCard(
                          title: translate(lang, 'settings.arch.grp2Title'),
                          titleColor: palette.cobaltText,
                          items: [
                            translate(lang, 'settings.arch.grp2Item1'),
                            translate(lang, 'settings.arch.grp2Item2'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _ArchGroupCard(
                          title: translate(lang, 'settings.arch.grp3Title'),
                          titleColor: palette.textPrimary,
                          items: [
                            translate(lang, 'settings.arch.grp3Item1'),
                            translate(lang, 'settings.arch.grp3Item2'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Risk Register Matrix
        VyronSurfacePanel(
          padding: VyronPanelPadding.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VyronSectionTitle(
                title: translate(lang, 'settings.risks.title'),
                subtitle: translate(lang, 'settings.risks.subtitle'),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 680) {
                    return Column(
                      children: [
                        for (final r in localizedRisks)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt.withValues(alpha: 0.2),
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
                                    Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          r.id,
                                          style: TextStyle(
                                            fontFamily: VyronTypography.mono,
                                            fontSize: 12,
                                            color: palette.textMuted,
                                          ),
                                        ),
                                        VyronToneBadge(
                                          label: r.priority.wire,
                                          tone: r.priority == RiskPriority.p0
                                              ? VyronMetricTone.crimson
                                              : r.priority == RiskPriority.p1
                                                  ? VyronMetricTone.amber
                                                  : VyronMetricTone.neutral,
                                        ),
                                      ],
                                    ),
                                    VyronStatusLabel(
                                      status: labelRiskStatus(r.status, lang),
                                      statusKey: r.status.wire,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  r.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  r.controlSummary,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: palette.textMuted),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: palette.panelBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text(
                                translate(lang, 'settings.risks.colId'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: palette.textMuted),
                              ),
                            ),
                            SizedBox(
                              width: 78,
                              child: Text(
                                translate(lang, 'settings.risks.colPriority'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: palette.textMuted),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                translate(lang, 'settings.risks.colRisk'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: palette.textMuted),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                translate(lang, 'settings.risks.colControl'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: palette.textMuted),
                              ),
                            ),
                            SizedBox(
                              width: 160,
                              child: Text(
                                translate(lang, 'common.status'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: palette.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final r in localizedRisks)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: palette.panelBorder
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 52,
                                child: Text(
                                  r.id,
                                  style: TextStyle(
                                    fontFamily: VyronTypography.mono,
                                    fontSize: 12,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 78,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: VyronToneBadge(
                                    label: r.priority.wire,
                                    tone: r.priority == RiskPriority.p0
                                        ? VyronMetricTone.crimson
                                        : r.priority == RiskPriority.p1
                                            ? VyronMetricTone.amber
                                            : VyronMetricTone.neutral,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    r.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: palette.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    r.controlSummary,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: palette.textMuted),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: VyronStatusLabel(
                                  status: labelRiskStatus(r.status, lang),
                                  statusKey: r.status.wire,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Vyron Access & Session Security
        VyronSurfacePanel(
          padding: VyronPanelPadding.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translate(lang, 'settings.access.title'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          translate(lang, 'settings.access.subtitle', {
                            'name': settings.ownerName,
                          }),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: palette.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('settings-lock-vyron-btn'),
                        onPressed: () =>
                            accessNotifier.lock(LockReason.manual),
                        icon: const Icon(Icons.lock_outline_rounded, size: 15),
                        label: Text(translate(lang, 'nav.lockVyron')),
                      ),
                      OutlinedButton.icon(
                        key: const Key('settings-logout-btn'),
                        onPressed: accessNotifier.logout,
                        icon: const Icon(Icons.logout_rounded, size: 15),
                        label: Text(translate(lang, 'nav.logout')),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, accCons) {
                  final isWide = accCons.maxWidth >= 820;

                  final timeoutPanel = Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          translate(lang, 'settings.access.autoLockLabel'),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 13,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          translate(lang, 'settings.access.autoLockDesc'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: palette.textMuted,
                                    fontSize: 11,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        VyronDropdownField<int>(
                          key: const Key('settings-idle-timeout-dropdown'),
                          value: idleTimeoutValues.contains(
                            accessState.session.idleTimeoutMinutes,
                          )
                              ? accessState.session.idleTimeoutMinutes
                              : defaultIdleTimeoutMinutes,
                          items: [
                            for (final minutes in idleTimeoutValues)
                              DropdownMenuItem(
                                value: minutes,
                                child: Text(_idleTimeoutLabel(minutes, lang)),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              accessNotifier.setIdleTimeoutMinutes(v);
                            }
                          },
                        ),
                      ],
                    ),
                  );

                  final passwordPanel = Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.panelBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          translate(lang, 'settings.access.updatePwdTitle'),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 13,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, pwdCons) {
                            final inline = pwdCons.maxWidth >= 460;
                            final cur = TextField(
                              key: const Key('settings-current-pwd'),
                              controller: _currentPwdCtrl,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: translate(
                                  lang,
                                  'settings.access.currentPwdPlaceholder',
                                ),
                              ),
                            );
                            final nw = TextField(
                              key: const Key('settings-new-pwd'),
                              controller: _newPwdCtrl,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: translate(
                                  lang,
                                  'settings.access.newPwdPlaceholder',
                                ),
                              ),
                            );
                            final btn = ElevatedButton(
                              key: const Key('settings-save-pwd-btn'),
                              onPressed: accessState.isVerifying
                                  ? null
                                  : () => _handleUpdatePassword(lang),
                              child: Text(
                                translate(lang, 'settings.access.savePwd'),
                              ),
                            );
                            if (inline) {
                              return Row(
                                children: [
                                  Expanded(child: cur),
                                  const SizedBox(width: 8),
                                  Expanded(child: nw),
                                  const SizedBox(width: 8),
                                  btn,
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                cur,
                                const SizedBox(height: 8),
                                nw,
                                const SizedBox(height: 8),
                                btn,
                              ],
                            );
                          },
                        ),
                        if (_pwdMsg.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _pwdMsg,
                            key: const Key('settings-pwd-feedback'),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _pwdMsgError
                                          ? (isDark
                                              ? VyronColors.crimsonDarkText
                                              : VyronColors.crimsonLightText)
                                          : (isDark
                                              ? VyronColors.emeraldDarkText
                                              : VyronColors.emeraldLightText),
                                    ),
                          ),
                        ],
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: timeoutPanel),
                        const SizedBox(width: 14),
                        Expanded(child: passwordPanel),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      timeoutPanel,
                      const SizedBox(height: 12),
                      passwordPanel,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Bottom Row: Notification Preferences & Integrations
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;

            final notifPrefsCard = VyronSurfacePanel(
              padding: VyronPanelPadding.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    translate(lang, 'settings.notifPrefs.title'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _NotifPrefTile(
                    label:
                        translate(lang, 'settings.notifPrefs.financialAlerts'),
                    value: settings.notificationPrefs.financialAlerts,
                    onChanged: (v) => notifier.updateSettings(
                      OwnerSettingsPatch(
                        notificationPrefs: settings.notificationPrefs
                            .copyWith(financialAlerts: v),
                      ),
                    ),
                  ),
                  _NotifPrefTile(
                    label: translate(
                      lang,
                      'settings.notifPrefs.commissionsReceived',
                    ),
                    value: settings.notificationPrefs.commissionsReceived,
                    onChanged: (v) => notifier.updateSettings(
                      OwnerSettingsPatch(
                        notificationPrefs: settings.notificationPrefs
                            .copyWith(commissionsReceived: v),
                      ),
                    ),
                  ),
                  _NotifPrefTile(
                    label: translate(lang, 'settings.notifPrefs.opportunities'),
                    value: settings.notificationPrefs.opportunities,
                    onChanged: (v) => notifier.updateSettings(
                      OwnerSettingsPatch(
                        notificationPrefs: settings.notificationPrefs
                            .copyWith(opportunities: v),
                      ),
                    ),
                  ),
                  _NotifPrefTile(
                    label:
                        translate(lang, 'settings.notifPrefs.pendingApprovals'),
                    value: settings.notificationPrefs.pendingApprovals,
                    onChanged: (v) => notifier.updateSettings(
                      OwnerSettingsPatch(
                        notificationPrefs: settings.notificationPrefs
                            .copyWith(pendingApprovals: v),
                      ),
                    ),
                  ),
                  _NotifPrefTile(
                    label: translate(
                      lang,
                      'settings.notifPrefs.automationFailures',
                    ),
                    value: settings.notificationPrefs.automationFailures,
                    onChanged: (v) => notifier.updateSettings(
                      OwnerSettingsPatch(
                        notificationPrefs: settings.notificationPrefs
                            .copyWith(automationFailures: v),
                      ),
                    ),
                  ),
                  _NotifPrefTile(
                    label: translate(
                      lang,
                      'settings.notifPrefs.operationalEvents',
                    ),
                    value: settings.notificationPrefs.operationalEvents,
                    onChanged: (v) => notifier.updateSettings(
                      OwnerSettingsPatch(
                        notificationPrefs: settings.notificationPrefs
                            .copyWith(operationalEvents: v),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final integrationsCard = VyronSurfacePanel(
              padding: VyronPanelPadding.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VyronSectionTitle(
                    title: translate(lang, 'settings.integrations.title'),
                    subtitle: translate(lang, 'settings.integrations.subtitle'),
                  ),
                  const SizedBox(height: 12),
                  for (final item in localizedIntegrations)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: palette.panelBorder.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: palette.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.category} · ${item.lastChecked}',
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
                          VyronStatusLabel(
                            status: labelIntegrationConfigStatus(
                              item.status,
                              lang,
                            ),
                            statusKey: item.status.wire,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: notifPrefsCard),
                  const SizedBox(width: 14),
                  Expanded(child: integrationsCard),
                ],
              );
            }
            return Column(
              children: [
                notifPrefsCard,
                const SizedBox(height: 14),
                integrationsCard,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PreferenceSwitchRow extends StatelessWidget {
  const _PreferenceSwitchRow({
    required this.title,
    required this.subtitle,
    required this.control,
  });

  final String title;
  final String subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceAlt.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          control,
        ],
      ),
    );
  }
}

class _PolicyCheckboxBox extends StatelessWidget {
  const _PolicyCheckboxBox({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return VyronToggleSwitch(
      value: value,
      label: title,
      subtitle: subtitle,
      onChanged: onChanged,
    );
  }
}

class _ArchGroupCard extends StatelessWidget {
  const _ArchGroupCard({
    required this.title,
    required this.titleColor,
    required this.items,
  });

  final String title;
  final Color titleColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: VyronTypography.sans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items) ...[
            Text(
              '• $item',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 11,
                  ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _NotifPrefTile extends StatelessWidget {
  const _NotifPrefTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: VyronToggleSwitch(
        value: value,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}
