// apps/customer/lib/features/marketplace/marketplace_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_domain/task_domain.dart';

import '../auth/auth_controller.dart';
import 'firestore_job_marketplace_repository.dart';

/// Firestore-backed jobs, scoped to the signed-in customer so their posted jobs
/// pull on any device. Falls back to an empty repo when signed out.
final jobMarketplaceRepositoryProvider = Provider<JobMarketplaceRepository>(
  (ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const EmptyJobMarketplaceRepository();
    return FirestoreJobMarketplaceRepository(user.uid);
  },
);

final myJobsProvider = StreamProvider<List<JobRequest>>(
  (ref) => ref.watch(jobMarketplaceRepositoryProvider).watchMyJobs(),
);

/// Snapshot of an in-progress search, surfaced on the Home screen so the user
/// can jump back into it. `offersReady` flips true once the radar finds offers.
class ActiveSearch {
  const ActiveSearch({required this.jobId, this.offersReady = false});

  final String jobId;
  final bool offersReady;

  ActiveSearch copyWith({bool? offersReady}) => ActiveSearch(
        jobId: jobId,
        offersReady: offersReady ?? this.offersReady,
      );
}

/// The current active search, or null when none is running. Set when a job is
/// published / the radar opens; cleared when the user cancels or hires.
final activeSearchProvider = StateProvider<ActiveSearch?>((ref) => null);

/// The in-progress draft the customer assembles before publishing.
class JobDraftController extends Notifier<JobRequestDraft> {
  @override
  JobRequestDraft build() => const JobRequestDraft();

  void startCategory(JobCategory category) =>
      state = JobRequestDraft(category: category);
  void setTitle(String title) => state = state.copyWith(title: title);
  void setDescription(String d) => state = state.copyWith(description: d);
  void setPrice(int price) => state = state.copyWith(fixedPrice: price);
  void setPhotos(List<String> photos) => state = state.copyWith(photos: photos);
  void addPhoto(String path) =>
      state = state.copyWith(photos: [...state.photos, path]);
  void removePhoto(int index) {
    final updated = [...state.photos]..removeAt(index);
    state = state.copyWith(photos: updated);
  }

  void reset() => state = const JobRequestDraft();
}

final jobDraftProvider =
    NotifierProvider<JobDraftController, JobRequestDraft>(JobDraftController.new);
