import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

import '../jobs/jobs_providers.dart';

/// One row of the `job_assignments` join table: the link between a technician
/// and a customer's service request (job). This is the technician-side "database"
/// of engagements, queryable independently of the shared `jobs` collection.
@immutable
class JobAssignment {
  const JobAssignment({
    required this.jobId,
    required this.technicianId,
    required this.customerId,
    required this.technicianName,
    required this.title,
    required this.category,
    required this.agreedPrice,
    required this.status,
    required this.locationLabel,
    this.lat,
    this.lng,
    this.updatedAt,
  });

  final String jobId;
  final String technicianId;
  final String customerId;
  final String technicianName;
  final String title;
  final JobCategory category;
  final int agreedPrice;
  final JobStatus status;
  final String locationLabel;
  final double? lat;
  final double? lng;
  final DateTime? updatedAt;
}

/// Every job assignment linked to the signed-in technician, most-recent first.
final myAssignmentsProvider = StreamProvider<List<JobAssignment>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) {
    return Stream<List<JobAssignment>>.value(const <JobAssignment>[]);
  }
  return FirestorePaths.jobAssignmentsCollection(FirebaseFirestore.instance)
      .where('technician_id', isEqualTo: uid)
      .orderBy('updated_at', descending: true)
      .snapshots()
      .map((qs) => qs.docs.map(_fromDoc).toList());
});

/// Count of active (not completed/cancelled) assignments — a quick "currently
/// linked jobs" figure for the profile.
final activeAssignmentCountProvider = Provider<int>((ref) {
  final List<JobAssignment> all =
      ref.watch(myAssignmentsProvider).valueOrNull ?? const <JobAssignment>[];
  return all
      .where((a) =>
          a.status != JobStatus.completed && a.status != JobStatus.cancelled)
      .length;
});

JobAssignment _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
  JobCategory category = JobCategory.plumbing;
  final rawCat = d['category'];
  if (rawCat is String) {
    for (final JobCategory c in JobCategory.values) {
      if (c.name == rawCat || c.id == rawCat) category = c;
    }
  }
  JobStatus status = JobStatus.accepted;
  final rawStatus = d['status'];
  if (rawStatus is String) {
    for (final JobStatus s in JobStatus.values) {
      if (s.name == rawStatus || s.toWire() == rawStatus) status = s;
    }
  }
  return JobAssignment(
    jobId: (d['job_id'] as String?) ?? doc.id,
    technicianId: (d['technician_id'] as String?) ?? '',
    customerId: (d['customer_id'] as String?) ?? '',
    technicianName: (d['technician_name'] as String?) ?? '',
    title: (d['title'] as String?) ?? '',
    category: category,
    agreedPrice: (d['agreed_price'] as num?)?.toInt() ?? 0,
    status: status,
    locationLabel: (d['location_label'] as String?) ?? '',
    lat: (d['lat'] as num?)?.toDouble(),
    lng: (d['lng'] as num?)?.toDouble(),
    updatedAt: (d['updated_at'] as Timestamp?)?.toDate(),
  );
}
