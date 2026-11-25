import 'package:material_ui/material_ui.dart';

import '../theme/vyron_colors.dart';

enum VyronMarkVariant {
  /// Primary brand color gradient (#3B6BFF -> #315FEA -> #1D44C4)
  cobalt,

  /// Cool White monochrome (#F1F2F3) for dark surfaces
  white,

  /// Titanium/Graphite monochrome (#AEB7C2)
  titanium,

  /// Obsidian Black (#101216) for Cool White / light surfaces
  obsidian,
}

/// Official Vyron geometric symbol faithfully constructed from src/components/VyronBrand.tsx
/// and the official brand identity sheets (viewBox 100 x 72 proportion).
class VyronMark extends StatelessWidget {
  const VyronMark({
    super.key,
    this.size = 28,
    this.variant = VyronMarkVariant.cobalt,
  });

  final double size;
  final VyronMarkVariant variant;

  static const double aspectRatio = 0.72;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * aspectRatio,
      child: CustomPaint(painter: VyronMarkPainter(variant: variant)),
    );
  }
}

class VyronMarkPainter extends CustomPainter {
  const VyronMarkPainter({required this.variant});

  final VyronMarkVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100.0;
    final sy = size.height / 72.0;

    canvas.save();
    canvas.scale(sx, sy);

    final paint = Paint()..style = PaintingStyle.fill;

    switch (variant) {
      case VyronMarkVariant.cobalt:
        paint.shader = const LinearGradient(
          begin: Alignment(-0.84, -0.83),
          end: Alignment(0.84, 0.89),
          colors: [
            VyronColors.markGradientStart,
            VyronColors.markGradientMid,
            VyronColors.markGradientEnd,
          ],
          stops: [0.0, 0.55, 1.0],
        ).createShader(const Rect.fromLTWH(8, 6, 84, 62));
      case VyronMarkVariant.white:
        paint.color = VyronColors.coolWhite;
      case VyronMarkVariant.titanium:
        paint.color = VyronColors.titanium;
      case VyronMarkVariant.obsidian:
        paint.color = VyronColors.obsidianBlack;
    }

    // Left Wing: M4 6 H31.5 L51.5 40.5 L39.2 66 L4 6 Z
    final leftWing = Path()
      ..moveTo(4, 6)
      ..lineTo(31.5, 6)
      ..lineTo(51.5, 40.5)
      ..lineTo(39.2, 66)
      ..lineTo(4, 6)
      ..close();

    // Right Upper Hooked Wing: M55.5 6 H96 L86.8 22 H63.5 L52.8 40.5 L45.2 27.4 L55.5 6 Z
    final rightUpper = Path()
      ..moveTo(55.5, 6)
      ..lineTo(96, 6)
      ..lineTo(86.8, 22)
      ..lineTo(63.5, 22)
      ..lineTo(52.8, 40.5)
      ..lineTo(45.2, 27.4)
      ..lineTo(55.5, 6)
      ..close();

    // Right Lower Diagonal Fold: M65.8 27 H84.2 L60.2 66 H44.5 L65.8 27 Z
    final rightLower = Path()
      ..moveTo(65.8, 27)
      ..lineTo(84.2, 27)
      ..lineTo(60.2, 66)
      ..lineTo(44.5, 66)
      ..lineTo(65.8, 27)
      ..close();

    canvas.drawPath(leftWing, paint);
    canvas.drawPath(rightUpper, paint);
    canvas.drawPath(rightLower, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VyronMarkPainter oldDelegate) =>
      oldDelegate.variant != variant;
}

class VyronWordmark extends StatelessWidget {
  const VyronWordmark({
    super.key,
    this.showMark = true,
    this.markSize = 26,
    this.fontSize = 15,
    this.variant = VyronMarkVariant.cobalt,
    this.showDivider = false,
  });

  final bool showMark;
  final double markSize;
  final double fontSize;
  final VyronMarkVariant variant;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.vyronColors;
    final wordColor = variant == VyronMarkVariant.white
        ? VyronColors.coolWhite
        : variant == VyronMarkVariant.obsidian
        ? VyronColors.obsidianBlack
        : variant == VyronMarkVariant.titanium
        ? VyronColors.titanium
        : palette.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMark) VyronMark(size: markSize, variant: variant),
        if (showMark && showDivider) ...[
          const SizedBox(width: 14),
          Container(width: 1, height: markSize * 0.85, color: palette.border),
          const SizedBox(width: 14),
        ] else if (showMark) ...[
          const SizedBox(width: 12),
        ],
        Text(
          'VYRON',
          style: TextStyle(
            fontFamily: VyronTypography.display,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            letterSpacing: fontSize * 0.32,
            color: wordColor,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
