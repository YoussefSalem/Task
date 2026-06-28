import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

/// Firestore live-location feed for jobs in progress.
final jobTrackingRepositoryProvider = Provider<JobTrackingRepository>(
  (ref) => FirestoreJobTrackingRepository(),
);

/// The latest tracking point for a job, or null until the technician shares
/// location. Keyed by job id.
final jobTrackingProvider =
    StreamProvider.family<TrackingPoint?, String>((ref, jobId) {
  return ref.watch(jobTrackingRepositoryProvider).watchLatest(jobId);
});
