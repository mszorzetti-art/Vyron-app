import 'package:material_ui/material_ui.dart';

import '../theme/vyron_colors.dart';

/// Primitivo estrutural de skeleton loading alinhado à estética Graphite & Cobalt.
class VyronSkeletonBox extends StatefulWidget {
  const VyronSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 6,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<VyronSkeletonBox> createState() => _VyronSkeletonBoxState();
}

class _VyronSkeletonBoxState extends State<VyronSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? VyronColors.graphite.withValues(alpha: 0.72)
        : VyronColors.lightSurfaceAlt;
    final highlightColor = isDark
        ? VyronColors.titanium.withValues(alpha: 0.16)
        : VyronColors.lightPanelBorder;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final fill =
            Color.lerp(baseColor, highlightColor, _controller.value) ??
            baseColor;
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: palette.panelBorder.withValues(alpha: 0.4),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton estrutural para blocos de KPI (1, 2 ou 4 colunas responsivas).
class VyronKpiGridSkeleton extends StatelessWidget {
  const VyronKpiGridSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 960
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - (cols - 1) * spacing) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: cardWidth,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.panelBorder),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VyronSkeletonBox(width: 112, height: 12, borderRadius: 4),
                      SizedBox(height: 12),
                      VyronSkeletonBox(width: 148, height: 22, borderRadius: 5),
                      SizedBox(height: 10),
                      VyronSkeletonBox(width: 176, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Skeleton estrutural preservando altura e eixos do painel de gráfico Vyron.
class VyronChartSkeleton extends StatelessWidget {
  const VyronChartSkeleton({super.key, this.height = 240});

  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      key: const Key('vyron-chart-skeleton'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VyronSkeletonBox(width: 190, height: 16, borderRadius: 4),
                  SizedBox(height: 6),
                  VyronSkeletonBox(width: 240, height: 12, borderRadius: 4),
                ],
              ),
              VyronSkeletonBox(width: 160, height: 30, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var r = 0; r < 5; r++)
                  Row(
                    children: [
                      const VyronSkeletonBox(
                        width: 44,
                        height: 10,
                        borderRadius: 3,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: VyronSkeletonBox(
                          height: r == 2 ? 42 : 2,
                          borderRadius: r == 2 ? 6 : 2,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const VyronSkeletonBox(width: 220, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton estrutural para tabelas de dados e ledgers financeiros/execuções.
class VyronTableSkeleton extends StatelessWidget {
  const VyronTableSkeleton({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Container(
      key: const Key('vyron-table-skeleton'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Expanded(flex: 2, child: VyronSkeletonBox(height: 12)),
              SizedBox(width: 12),
              Expanded(flex: 2, child: VyronSkeletonBox(height: 12)),
              SizedBox(width: 12),
              Expanded(flex: 1, child: VyronSkeletonBox(height: 12)),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(flex: 2, child: VyronSkeletonBox(height: 16)),
                SizedBox(width: 12),
                Expanded(flex: 2, child: VyronSkeletonBox(height: 16)),
                SizedBox(width: 12),
                Expanded(flex: 1, child: VyronSkeletonBox(height: 16)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton estrutural de lista de cards (Notificações, Agentes, Marcas, Atividades).
class VyronCardListSkeleton extends StatelessWidget {
  const VyronCardListSkeleton({super.key, this.cards = 3});

  final int cards;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return Column(
      key: const Key('vyron-card-list-skeleton'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cards; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.panelBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VyronSkeletonBox(width: 140, height: 14, borderRadius: 4),
                    VyronSkeletonBox(width: 72, height: 20, borderRadius: 5),
                  ],
                ),
                SizedBox(height: 10),
                VyronSkeletonBox(height: 12, borderRadius: 4),
                SizedBox(height: 6),
                VyronSkeletonBox(width: 240, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Skeleton completo de módulo utilizado durante a hidratação atômica inicial.
class VyronModuleSkeleton extends StatelessWidget {
  const VyronModuleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    return SingleChildScrollView(
      key: const Key('vyron-module-skeleton'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.panelBorder)),
            ),
            child: const Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VyronSkeletonBox(width: 220, height: 24, borderRadius: 5),
                    SizedBox(height: 8),
                    VyronSkeletonBox(width: 290, height: 13, borderRadius: 4),
                  ],
                ),
                VyronSkeletonBox(width: 140, height: 36, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const VyronKpiGridSkeleton(count: 4),
          const SizedBox(height: 18),
          const VyronChartSkeleton(height: 210),
          const SizedBox(height: 18),
          const VyronTableSkeleton(rows: 3),
        ],
      ),
    );
  }
}
