import 'package:meta/meta.dart';

/// The kind of movement a [WalletTransaction] represents. Drives the icon and
/// the sign convention in the ledger UI.
enum WalletTransactionType {
  /// Credit earned by referring another user.
  referral,

  /// Money returned to the wallet (e.g. a cancelled job).
  refund,

  /// A generic admin/promo credit not covered by the other types.
  credit,

  /// Money spent from the wallet (e.g. paying for a job).
  debit,
}

/// A user's wallet balance, stored at `users/{uid}/wallet/summary`.
///
/// The balance is held in **minor units** (piasters for EGP) to avoid floating
/// point drift; convert to major units only for display. Clients never write
/// this document — it is mutated by the backend/admin, so the customer app
/// treats it as read-only.
@immutable
class WalletSummary {
  const WalletSummary({
    required this.balanceMinor,
    this.currency = 'EGP',
    this.updatedAt,
  });

  /// An empty wallet — the honest default for a user who has never been
  /// credited. No fake starting balance.
  static const WalletSummary empty = WalletSummary(balanceMinor: 0);

  /// Balance in minor units (e.g. piasters). 12345 == 123.45 EGP.
  final int balanceMinor;

  /// ISO currency code. Single-currency (EGP) for now.
  final String currency;

  /// When the balance last changed, if known.
  final DateTime? updatedAt;

  /// Balance in major units, for display (123.45 for 12345 minor).
  double get balanceMajor => balanceMinor / 100;
}

/// One entry in a user's wallet ledger, stored under
/// `users/{uid}/wallet_transactions/{id}`, newest first.
///
/// [amountMinor] is **signed**: positive for credits, negative for debits. The
/// data layer is the single source of truth for the sign, so the UI never has
/// to infer direction from [type] alone.
@immutable
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final WalletTransactionType type;

  /// Signed amount in minor units. Positive == credit, negative == debit.
  final int amountMinor;

  /// Human-readable description of the movement.
  final String title;

  final DateTime createdAt;

  /// True when this entry added money to the wallet.
  bool get isCredit => amountMinor >= 0;

  /// Magnitude in major units, for display (always non-negative).
  double get amountMajorAbs => amountMinor.abs() / 100;
}
