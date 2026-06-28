import '../entities/tracking_point.dart';

/// Live technician-location feed for a single job, read from
/// `jobs/{jobId}/tracking`. Implemented in `task_data` over Cloud Firestore.
abstract interface class JobTrackingRepository {
  /// The most recent tracking point for [jobId], or null until the technician
  /// starts sharing location.
  Stream<TrackingPoint?> watchLatest(String jobId);
}
