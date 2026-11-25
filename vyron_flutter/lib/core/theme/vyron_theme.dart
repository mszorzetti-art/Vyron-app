import 'package:material_ui/material_ui.dart';

import 'vyron_colors.dart';

abstract final class VyronTheme {
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark
        ? VyronPaletteExtension.dark
        : VyronPaletteExtension.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: VyronColors.electricCobalt,
      onPrimary: Colors.white,
      secondary: palette.surfaceAlt,
      onSecondary: palette.textPrimary,
      error: isDark
          ? VyronColors.crimsonDarkText
          : VyronColors.crimsonLightText,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      outline: palette.border,
    );

    final baseTextTheme = TextTheme(
      displaySmall: TextStyle(
        fontFamily: VyronTypography.display,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
        letterSpacing: -0.4,
      ),
      headlineMedium: TextStyle(
        fontFamily: VyronTypography.display,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        color: palette.textPrimary,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontFamily: VyronTypography.display,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: VyronTypography.display,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: palette.textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: VyronTypography.display,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: palette.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: VyronTypography.sans,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: VyronTypography.sans,
        fontWeight: FontWeight.w400,
        fontSize: 13,
        color: palette.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: VyronTypography.sans,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: palette.textMuted,
      ),
      labelLarge: TextStyle(
        fontFamily: VyronTypography.sans,
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: palette.textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: VyronTypography.sans,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: palette.textMuted,
      ),
      labelSmall: TextStyle(
        fontFamily: VyronTypography.mono,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        color: palette.textMuted,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: VyronTypography.sans,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.sidebarBackground,
      splashFactory: NoSplash.splashFactory,
      highlightColor: VyronColors.electricCobalt.withValues(alpha: 0.08),
      textTheme: baseTextTheme,
      dividerColor: palette.panelBorder,
      dividerTheme: DividerThemeData(
        color: palette.panelBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: palette.panelBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? VyronColors.obsidianBlack
            : VyronColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: VyronColors.electricCobalt,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VyronColors.electricCobalt,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: VyronTypography.sans,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      extensions: [palette],
    );
  }
}
