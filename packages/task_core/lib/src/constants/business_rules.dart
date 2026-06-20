/// Canonical business-rule constants extracted verbatim from the PRD.
///
/// Centralised so the same numbers drive the Flutter clients AND are referenced
/// by the Cloud Functions contract. Anything configurable per-zone at runtime
/// (base price, commission override) is NOT hard-coded here — only the global
/// defaults and structural invariants the PRD fixes.
abstract final class BusinessRules {
  const BusinessRules._();

  // --- ASAP dispatch cascade (PRD §3.1) ---
  /// Progressive search radii in kilometres: 3 → 6 → … → 20 km.
  static const List<int> dispatchRadiiKm = <int>[3, 6, 9, 12, 15, 20];

  /// Delay between dispatch tiers before expanding the radius.
  static const Duration dispatchTierDelay = Duration(seconds: 30);

  // --- Sealed-bid quoting (PRD §3.2) ---
  /// Maximum quotes accepted before new bids are locked.
  static const int maxQuotesPerJob = 5;

  // --- Scope-creep thresholds (PRD §3.3), as fractions of base price ---
  static const double scopeCustomerOtpThreshold = 0.30; // < 30% → customer OTP
  static const double scopeAdminOverrideThreshold = 0.50; // 30–50% → admin + OTP
  // > 50% → mandatory admin review + customer re-authorisation.

  // --- Wallet & COD (PRD §4.1) ---
  /// Flat platform fee applied to every job.
  static const double platformFeeRate = 0.20;

  /// Persistent UI warning at or below this balance (EGP).
  static const int walletWarningThreshold = -300;

  /// Online toggle hard-locked at or below this balance (EGP).
  static const int walletHardLockThreshold = -500;

  // --- Geolocation telemetry (PRD §5.2) ---
  static const Duration geoEnRouteWriteInterval = Duration(seconds: 10);
  static const int geoIdleDistanceMeters = 20;
  static const Duration geoIdleWriteInterval = Duration(minutes: 2);

  // --- Media pipeline (PRD §5.1) ---
  static const int imageMaxDimensionPx = 1080;
  static const int imageJpegQuality = 80;
  static const int imageMaxBytes = 800 * 1024; // 800 KB
  static const int jobBeforeImagesMin = 1;
  static const int jobAfterImagesMin = 1;
  static const int jobImagesMaxTotal = 10;

  // --- Offline retention (PRD §5.1) ---
  static const Duration offlineQueueTtl = Duration(days: 7);

  // --- Chat retention (PRD §6.2) ---
  static const Duration chatActiveRetention = Duration(days: 30);
  static const Duration chatArchiveRetention = Duration(days: 365);
}
