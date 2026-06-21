import 'package:meta/meta.dart';

import 'job_enums.dart';

/// A single price point in a negotiation thread.
@immutable
class PriceProposal {
  const PriceProposal({required this.amount, required this.by, required this.at});

  final int amount; // EGP
  final ProposalAuthor by;
  final DateTime at;
}

/// One technician's negotiation thread for a job — the full price trail plus
/// the current status. There is exactly one [Offer] per interested technician.
@immutable
class Offer {
  const Offer({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    required this.rating,
    required this.jobsDone,
    required this.etaLabel,
    required this.proposals,
    required this.status,
  });

  final String id;
  final String technicianId;
  final String technicianName;
  final double rating;
  final int jobsDone;
  final String etaLabel;
  final List<PriceProposal> proposals;
  final OfferStatus status;

  /// The latest proposed amount in the thread (EGP). Never empty by construction.
  int get currentPrice => proposals.last.amount;

  Offer copyWith({List<PriceProposal>? proposals, OfferStatus? status}) => Offer(
        id: id,
        technicianId: technicianId,
        technicianName: technicianName,
        rating: rating,
        jobsDone: jobsDone,
        etaLabel: etaLabel,
        proposals: proposals ?? this.proposals,
        status: status ?? this.status,
      );
}
