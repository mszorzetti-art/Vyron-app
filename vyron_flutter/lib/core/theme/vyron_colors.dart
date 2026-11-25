import 'package:material_ui/material_ui.dart';

/// Official Vyron Graphite & Cobalt visual identity tokens.
/// Preserved identically from src/index.css and official brand sheets.
abstract final class VyronColors {
  // Core Brand Palette
  static const Color obsidianBlack = Color(0xFF101216);
  static const Color darkSurface = Color(0xFF171A20);
  static const Color darkSidebar = Color(0xFF14171C);
  static const Color graphite = Color(0xFF292E36);
  static const Color electricCobalt = Color(0xFF315FEA);
  static const Color cobaltHover = Color(0xFF274FC9);
  static const Color cobaltTextDark = Color(0xFF7FA0FF);
  static const Color cobaltMetricDark = Color(0xFF6B8FFF);
  static const Color titanium = Color(0xFFAEB7C2);
  static const Color lightMuted = Color(0xFF525B68);
  static const Color coolWhite = Color(0xFFF1F2F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFE6E9ED);

  // Official Brand Mark Gradient Stops
  static const Color markGradientStart = Color(0xFF3B6BFF);
  static const Color markGradientMid = Color(0xFF315FEA);
  static const Color markGradientEnd = Color(0xFF1D44C4);

  // Borders
  static const Color darkBorder = Color(0x21AEB7C2); // ~13% Titanium
  static const Color darkPanelBorder = Color(0x1AFFFFFF); // 10% white
  static const Color lightBorder = Color(0x1C101216); // ~11% Obsidian
  static const Color lightPanelBorder = Color(0x1A000000); // 10% black

  // Semantic Status Colors
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDarkText = Color(0xFF34D399);
  static const Color emeraldLightText = Color(0xFF047857);
  static const Color amber = Color(0xFFD97706);
  static const Color amberDarkText = Color(0xFFFBBF24);
  static const Color amberLightText = Color(0xFFB45309);
  static const Color crimson = Color(0xFFA62633);
  static const Color crimsonLightButton = Color(0xFF9E2430);
  static const Color crimsonDarkText = Color(0xFFF87171);
  static const Color crimsonLightText = Color(0xFFBE123C);
}

abstract final class VyronTypography {
  static const String display = 'PlusJakartaSans';
  static const String sans = 'DMSans';
  static const String mono = 'JetBrainsMono';
}

@immutable
class VyronPaletteExtension extends ThemeExtension<VyronPaletteExtension> {
  const VyronPaletteExtension({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.sidebarBackground,
    required this.border,
    required this.panelBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.cobalt,
    required this.cobaltText,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color sidebarBackground;
  final Color border;
  final Color panelBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color cobalt;
  final Color cobaltText;

  static const VyronPaletteExtension dark = VyronPaletteExtension(
    background: VyronColors.obsidianBlack,
    surface: VyronColors.darkSurface,
    surfaceAlt: VyronColors.graphite,
    sidebarBackground: VyronColors.darkSidebar,
    border: VyronColors.darkBorder,
    panelBorder: VyronColors.darkPanelBorder,
    textPrimary: VyronColors.coolWhite,
    textMuted: VyronColors.titanium,
    cobalt: VyronColors.electricCobalt,
    cobaltText: VyronColors.cobaltTextDark,
  );

  static const VyronPaletteExtension light = VyronPaletteExtension(
    background: VyronColors.coolWhite,
    surface: VyronColors.lightSurface,
    surfaceAlt: VyronColors.lightSurfaceAlt,
    sidebarBackground: VyronColors.lightSurface,
    border: VyronColors.lightBorder,
    panelBorder: VyronColors.lightPanelBorder,
    textPrimary: VyronColors.obsidianBlack,
    textMuted: VyronColors.lightMuted,
    cobalt: VyronColors.electricCobalt,
    cobaltText: VyronColors.electricCobalt,
  );

  @override
  VyronPaletteExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? sidebarBackground,
    Color? border,
    Color? panelBorder,
    Color? textPrimary,
    Color? textMuted,
    Color? cobalt,
    Color? cobaltText,
  }) {
    return VyronPaletteExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      border: border ?? this.border,
      panelBorder: panelBorder ?? this.panelBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      cobalt: cobalt ?? this.cobalt,
      cobaltText: cobaltText ?? this.cobaltText,
    );
  }

  @override
  VyronPaletteExtension lerp(
    covariant ThemeExtension<VyronPaletteExtension>? other,
    double t,
  ) {
    if (other is! VyronPaletteExtension) return this;
    return VyronPaletteExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      sidebarBackground: Color.lerp(
        sidebarBackground,
        other.sidebarBackground,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      cobalt: Color.lerp(cobalt, other.cobalt, t)!,
      cobaltText: Color.lerp(cobaltText, other.cobaltText, t)!,
    );
  }
}

extension VyronThemeContext on BuildContext {
  VyronPaletteExtension get vyronColors =>
      Theme.of(this).extension<VyronPaletteExtension>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? VyronPaletteExtension.dark
          : VyronPaletteExtension.light);
}

/// Converts CSS hex color strings (`#RRGGBB` or `#AARRGGBB`) to Flutter [Color].
Color parseVyronHexColor(
  String hex, {
  Color fallback = VyronColors.electricCobalt,
}) {
  final cleaned = hex.trim().replaceFirst('#', '');
  if (cleaned.length == 6) {
    final parsed = int.tryParse('FF$cleaned', radix: 16);
    if (parsed != null) return Color(parsed);
  } else if (cleaned.length == 8) {
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return fallback;
}
