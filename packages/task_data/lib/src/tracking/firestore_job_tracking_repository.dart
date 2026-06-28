import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_domain/task_domain.dart';

/// Cloud Firestore implementation of [JobTrackingRepository].
///
/// The assigned technician appends location samples to
/// `jobs/{jobId}/tracking/{id}`; the customer reads the most recent one.
class FirestoreJobTrackingRepository implements JobTrackingRepository {
  FirestoreJobTrackingRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<TrackingPoint?> watchLatest(String jobId) {
    return _db
        .collection('jobs')
        .doc(jobId)
        .collection('tracking')
        .orderBy('at', descending: true)
        .limit(1)
        .snapshots()
        .map((qs) => qs.docs.isEmpty ? null : _fromDoc(qs.docs.first));
  }

  TrackingPoint? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
    final num? lat = d['lat'] as num?;
    final num? lng = d['lng'] as num?;
    if (lat == null || lng == null) return null;
    return TrackingPoint(
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      at: (d['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      etaMinutes: (d['eta_minutes'] as num?)?.toInt(),
    );
  }
}
