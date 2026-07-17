import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

import '../auth/auth_controller.dart';
import 'technician_jobs_repository.dart';

/// Shared Firestore live-location repository (read + technician publish).
final jobTrackingRepositoryProvider = Provider<JobTrackingRepository>(
  (ref) => FirestoreJobTrackingRepository(),
);

/// The latest tracking point for a job, or null until the pro shares location.
final jobTrackingProvider =
    StreamProvider.family<TrackingPoint?, String>((ref, jobId) {
  return ref.watch(jobTrackingRepositoryProvider).watchLatest(jobId);
});

/// The signed-in technician's uid, or null when signed out.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.uid,
);

/// Firestore-backed jobs view for the signed-in technician, or null when signed
/// out (the screens render an empty/loading state in that window).
final technicianJobsRepositoryProvider =
    Provider<TechnicianJobsRepository?>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return TechnicianJobsRepository(uid);
});

/// The open market — every job still taking bids.
final openJobsProvider = StreamProvider<List<JobRequest>>((ref) {
  final repo = ref.watch(technicianJobsRepositoryProvider);
  if (repo == null) return Stream<List<JobRequest>>.value(const <JobRequest>[]);
  return repo.watchOpenJobs();
});

/// Fallback freshness for an ASAP request that has no live heartbeat (customer
/// posted then left the waiting screen). Short by design — the real-time
/// `searchingUntil` heartbeat is the primary "actively looking" signal; this
/// only keeps a just-posted job visible briefly if the heartbeat lapses. Set to
/// [Duration.zero] to show ONLY customers actively on a waiting screen.
const Duration kNearbyAsapFreshness = Duration(hours: 2);

/// Grace period a scheduled visit lingers past its slot before dropping off.
const Duration kScheduledGrace = Duration(hours: 2);

/// "Customers actively looking near you" — the open market narrowed to live,
/// relevant demand. A job counts as live when the customer is actively looking
/// *now* (fresh `searchingUntil` heartbeat) OR, as a fallback, it's still within
/// its freshness window. Drops this pro's own postings and jobs they've already
/// withdrawn from or been declined on. Actively-searching jobs sort to the top.
/// Empty when no customer is looking, so the feed never shows phantom demand.
final nearbyJobsProvider = Provider<List<JobRequest>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  final List<JobRequest> open =
      ref.watch(openJobsProvider).valueOrNull ?? const <JobRequest>[];
  final DateTime now = DateTime.now();

  bool withinFreshness(JobRequest j) {
    if (j.timing == JobTiming.scheduled) {
      final DateTime? at = j.scheduledAt;
      return at == null || !now.isAfter(at.add(kScheduledGrace));
    }
    return now.difference(j.createdAt) <= kNearbyAsapFreshness;
  }

  final List<JobRequest> live = open.where((JobRequest j) {
    if (uid != null && j.customerId == uid) return false; // never our own post
    final Offer? mine = uid == null
        ? null
        : j.offers.where((o) => o.technicianId == uid).firstOrNull;
    if (mine != null &&
        (mine.status == OfferStatus.withdrawn ||
            mine.status == OfferStatus.declined)) {
      return false; // we passed on it or lost it
    }
    // Live if the customer is actively searching now, or still fresh.
    return j.isSearchingAt(now) || withinFreshness(j);
  }).toList();

  // Actively-searching customers first (hottest leads), then newest.
  live.sort((JobRequest a, JobRequest b) {
    final bool sa = a.isSearchingAt(now);
    final bool sb = b.isSearchingAt(now);
    if (sa != sb) return sa ? -1 : 1;
    return b.createdAt.compareTo(a.createdAt);
  });
  return live;
});

/// The subset of the open market this pro has an in-flight bid on.
final myBidsProvider = Provider<List<JobRequest>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  final List<JobRequest> open =
      ref.watch(openJobsProvider).valueOrNull ?? const <JobRequest>[];
  if (uid == null) return const <JobRequest>[];
  return open.where((job) {
    final Offer? mine =
        job.offers.where((o) => o.technicianId == uid).firstOrNull;
    return mine != null &&
        (mine.status == OfferStatus.pending ||
            mine.status == OfferStatus.countered);
  }).toList();
});

/// Jobs that have left the open market and involve this pro (hired + history).
final myEngagementsProvider = StreamProvider<List<JobRequest>>((ref) {
  final repo = ref.watch(technicianJobsRepositoryProvider);
  if (repo == null) return Stream<List<JobRequest>>.value(const <JobRequest>[]);
  return repo.watchMyEngagements();
});

const Set<JobStatus> kActiveStatuses = <JobStatus>{
  JobStatus.accepted,
  JobStatus.enRoute,
  JobStatus.inProgress,
  JobStatus.pausedForApproval,
};

/// Jobs this pro is currently hired on (accepted → in progress).
final myActiveJobsProvider = Provider<List<JobRequest>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  final List<JobRequest> jobs =
      ref.watch(myEngagementsProvider).valueOrNull ?? const <JobRequest>[];
  if (uid == null) return const <JobRequest>[];
  return jobs
      .where((j) =>
          kActiveStatuses.contains(j.status) &&
          j.acceptedOffer?.technicianId == uid)
      .toList();
});

/// The single most recent active job, or null — drives the dashboard hero card.
final primaryActiveJobProvider = Provider<JobRequest?>((ref) {
  return ref.watch(myActiveJobsProvider).firstOrNull;
});

/// Upcoming scheduled jobs this pro is hired on, soonest first — the agenda.
final myScheduledJobsProvider = Provider<List<JobRequest>>((ref) {
  final List<JobRequest> active = ref.watch(myActiveJobsProvider);
  final List<JobRequest> scheduled = active
      .where((j) => j.timing == JobTiming.scheduled && j.scheduledAt != null)
      .toList()
    ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
  return scheduled;
});

/// Finished or cancelled jobs this pro worked — the earnings/history feed.
final myHistoryProvider = Provider<List<JobRequest>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  final List<JobRequest> jobs =
      ref.watch(myEngagementsProvider).valueOrNull ?? const <JobRequest>[];
  if (uid == null) return const <JobRequest>[];
  return jobs
      .where((j) =>
          j.status == JobStatus.completed &&
          j.acceptedOffer?.technicianId == uid)
      .toList();
});

/// A single job by id, sourced from whichever live stream currently holds it, so
/// the detail/active screens update in real time. Null if not currently loaded.
final jobByIdProvider = Provider.family<JobRequest?, String>((ref, jobId) {
  final List<JobRequest> open =
      ref.watch(openJobsProvider).valueOrNull ?? const <JobRequest>[];
  final List<JobRequest> mine =
      ref.watch(myEngagementsProvider).valueOrNull ?? const <JobRequest>[];
  for (final JobRequest j in <JobRequest>[...open, ...mine]) {
    if (j.id == jobId) return j;
  }
  return null;
});
