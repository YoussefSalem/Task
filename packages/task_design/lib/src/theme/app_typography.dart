import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Display typography used for brand moments (splash, onboarding headers).
///
/// Pairs a geometric display face (Sora) against the Cairo body face used in
/// the theme — a deliberate display/body contrast rather than one family
/// everywhere.
abstract final class AppTypography {
  const AppTypography._();

  /// The "Task" wordmark. Tight tracking, heavy weight for a confident mark.
  static TextStyle wordmark({
    required Color color,
    double fontSize = 44,
  }) {
    return GoogleFonts.sora(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.0,
    );
  }
}
