import 'package:flutter/material.dart';
import '../i18n/translate.dart';
import '../theme/vyron_colors.dart';
import '../../domain/models/vyron_enums.dart';

enum VyronMetricTone {
  neutral,
  cobalt,
  emerald,
  amber,
  crimson,
}

/// Cabeçalho padrão de módulo (título, subtítulo e ações adaptativas).
class VyronPageHeader extends StatelessWidget {
  const VyronPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.panelBorder),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 680;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: isWide ? 26 : 22,
                      letterSpacing: -0.4,
                    ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ],
          );

          if (actions.isEmpty) {
            return titleBlock;
          }

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                Flexible(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: actions,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

enum VyronPanelPadding {
  none,
  sm,
  md,
  lg,
}

/// Painel arquitetônico Vyron com borda de 1px e cantos de 8px.
class VyronSurfacePanel extends StatelessWidget {
  const VyronSurfacePanel({
    super.key,
    required this.child,
    this.padding = VyronPanelPadding.md,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final VyronPanelPadding padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final edgeInsets = switch (padding) {
      VyronPanelPadding.none => EdgeInsets.zero,
      VyronPanelPadding.sm => const EdgeInsets.all(14),
      VyronPanelPadding.md => const EdgeInsets.all(18),
      VyronPanelPadding.lg => const EdgeInsets.all(22),
    };

    return Container(
      width: double.infinity,
      padding: edgeInsets,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? palette.panelBorder),
      ),
      child: child,
    );
  }
}

/// Bloco de KPI com algarismos tabulares em JetBrains Mono e navegação opcional.
class VyronMetricBlock extends StatelessWidget {
  const VyronMetricBlock({
    super.key,
    required this.label,
    required this.value,
    this.helper,
    this.tone = VyronMetricTone.neutral,
    this.onTap,
  });

  final String label;
  final String value;
  final String? helper;
  final VyronMetricTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final valueColor = switch (tone) {
      VyronMetricTone.neutral => palette.textPrimary,
      VyronMetricTone.cobalt =>
        isDark ? VyronColors.cobaltMetricDark : VyronColors.electricCobalt,
      VyronMetricTone.emerald =>
        isDark ? VyronColors.emeraldDarkText : VyronColors.emeraldLightText,
      VyronMetricTone.amber =>
        isDark ? VyronColors.amberDarkText : VyronColors.amberLightText,
      VyronMetricTone.crimson =>
        isDark ? VyronColors.crimsonDarkText : VyronColors.crimsonLightText,
    };

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: VyronTypography.sans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: VyronTypography.mono,
              fontSize: 21,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (helper != null && helper!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              helper!,
              style: TextStyle(
                fontFamily: VyronTypography.sans,
                fontSize: 12,
                color: palette.textMuted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: palette.panelBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              hoverColor: VyronColors.electricCobalt.withValues(alpha: 0.05),
              child: body,
            )
          : body,
    );
  }
}

/// Rótulo semântico com ícone + texto equivalente ao `StatusLabel` do React.
class VyronStatusLabel extends StatelessWidget {
  const VyronStatusLabel({
    super.key,
    required this.status,
    this.statusKey,
  });

  final String status;
  final String? statusKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = (statusKey ?? status).toLowerCase();

    var icon = Icons.schedule_rounded;
    var color = palette.textMuted;

    if (s.contains('approved') ||
        s.contains('aprovado') ||
        s.contains('published') ||
        s.contains('publicado') ||
        s.contains('received') ||
        s.contains('recebido') ||
        s.contains('active') ||
        s.contains('ativo') ||
        s.contains('success') ||
        s.contains('succeeded') ||
        s.contains('concluído') ||
        s.contains('mitigado') ||
        s.contains('mitigated') ||
        s.contains('configurado') ||
        s.contains('configured') ||
        s.contains('pronto') ||
        s.contains('ready')) {
      icon = Icons.check_circle_outline_rounded;
      color =
          isDark ? VyronColors.emeraldDarkText : VyronColors.emeraldLightText;
    } else if (s.contains('running') || s.contains('em execução')) {
      icon = Icons.play_circle_outline_rounded;
      color =
          isDark ? VyronColors.cobaltMetricDark : VyronColors.electricCobalt;
    } else if (s.contains('confirmed') ||
        s.contains('confirmado') ||
        s.contains('in review') ||
        s.contains('em revisão') ||
        s.contains('waiting') ||
        s.contains('aguardando') ||
        s.contains('atenção') ||
        s.contains('attention') ||
        s.contains('pendente') ||
        s.contains('pending') ||
        s.contains('infraestrutura') ||
        s.contains('infrastructure') ||
        s.contains('candidate') ||
        s.contains('candidato') ||
        s.contains('unknown') ||
        s.contains('desconhecido') ||
        s.contains('aberto') ||
        s == 'open') {
      icon = Icons.schedule_rounded;
      color = isDark ? VyronColors.amberDarkText : VyronColors.amberLightText;
    } else if (s.contains('paused') ||
        s.contains('pausado') ||
        s.contains('idle') ||
        s.contains('em espera') ||
        s.contains('brief') ||
        s.contains('content plan') ||
        s.contains('planejamento') ||
        s.contains('draft') ||
        s.contains('rascunho') ||
        s.contains('not_applicable') ||
        s == 'n/a' ||
        s.contains('desativado') ||
        s.contains('disabled')) {
      icon = Icons.pause_circle_outline_rounded;
      color = palette.textMuted;
    } else if (s.contains('archived') || s.contains('arquivado')) {
      icon = Icons.inventory_2_outlined;
      color = palette.textMuted;
    } else if (s.contains('rejected') ||
        s.contains('rejeitado') ||
        s.contains('error') ||
        s.contains('falh') ||
        s.contains('failed') ||
        s.contains('halted') ||
        s.contains('interrompido') ||
        s.contains('parado') ||
        s.contains('blocked') ||
        s.contains('bloqueado') ||
        s.contains('desconectado') ||
        s.contains('disconnected')) {
      icon = Icons.cancel_outlined;
      color =
          isDark ? VyronColors.crimsonDarkText : VyronColors.crimsonLightText;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            status,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: VyronTypography.sans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tag estrutural compacta (cantos de 6px, estética zero-pill).
class VyronToneBadge extends StatelessWidget {
  const VyronToneBadge({
    super.key,
    required this.label,
    this.tone = VyronMetricTone.neutral,
    this.monospace = false,
  });

  final String label;
  final VyronMetricTone tone;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fg = switch (tone) {
      VyronMetricTone.neutral => palette.textMuted,
      VyronMetricTone.cobalt => palette.cobaltText,
      VyronMetricTone.emerald =>
        isDark ? VyronColors.emeraldDarkText : VyronColors.emeraldLightText,
      VyronMetricTone.amber =>
        isDark ? VyronColors.amberDarkText : VyronColors.amberLightText,
      VyronMetricTone.crimson =>
        isDark ? VyronColors.crimsonDarkText : VyronColors.crimsonLightText,
    };

    final bg = switch (tone) {
      VyronMetricTone.neutral => palette.surfaceAlt.withValues(alpha: 0.45),
      VyronMetricTone.cobalt =>
        VyronColors.electricCobalt.withValues(alpha: 0.12),
      VyronMetricTone.emerald => VyronColors.emerald.withValues(alpha: 0.12),
      VyronMetricTone.amber => VyronColors.amber.withValues(alpha: 0.14),
      VyronMetricTone.crimson => VyronColors.crimson.withValues(alpha: 0.14),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: monospace ? VyronTypography.mono : VyronTypography.sans,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          fontFeatures:
              monospace ? const [FontFeature.tabularFigures()] : null,
        ),
      ),
    );
  }
}

class VyronProgressBar extends StatelessWidget {
  const VyronProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
  });

  /// Valor normalizado entre 0.0 e 1.0.
  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: palette.surfaceAlt.withValues(alpha: 0.65),
              ),
            ),
            FractionallySizedBox(
              widthFactor: clamped,
              heightFactor: 1,
              child: ColoredBox(
                color: color ?? VyronColors.electricCobalt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VyronEmptyState extends StatelessWidget {
  const VyronEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 26,
            color: palette.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    height: 1.45,
                  ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class VyronSegmentOption<T> {
  const VyronSegmentOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class VyronSegmentedControl<T> extends StatelessWidget {
  const VyronSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<VyronSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackBg = isDark ? VyronColors.obsidianBlack : palette.surfaceAlt;
    final activeBg = isDark ? VyronColors.graphite : VyronColors.lightSurface;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.panelBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final opt in options)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: InkWell(
                  onTap: () => onChanged(opt.value),
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: opt.value == value ? activeBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      opt.label,
                      style: TextStyle(
                        fontFamily: VyronTypography.sans,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: opt.value == value
                            ? palette.textPrimary
                            : palette.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VyronSectionTitle extends StatelessWidget {
  const VyronSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

/// Abre janela modal responsiva equivalente ao `ModalDialog` de src/components/ui.tsx.
Future<T?> showVyronModalDialog<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required UiLanguage language,
  required Widget Function(BuildContext dialogContext) builder,
  double maxWidth = 520,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final palette = dialogContext.vyronColors;
      final closeLabel = translate(language, 'common.close');
      return Dialog(
        backgroundColor: palette.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: palette.border),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: palette.panelBorder),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: Theme.of(dialogContext).textTheme.titleMedium,
                          ),
                          if (subtitle != null && subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: palette.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        side: BorderSide(color: palette.border),
                        foregroundColor: palette.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        closeLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: builder(dialogContext),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Version-safe stylized dropdown field preserving exact Vyron border and label aesthetics.
class VyronDropdownField<T> extends StatelessWidget {
  const VyronDropdownField({
    super.key,
    this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String? labelText;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: palette.border),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: palette.surface,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
