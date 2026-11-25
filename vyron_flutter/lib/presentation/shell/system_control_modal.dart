import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/translate.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_ui.dart';
import '../../domain/models/vyron_enums.dart';
import '../../domain/rules/vyron_rules.dart';

enum SystemControlModalMode { halt, resume }

Future<void> showSystemControlModal({
  required BuildContext context,
  required SystemControlModalMode mode,
  required UiLanguage language,
  required String initialActor,
}) {
  return showVyronModalDialog<void>(
    context: context,
    language: language,
    title: translate(
      language,
      mode == SystemControlModalMode.halt
          ? 'controls.modal.haltTitle'
          : 'controls.modal.resumeTitle',
    ),
    subtitle: translate(
      language,
      mode == SystemControlModalMode.halt
          ? 'controls.modal.haltSubtitle'
          : 'controls.modal.resumeSubtitle',
    ),
    builder: (_) =>
        _SystemControlModalBody(mode: mode, initialActor: initialActor),
  );
}

class _SystemControlModalBody extends ConsumerStatefulWidget {
  const _SystemControlModalBody({
    required this.mode,
    required this.initialActor,
  });

  final SystemControlModalMode mode;
  final String initialActor;

  @override
  ConsumerState<_SystemControlModalBody> createState() =>
      _SystemControlModalBodyState();
}

class _SystemControlModalBodyState
    extends ConsumerState<_SystemControlModalBody> {
  late final TextEditingController _actorController;
  final TextEditingController _reasonController = TextEditingController();
  String _error = '';

  @override
  void initState() {
    super.initState();
    _actorController = TextEditingController(text: widget.initialActor);
  }

  @override
  void dispose() {
    _actorController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final domain = ref.read(vyronStateProvider).domain;
    final lang = domain.settings.uiLanguage;
    final actor = _actorController.text.trim();
    final reason = _reasonController.text.trim();

    if (actor.isEmpty || reason.isEmpty) {
      setState(() {
        _error = translate(lang, 'controls.modal.missingFields');
      });
      return;
    }

    final notifier = ref.read(vyronStateProvider.notifier);
    if (widget.mode == SystemControlModalMode.halt) {
      notifier.haltSystemControl(actor, reason);
      Navigator.of(context).pop();
      return;
    }

    final res = notifier.resumeSystemControl(actor, reason);
    if (!res.ok) {
      setState(() {
        _error =
            res.reason ??
            translate(lang, 'controls.modal.resumeBlockedDefault');
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(vyronStateProvider);
    final lang = appState.domain.settings.uiLanguage;
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resumeGate = canResumeSystemControl(
      appState.domain.jobRuns,
      language: lang,
    );
    final resumeBlocked =
        widget.mode == SystemControlModalMode.resume && !resumeGate.allowed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (resumeBlocked) ...[
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
                  translate(lang, 'controls.modal.orphanWarningTitle'),
                  style: TextStyle(
                    fontFamily: VyronTypography.sans,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? VyronColors.amberDarkText
                        : VyronColors.amberLightText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resumeGate.reason ?? '',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    ref.read(vyronStateProvider.notifier).reconcileJobsDemo();
                    setState(() {
                      _error = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VyronColors.amber,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(translate(lang, 'controls.modal.reconcileNow')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          translate(lang, 'controls.modal.actorLabel'),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: palette.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('vyron-control-actor'),
          controller: _actorController,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Text(
          translate(lang, 'controls.modal.reasonLabel'),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: palette.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('vyron-control-reason'),
          controller: _reasonController,
          maxLines: 2,
          onChanged: (_) {
            if (_error.isNotEmpty) {
              setState(() {
                _error = '';
              });
            }
          },
          decoration: InputDecoration(
            hintText: translate(
              lang,
              widget.mode == SystemControlModalMode.halt
                  ? 'controls.modal.haltPlaceholder'
                  : 'controls.modal.resumePlaceholder',
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _error,
            style: TextStyle(
              fontFamily: VyronTypography.sans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? VyronColors.crimsonDarkText
                  : VyronColors.crimsonLightText,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: palette.border),
                foregroundColor: palette.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(translate(lang, 'common.cancel')),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              key: const Key('vyron-control-confirm'),
              onPressed: resumeBlocked ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.mode == SystemControlModalMode.halt
                    ? (isDark
                          ? VyronColors.crimson
                          : VyronColors.crimsonLightButton)
                    : VyronColors.electricCobalt,
                foregroundColor: Colors.white,
              ),
              child: Text(
                translate(
                  lang,
                  widget.mode == SystemControlModalMode.halt
                      ? 'controls.modal.confirmHalt'
                      : 'controls.modal.confirmResume',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
