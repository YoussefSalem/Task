import '../entities/wallet.dart';

/// Read-only view of a single user's wallet.
///
/// The customer app never mutates the balance or writes ledger entries — those
/// are produced by the backend (referrals, refunds, admin credits) once the
/// payments phase lands. This interface therefore exposes only live reads.
/// Implemented in `task_data` over Cloud Firestore.
abstract interface class WalletRepository {
  /// Live balance for [uid]. Emits [WalletSummary.empty] until the wallet doc
  /// exists, so a brand-new user sees a clean 0 rather than an error.
  Stream<WalletSummary> watchSummary(String uid);

  /// Live ledger for [uid], newest first. Empty until the user is credited.
  Stream<List<WalletTransaction>> watchTransactions(String uid);
}
