import 'package:task_core/task_core.dart';

import '../entities/complaint.dart';

/// Complaints filed against a job, stored under
/// `jobs/{jobId}/complaints/{id}`. Implemented in `task_data` over Cloud
/// Firestore.
abstract interface class ComplaintRepository {
  /// Live list of complaints for a single job, newest first.
  Stream<List<Complaint>> watchForJob(String jobId);

  /// File a new complaint.
  Future<Result<Complaint, Failure>> submit(ComplaintDraft draft);
}
