// apps/customer/lib/features/marketplace/marketplace_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_domain/task_domain.dart';

import 'mock_job_marketplace_repository.dart';

final jobMarketplaceRepositoryProvider = Provider<JobMarketplaceRepository>(
  (ref) => MockJobMarketplaceRepository(),
);

final myJobsProvider = StreamProvider<List<JobRequest>>(
  (ref) => ref.watch(jobMarketplaceRepositoryProvider).watchMyJobs(),
);

/// The in-progress draft the customer assembles before publishing.
class JobDraftController extends Notifier<JobRequestDraft> {
  @override
  JobRequestDraft build() => const JobRequestDraft();

  void startCategory(JobCategory category) =>
      state = JobRequestDraft(category: category);
  void setTitle(String title) => state = state.copyWith(title: title);
  void setDescription(String d) => state = state.copyWith(description: d);
  void setPrice(int price) => state = state.copyWith(fixedPrice: price);
  void reset() => state = const JobRequestDraft();
}

final jobDraftProvider =
    NotifierProvider<JobDraftController, JobRequestDraft>(JobDraftController.new);
