// packages/task_domain/test/job_request_test.dart
import 'package:task_domain/task_domain.dart';
import 'package:test/test.dart';

JobRequest _job({List<Offer> offers = const <Offer>[]}) => JobRequest(
      id: 'j1',
      category: JobCategory.electrical,
      title: 'Flickering living-room lights',
      description: 'Lights flicker when the AC turns on.',
      fixedPrice: 400,
      urgency: Urgency.soon,
      propertyType: PropertyType.apartment,
      locationLabel: 'Maadi, Cairo',
      status: JobStatus.biddingActive,
      offers: offers,
      createdAt: DateTime(2026),
    );

void main() {
  test('settledPrice falls back to fixedPrice with no accepted offer', () {
    expect(_job().settledPrice, 400);
  });

  test('settledPrice uses the accepted offer current price', () {
    final Offer accepted = Offer(
      id: 'o1', technicianId: 't1', technicianName: 'K', rating: 4.9,
      jobsDone: 10, etaLabel: '40 min', status: OfferStatus.accepted,
      proposals: <PriceProposal>[
        PriceProposal(amount: 550, by: ProposalAuthor.technician, at: DateTime(2026)),
      ],
    );
    final JobRequest job = _job(offers: <Offer>[accepted]);
    expect(job.acceptedOffer, accepted);
    expect(job.settledPrice, 550);
  });
}
