import '../entities/job_request.dart';
import '../entities/job_request_draft.dart';

/// The seam between the marketplace UI and its data source. The prototype binds
/// an in-memory mock; slice 4 swaps in a Firestore-backed implementation.
abstract interface class JobMarketplaceRepository {
  /// The customer's own posted jobs, newest first, re-emitting on every change.
  Stream<List<JobRequest>> watchMyJobs();

  /// Publishes a draft as a live [JobRequest] and returns the stored job.
  Future<JobRequest> publish(JobRequestDraft draft);

  /// Customer accepts a technician's current offer.
  Future<void> acceptOffer(String jobId, String offerId);

  /// Customer counters a technician's offer with [amount] EGP.
  Future<void> counterOffer(String jobId, String offerId, int amount);

  /// Customer cancels a posted job.
  Future<void> cancelJob(String jobId);
}
