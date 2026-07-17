import 'package:flutter/material.dart';

/// Technician-app accent tokens.
///
/// The Technician app is a sibling of the Customer app: it keeps the shared
/// dark-navy neutrals (`AppColors.background` / `.surface`) so the two feel like
/// one product family, but swaps the customer's violet brand for a teal "work"
/// accent. Teal reads as tool, meter, and readiness — the language of a pro on
/// the job — and stays clearly distinct from the emerald `success` green.
abstract final class TechColors {
  const TechColors._();

  // ── Teal accent (theme-invariant brand) ─────────────────────────────────
  /// Core brand accent. Legible on the near-white light surface.
  static const Color accent = Color(0xFF0D9488); // teal-600
  /// Hover / depth.
  static const Color accentDark = Color(0xFF0F766E); // teal-700
  /// Luminous highlight — the "live" glow on dark surfaces.
  static const Color accentBright = Color(0xFF2DD4BF); // teal-400
  /// Light lavender-equivalent tint for containers.
  static const Color accentContainer = Color(0xFFCCFBF1); // teal-100

  // ── Availability semantics ───────────────────────────────────────────────
  /// "Online / accepting jobs" — the emerald go-signal.
  static const Color online = Color(0xFF10B981);
  /// "Offline / paused" — a calm slate.
  static const Color offline = Color(0xFF64748B);

  // ── Money ─────────────────────────────────────────────────────────────────
  /// Earnings figures lean on the brand teal so payouts feel on-brand.
  static const Color earnings = Color(0xFF14B8A6);
}
