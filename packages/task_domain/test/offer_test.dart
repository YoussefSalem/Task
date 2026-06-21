// packages/task_domain/test/offer_test.dart
import 'package:task_domain/task_domain.dart';
import 'package:test/test.dart';

Offer _offer(List<int> amounts, {OfferStatus status = OfferStatus.pending}) =>
    Offer(
      id: 'o1',
      technicianId: 't1',
      technicianName: 'Khaled',
      rating: 4.9,
      jobsDone: 1284,
      etaLabel: '40 min',
      status: status,
      proposals: <PriceProposal>[
        for (final int a in amounts)
          PriceProposal(amount: a, by: ProposalAuthor.technician, at: DateTime(2026)),
      ],
    );

void main() {
  test('currentPrice reflects the last proposal in the thread', () {
    expect(_offer(<int>[550, 480, 500]).currentPrice, 500);
  });

  test('copyWith appends a proposal and flips status', () {
    final Offer base = _offer(<int>[550]);
    final Offer countered = base.copyWith(
      proposals: <PriceProposal>[
        ...base.proposals,
        PriceProposal(amount: 480, by: ProposalAuthor.customer, at: DateTime(2026)),
      ],
      status: OfferStatus.countered,
    );
    expect(countered.currentPrice, 480);
    expect(countered.status, OfferStatus.countered);
    expect(base.currentPrice, 550); // original unchanged
  });
}
