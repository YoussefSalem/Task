import 'package:flutter/material.dart';

/// Design tokens from the PRD "Dark Theme Blueprint" (§1.2 / discovery doc).
///
/// These are raw brand values. Widgets should prefer `Theme.of(context)`
/// (ColorScheme) and reach for these tokens only for brand-specific accents
/// not expressible through the scheme.
abstract final class AppColors {
  const AppColors._();

  // ── Brand (theme-invariant) ──────────────────────────────────────────────
  static const Color primary = Color(0xFF7C3AED); // brand / active states
  static const Color primaryDark = Color(0xFF5B21B6); // hover / depth
  static const Color primaryContainer = Color(0xFFEDE9FE); // light lavender tint

  // ── Dark theme ───────────────────────────────────────────────────────────
  static const Color surface = Color(0xFF374151); // cards, dividers
  static const Color background = Color(0xFF111827); // base background
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE5E7EB);

  // ── Light theme ──────────────────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8F7FF); // off-white, lavender hint
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF4B5563);

  // ── Status indicators (shared) ───────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
