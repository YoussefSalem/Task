import 'package:meta/meta.dart';

/// A marketing banner shown in the home hero carousel, stored in the top-level
/// `promotions` collection and managed by admins. Purely presentational content
/// — no per-user data.
@immutable
class Promotion {
  const Promotion({
    required this.id,
    required this.headline,
    required this.subtitle,
    this.badge,
    this.accentHex,
    this.iconName,
    this.order = 0,
  });

  final String id;
  final String headline;
  final String subtitle;

  /// Optional pill label (e.g. "Limited", "New").
  final String? badge;

  /// Optional accent colour as a hex string (e.g. "#0EA5E9") driving the card
  /// gradient. The UI falls back to a default when absent.
  final String? accentHex;

  /// Optional icon identifier the UI maps to a glyph; falls back to a default.
  final String? iconName;

  /// Sort order within the carousel, ascending.
  final int order;
}
