import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the customer pays — all in-app only. Cash / off-platform payments are
/// not permitted; this enum intentionally excludes them.
enum PaymentMethod { card, wallet, instapay }

extension PaymentMethodX on PaymentMethod {
  String label(AppLocalizations l) => switch (this) {
        PaymentMethod.card => l.payCard,
        PaymentMethod.wallet => l.payWallet,
        PaymentMethod.instapay => l.payInstapay,
      };

  String sub(AppLocalizations l) => switch (this) {
        PaymentMethod.card => l.payCardSub,
        PaymentMethod.wallet => l.payWalletSub,
        PaymentMethod.instapay => l.payInstapaySub,
      };

  IconData get icon => switch (this) {
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.wallet => Icons.account_balance_wallet_rounded,
        PaymentMethod.instapay => Icons.account_balance_rounded,
      };
}

/// Icon families a saved address can use. Stored as a string in Firestore and
/// mapped back to an [IconData] for display, since [IconData] isn't directly
/// serializable.
enum AddressIconKind { home, work, other, friend, gym, school }

extension AddressIconKindX on AddressIconKind {
  IconData get icon => switch (this) {
        AddressIconKind.home => Icons.home_rounded,
        AddressIconKind.work => Icons.work_rounded,
        AddressIconKind.other => Icons.location_on_rounded,
        AddressIconKind.friend => Icons.person_rounded,
        AddressIconKind.gym => Icons.fitness_center_rounded,
        AddressIconKind.school => Icons.school_rounded,
      };

  static AddressIconKind fromName(Object? name) {
    for (final AddressIconKind k in AddressIconKind.values) {
      if (k.name == name) return k;
    }
    return AddressIconKind.other;
  }
}

@immutable
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line,
    this.iconKind = AddressIconKind.other,
    this.lat,
    this.lng,
  });

  final String id;
  final String label;
  final String line;
  final AddressIconKind iconKind;
  final double? lat;
  final double? lng;

  IconData get icon => iconKind.icon;
}

/// Simulated Task wallet balance in EGP.
/// In production this would come from a Firestore user-doc stream.
final walletCreditProvider = StateProvider<int>((ref) => 125);

/// Live stages used by the tracking screen (subset of the job state machine).
enum JobStage { searching, accepted, enRoute, inProgress, completed }

extension JobStageX on JobStage {
  String title(AppLocalizations l) => switch (this) {
        JobStage.searching => l.stageSearching,
        JobStage.accepted => l.stageAccepted,
        JobStage.enRoute => l.stageEnRoute,
        JobStage.inProgress => l.stageInProgress,
        JobStage.completed => l.stageCompleted,
      };
}
