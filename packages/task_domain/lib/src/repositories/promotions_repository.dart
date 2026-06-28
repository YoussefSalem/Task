import '../entities/promotion.dart';

/// Read-only feed of active home-screen promotions, ordered for display.
/// Implemented in `task_data` over the `promotions` collection.
abstract interface class PromotionsRepository {
  /// Live list of active promotions, ascending by order. Empty when none are
  /// configured — the UI then hides the carousel rather than showing filler.
  Stream<List<Promotion>> watchActive();
}
