import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

import '../jobs/jobs_providers.dart';

/// Reviews customers have left for the signed-in pro, newest first.
///
/// Uses a `collectionGroup('reviews')` query filtered by `technician_id`, which
/// spans every job's `reviews` subcollection. Needs the recursive-wildcard rule
/// and the composite index (`technician_id` + `created_at`).
final myReviewsProvider = StreamProvider<List<Review>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream<List<Review>>.value(const <Review>[]);
  return FirebaseFirestore.instance
      .collectionGroup(FirestorePaths.reviews)
      .where('technician_id', isEqualTo: uid)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((qs) => qs.docs.map(_reviewFromDoc).toList());
});

/// Summary of the pro's rating: average and count, derived from [myReviewsProvider].
final ratingSummaryProvider = Provider<({double average, int count})>((ref) {
  final List<Review> reviews =
      ref.watch(myReviewsProvider).valueOrNull ?? const <Review>[];
  if (reviews.isEmpty) return (average: 0.0, count: 0);
  final int total = reviews.fold<int>(0, (s, r) => s + r.rating);
  return (average: total / reviews.length, count: reviews.length);
});

Review _reviewFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
  return Review(
    rating: (d['rating'] as num?)?.toInt() ?? 0,
    tags: (d['tags'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
    note: (d['note'] as String?) ?? '',
    reviewerId: (d['reviewer_id'] as String?) ?? '',
    technicianId: (d['technician_id'] as String?) ?? '',
    createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}
