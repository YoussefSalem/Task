import 'package:flutter/material.dart';

/// How the customer pays (design spec §2 payments).
enum PaymentMethod { cash, card, wallet, instapay }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash on delivery',
        PaymentMethod.card => 'Card',
        PaymentMethod.wallet => 'Vodafone Cash',
        PaymentMethod.instapay => 'InstaPay',
      };

  String get sub => switch (this) {
        PaymentMethod.cash => 'Pay the pro directly when the job is done',
        PaymentMethod.card => 'Visa, Mastercard, Meeza · via Paymob',
        PaymentMethod.wallet => 'Pay from your mobile wallet',
        PaymentMethod.instapay => 'Bank transfer, confirmed by our team',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_rounded,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.wallet => Icons.account_balance_wallet_rounded,
        PaymentMethod.instapay => Icons.account_balance_rounded,
      };
}

@immutable
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line,
    required this.icon,
  });

  final String id;
  final String label;
  final String line;
  final IconData icon;
}

const List<SavedAddress> kSavedAddresses = <SavedAddress>[
  SavedAddress(
    id: 'home',
    label: 'Home',
    line: '14 Road 9, Maadi · Floor 3, Apt 6',
    icon: Icons.home_rounded,
  ),
  SavedAddress(
    id: 'work',
    label: 'Work',
    line: 'Smart Village, Building B12 · Reception',
    icon: Icons.work_rounded,
  ),
];

/// Live stages used by the tracking screen (subset of the job state machine).
enum JobStage { searching, accepted, enRoute, inProgress, completed }

extension JobStageX on JobStage {
  String get title => switch (this) {
        JobStage.searching => 'Finding your pro',
        JobStage.accepted => 'Pro assigned',
        JobStage.enRoute => 'On the way',
        JobStage.inProgress => 'Work in progress',
        JobStage.completed => 'Job complete',
      };
}
