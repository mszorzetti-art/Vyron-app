import 'package:flutter/material.dart';
import '../../core/theme/vyron_colors.dart';
import '../../core/widgets/vyron_mark.dart';

/// Minimal Lote 0 verification surface confirming offline fonts,
/// official Graphite & Cobalt tokens, and exact VyronMark rendering.
class BootSmokeScreen extends StatelessWidget {
  const BootSmokeScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const VyronWordmark(markSize: 30, fontSize: 16),
                        OutlinedButton(
                          onPressed: onToggleTheme,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textPrimary,
                            side: BorderSide(color: palette.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            isDark ? 'Modo Claro' : 'Modo Escuro',
                            style: const TextStyle(
                              fontFamily: VyronTypography.sans,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'INTELIGÊNCIA QUE CONECTA.\nPOTENCIAL QUE EVOLUI.',
                      style: TextStyle(
                        fontFamily: VyronTypography.display,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: palette.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.panelBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VYRON · GRAPHITE & COBALT',
                            style: TextStyle(
                              fontFamily: VyronTypography.mono,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: palette.cobaltText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Base Flutter operacional pronta para migração incremental.',
                            style: TextStyle(
                              fontFamily: VyronTypography.sans,
                              fontSize: 13,
                              color: palette.textPrimary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _SwatchDot(color: VyronColors.obsidianBlack),
                              _SwatchDot(color: VyronColors.graphite),
                              _SwatchDot(color: VyronColors.electricCobalt),
                              _SwatchDot(color: VyronColors.titanium),
                              _SwatchDot(color: VyronColors.coolWhite),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'com.marcuszorzetti.vyron',
                          style: TextStyle(
                            fontFamily: VyronTypography.mono,
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                        Text(
                          'LOTE 0',
                          style: TextStyle(
                            fontFamily: VyronTypography.mono,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: palette.cobaltText,
                          ),
                        ),
                      ],
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

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: context.vyronColors.border),
      ),
    );
  }
}
