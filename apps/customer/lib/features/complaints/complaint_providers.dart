import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

/// Real Firestore-backed complaint repository (jobs/{jobId}/complaints).
/// No demo/mock split needed here since this is a brand-new, always-real
/// feature - there is no legacy mock implementation to fall back to.
final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  return FirestoreComplaintRepository();
});

/// Live complaints filed against a specific job, newest first.
final jobComplaintsProvider =
    StreamProvider.autoDispose.family<List<Complaint>, String>((ref, jobId) {
  return ref.watch(complaintRepositoryProvider).watchForJob(jobId);
});
