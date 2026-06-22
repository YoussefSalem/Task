import 'package:customer/l10n/app_localizations.dart';
// apps/customer/lib/features/marketplace/mock_job_marketplace_repository.dart
import 'dart:async';

import 'package:task_domain/task_domain.dart';

/// In-memory [JobMarketplaceRepository] for the prototype. Holds jobs in a list
/// and re-emits the whole list through a broadcast stream on every mutation.
class MockJobMarketplaceRepository implements JobMarketplaceRepository {
  MockJobMarketplaceRepository() {
    _jobs = _seed();
    _emit();
  }

  late List<JobRequest> _jobs;
  final StreamController<List<JobRequest>> _controller =
      StreamController<List<JobRequest>>.broadcast();
  int _counter = 0;

  void _emit() => _controller.add(List<JobRequest>.unmodifiable(_jobs));

  @override
  Stream<List<JobRequest>> watchMyJobs() async* {
    yield List<JobRequest>.unmodifiable(_jobs);
    yield* _controller.stream;
  }

  @override
  Future<JobRequest> publish(JobRequestDraft draft) async {
    final JobRequest job = JobRequest(
      id: 'JOB-${(_counter++).toString().padLeft(4, '0')}',
      category: draft.category ?? JobCategory.plumbing,
      title: draft.title,
      description: draft.description,
      fixedPrice: draft.fixedPrice,
      urgency: draft.urgency,
      propertyType: draft.propertyType,
      floor: draft.floor,
      parking: draft.parking,
      photos: draft.photos,
      locationLabel:
          draft.locationLabel.isEmpty ? 'Maadi, Cairo' : draft.locationLabel,
      notes: draft.notes,
      status: JobStatus.biddingActive,
      offers: const <Offer>[],
      createdAt: DateTime.now(),
    );
    _jobs = <JobRequest>[job, ..._jobs];
    _emit();
    return job;
  }

  @override
  Future<void> acceptOffer(String jobId, String offerId) async {
    _mutateJob(jobId, (JobRequest job) {
      final List<Offer> offers = job.offers
          .map((Offer o) => o.copyWith(
                status: o.id == offerId
                    ? OfferStatus.accepted
                    : OfferStatus.declined,
              ))
          .toList();
      return job.copyWith(status: JobStatus.accepted, offers: offers);
    });
  }

  @override
  Future<void> counterOffer(String jobId, String offerId, int amount) async {
    _mutateJob(jobId, (JobRequest job) {
      final List<Offer> offers = job.offers.map((Offer o) {
        if (o.id != offerId) return o;
        return o.copyWith(
          proposals: <PriceProposal>[
            ...o.proposals,
            PriceProposal(
                amount: amount,
                by: ProposalAuthor.customer,
                at: DateTime.now()),
          ],
          status: OfferStatus.countered,
        );
      }).toList();
      return job.copyWith(offers: offers);
    });
  }

  @override
  Future<void> cancelJob(String jobId) async {
    _mutateJob(jobId, (JobRequest job) => job.copyWith(status: JobStatus.cancelled));
  }

  void _mutateJob(String jobId, JobRequest Function(JobRequest) update) {
    _jobs = _jobs
        .map((JobRequest j) => j.id == jobId ? update(j) : j)
        .toList();
    _emit();
  }

  List<JobRequest> _seed() {
    final DateTime now = DateTime.now();
    PriceProposal tech(int amount) =>
        PriceProposal(amount: amount, by: ProposalAuthor.technician, at: now);
    return <JobRequest>[
      JobRequest(
        id: 'JOB-SEED1',
        category: JobCategory.plumbing,
        title: 'Leaking kitchen sink',
        description: 'Steady drip under the sink, water pooling in the cabinet.',
        fixedPrice: 180,
        urgency: Urgency.soon,
        propertyType: PropertyType.apartment,
        locationLabel: 'Maadi, Cairo',
        status: JobStatus.biddingActive,
        createdAt: now,
        offers: <Offer>[
          Offer(
            id: 'OF-1', technicianId: 'T-1', technicianName: 'Khaled Mansour',
            rating: 4.9, jobsDone: 1284, etaLabel: 'Can start in 40 min',
            status: OfferStatus.pending, proposals: <PriceProposal>[tech(165)],
          ),
          Offer(
            id: 'OF-2', technicianId: 'T-2', technicianName: 'Sayed Abdel-Rahman',
            rating: 4.7, jobsDone: 612, etaLabel: 'Available this evening',
            status: OfferStatus.pending, proposals: <PriceProposal>[tech(140)],
          ),
          Offer(
            id: 'OF-3', technicianId: 'T-3', technicianName: 'Mostafa Eid',
            rating: 4.8, jobsDone: 903, etaLabel: 'Can start in 25 min',
            status: OfferStatus.pending, proposals: <PriceProposal>[tech(190)],
          ),
        ],
      ),
      JobRequest(
        id: 'JOB-SEED2',
        category: JobCategory.ac,
        title: 'AC not cooling',
        description: 'Split unit runs but blows warm air.',
        fixedPrice: 240,
        urgency: Urgency.urgent,
        propertyType: PropertyType.apartment,
        locationLabel: 'Nasr City, Cairo',
        status: JobStatus.inProgress,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      JobRequest(
        id: 'JOB-SEED3',
        category: JobCategory.electrical,
        title: 'Replace tripping breaker',
        description: 'Main breaker trips when the heater runs.',
        fixedPrice: 150,
        urgency: Urgency.flexible,
        propertyType: PropertyType.villa,
        locationLabel: 'Sheikh Zayed, Giza',
        status: JobStatus.completed,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
