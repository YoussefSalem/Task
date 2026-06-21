// apps/customer/test/mock_job_marketplace_repository_test.dart
import 'package:customer/features/marketplace/mock_job_marketplace_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_domain/task_domain.dart';

void main() {
  test('publish adds a job to watchMyJobs newest-first', () async {
    final MockJobMarketplaceRepository repo = MockJobMarketplaceRepository();
    final int before = (await repo.watchMyJobs().first).length;

    final JobRequest job = await repo.publish(const JobRequestDraft().copyWith(
      category: JobCategory.electrical,
      title: 'Flickering lights',
      fixedPrice: 400,
    ));

    final List<JobRequest> jobs = await repo.watchMyJobs().first;
    expect(jobs.length, before + 1);
    expect(jobs.first.id, job.id);
    expect(jobs.first.fixedPrice, 400);
  });

  test('acceptOffer marks the offer accepted and fixes settledPrice', () async {
    final MockJobMarketplaceRepository repo = MockJobMarketplaceRepository();
    final JobRequest seeded =
        (await repo.watchMyJobs().first).firstWhere((j) => j.offers.isNotEmpty);
    final Offer target = seeded.offers.first;

    await repo.acceptOffer(seeded.id, target.id);

    final JobRequest updated =
        (await repo.watchMyJobs().first).firstWhere((j) => j.id == seeded.id);
    expect(updated.acceptedOffer?.id, target.id);
    expect(updated.settledPrice, target.currentPrice);
  });

  test('counterOffer appends a customer proposal and sets countered', () async {
    final MockJobMarketplaceRepository repo = MockJobMarketplaceRepository();
    final JobRequest seeded =
        (await repo.watchMyJobs().first).firstWhere((j) => j.offers.isNotEmpty);
    final Offer target = seeded.offers.first;

    await repo.counterOffer(seeded.id, target.id, 480);

    final Offer updated = (await repo.watchMyJobs().first)
        .firstWhere((j) => j.id == seeded.id)
        .offers
        .firstWhere((o) => o.id == target.id);
    expect(updated.currentPrice, 480);
    expect(updated.proposals.last.by, ProposalAuthor.customer);
    expect(updated.status, OfferStatus.countered);
  });
}
