import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_design/task_design.dart';

import 'tech_colors.dart';

/// The Technician app theme. Shares the design system's structure, spacing,
/// Cairo typography, and shared-axis page motion with the Customer app, but
/// recolours the brand from violet to a teal "work" accent (see [TechColors]).
///
/// Built independently from `AppTheme` (rather than `copyWith`) so every
/// brand-tinted surface — focus rings, button glow, cards — resolves to teal
/// instead of leaking the customer's violet through baked-in tokens.
abstract final class TechTheme {
  const TechTheme._();

  static const PageTransitionsTheme _transitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    },
  );

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: TechColors.accentBright,
      onPrimary: Color(0xFF04211C),
      primaryContainer: TechColors.accentDark,
      onPrimaryContainer: TechColors.accentContainer,
      secondary: TechColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
    );
    return _shared(base);
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: TechColors.accent,
      onPrimary: Colors.white,
      primaryContainer: TechColors.accentContainer,
      onPrimaryContainer: Color(0xFF0F3D38),
      secondary: TechColors.accentDark,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: Color(0xFFE0FBF6),
      error: AppColors.error,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4FBFA), // off-white, teal hint
      splashFactory: InkSparkle.splashFactory,
    );
    return _shared(base).copyWith(
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 1,
        shadowColor: const Color(0x0F000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: Color(0x12000000)),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: const Color(0xFFDDF5F1),
        enabled: const Color(0x28000000),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFCBD5D3)),
    );
  }

  static ThemeData _shared(ThemeData base) {
    final Color accent = base.colorScheme.primary;
    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      pageTransitionsTheme: _transitions,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: base.colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: base.colorScheme.surface,
        enabled: Colors.transparent,
        accent: accent,
      ),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color enabled,
    Color accent = TechColors.accent,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: c == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: c, width: w),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: border(Colors.transparent),
      enabledBorder: border(enabled),
      focusedBorder: border(accent, 1.6),
    );
  }
}
