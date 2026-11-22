import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/state/vyron_access_notifier.dart';
import '../../application/state/vyron_state_notifier.dart';
import '../../core/i18n/translate.dart';
import '../../core/security/vyron_access_rules.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/theme/vyron_theme.dart';
import '../../core/widgets/vyron_mark.dart';
import '../../domain/models/vyron_enums.dart';

/// Tela oficial de autenticação e desbloqueio Vyron Access (sempre Obsidian Dark).
class AccessScreen extends ConsumerStatefulWidget {
  const AccessScreen({
    super.key,
    this.onUnlocked,
  });

  final void Function({required bool wasLocked})? onUnlocked;

  @override
  ConsumerState<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends ConsumerState<AccessScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _mapAccessError(UiLanguage lang, AccessErrorCode? code) {
    if (code == null) return translate(lang, 'access.error.generic');
    final key = switch (code) {
      AccessErrorCode.emptyPassword => 'access.error.emptyPassword',
      AccessErrorCode.wrongPassword => 'access.error.wrongPassword',
      AccessErrorCode.currentWrong => 'access.error.currentWrong',
      AccessErrorCode.newTooShort => 'access.error.newTooShort',
    };
    return translate(lang, key);
  }

  Future<void> _submit() async {
    final accessState = ref.read(vyronAccessProvider);
    if (accessState.isVerifying) return;
    final lang = ref.read(vyronStateProvider).domain.settings.uiLanguage;
    final res = await ref
        .read(vyronAccessProvider.notifier)
        .login(_passwordController.text);

    if (!mounted) return;
    if (!res.ok) {
      setState(() {
        _errorMessage = _mapAccessError(lang, res.errorCode);
      });
      return;
    }

    _passwordController.clear();
    setState(() {
      _errorMessage = '';
    });
    widget.onUnlocked?.call(wasLocked: res.wasLocked);
  }

  @override
  Widget build(BuildContext context) {
    final accessState = ref.watch(vyronAccessProvider);
    final lang = ref.watch(
      vyronStateProvider.select((s) => s.domain.settings.uiLanguage),
    );
    final session = accessState.session;

    final String? lockNotice;
    if (session.locked && session.lockReason == LockReason.inactivity) {
      lockNotice = translate(lang, 'access.lockReason.inactivity');
    } else if (session.locked && session.lockReason == LockReason.manual) {
      lockNotice = translate(lang, 'access.lockReason.manual');
    } else if (session.lockReason == LockReason.expired) {
      lockNotice = translate(lang, 'access.lockReason.expired');
    } else {
      lockNotice = null;
    }

    final footerLockLabel = session.idleTimeoutMinutes > 0
        ? translate(
            lang,
            'access.autoLockLabel',
            {'minutes': session.idleTimeoutMinutes},
          )
        : translate(lang, 'access.manualLockLabel');

    // Tela de acesso preserva superfície escura oficial Obsidian & Cobalt.
    return Theme(
      data: VyronTheme.dark(),
      child: Scaffold(
        backgroundColor: VyronColors.obsidianBlack,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 416),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: VyronColors.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: VyronColors.titanium.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VyronWordmark(
                            markSize: 28,
                            fontSize: 15,
                            variant: VyronMarkVariant.cobalt,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            translate(lang, 'access.welcome'),
                            style: const TextStyle(
                              fontFamily: VyronTypography.display,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                              color: VyronColors.coolWhite,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            translate(lang, 'access.subtitle'),
                            style: const TextStyle(
                              fontFamily: VyronTypography.sans,
                              fontSize: 14,
                              color: VyronColors.titanium,
                            ),
                          ),
                          if (lockNotice != null) ...[
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    VyronColors.graphite.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: VyronColors.titanium
                                      .withValues(alpha: 0.16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 15,
                                    color: VyronColors.electricCobalt,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lockNotice,
                                      style: const TextStyle(
                                        fontFamily: VyronTypography.sans,
                                        fontSize: 12,
                                        color: VyronColors.titanium,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Text(
                            translate(lang, 'access.passwordLabel'),
                            style: const TextStyle(
                              fontFamily: VyronTypography.sans,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: VyronColors.titanium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('vyron-access-password'),
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            onChanged: (_) {
                              if (_errorMessage.isNotEmpty) {
                                setState(() {
                                  _errorMessage = '';
                                });
                              }
                            },
                            style: const TextStyle(
                              fontFamily: VyronTypography.sans,
                              fontSize: 14,
                              color: VyronColors.coolWhite,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  translate(lang, 'access.passwordPlaceholder'),
                              hintStyle: const TextStyle(
                                color: Color(0xFF687280),
                              ),
                              filled: true,
                              fillColor: VyronColors.obsidianBlack,
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? translate(lang, 'access.hidePassword')
                                    : translate(lang, 'access.showPassword'),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: VyronColors.titanium,
                                ),
                              ),
                            ),
                          ),
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              key: const Key('vyron-access-error'),
                              style: const TextStyle(
                                fontFamily: VyronTypography.sans,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: VyronColors.crimsonDarkText,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              key: const Key('vyron-access-submit'),
                              onPressed: accessState.isVerifying
                                  ? null
                                  : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VyronColors.electricCobalt,
                                disabledBackgroundColor: VyronColors
                                    .electricCobalt
                                    .withValues(alpha: 0.6),
                                foregroundColor: Colors.white,
                              ),
                              child: accessState.isVerifying
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          translate(lang, 'access.verifying'),
                                          style: const TextStyle(
                                            fontFamily: VyronTypography.sans,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      translate(lang, 'access.submit'),
                                      style: const TextStyle(
                                        fontFamily: VyronTypography.sans,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(
                            color: VyronColors.titanium.withValues(alpha: 0.14),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  translate(lang, 'access.privateFooter'),
                                  style: const TextStyle(
                                    fontFamily: VyronTypography.sans,
                                    fontSize: 12,
                                    color: VyronColors.titanium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                footerLockLabel,
                                style: TextStyle(
                                  fontFamily: VyronTypography.mono,
                                  fontSize: 11,
                                  color: VyronColors.titanium
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text.rich(
                        TextSpan(
                          text: translate(lang, 'access.demoDisclaimer'),
                          style: const TextStyle(
                            fontFamily: VyronTypography.sans,
                            fontSize: 11,
                            height: 1.45,
                            color: Color(0xFF7F8896),
                          ),
                          children: session.usingDefaultCredential
                              ? [
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: translate(lang, 'access.demoHint'),
                                  ),
                                  const TextSpan(text: ' '),
                                  const TextSpan(
                                    text: 'vyron2026',
                                    style: TextStyle(
                                      fontFamily: VyronTypography.mono,
                                      color: VyronColors.titanium,
                                    ),
                                  ),
                                ]
                              : const [],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
