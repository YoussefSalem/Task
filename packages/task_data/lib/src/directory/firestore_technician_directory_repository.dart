import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_domain/task_domain.dart';

import '../mappers/enum_codecs.dart';

/// Cloud Firestore implementation of [TechnicianDirectoryRepository].
///
/// Reads technician profiles from the shared `users` collection
/// (`role == 'technician'`), ordered by rating. Customers only read these
/// public-facing fields; the security rules permit reading technician docs.
class FirestoreTechnicianDirectoryRepository
    implements TechnicianDirectoryRepository {
  FirestoreTechnicianDirectoryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<TechnicianProfile>> watchTopRated({int limit = 10}) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'technician')
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((qs) => qs.docs.map(_fromDoc).toList());
  }

  TechnicianProfile _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
    final String name = <String>[
      (d['first_name'] as String?) ?? '',
      (d['last_name'] as String?) ?? '',
    ].where((String s) => s.isNotEmpty).join(' ').trim();
    return TechnicianProfile(
      id: doc.id,
      name: name,
      category: _categoryOrDefault(d['primary_category']),
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      jobsDone: (d['jobs_done'] as num?)?.toInt() ?? 0,
      tier: _tierOrDefault(d['tier']),
      photoUrl: (d['photo_url'] as String?)?.isNotEmpty == true
          ? d['photo_url'] as String
          : null,
    );
  }

  JobCategory _categoryOrDefault(Object? wire) {
    if (wire is! String) return JobCategory.plumbing;
    for (final JobCategory c in JobCategory.values) {
      if (c.name == wire) return c;
    }
    return JobCategory.plumbing;
  }

  TechnicianTier _tierOrDefault(Object? wire) {
    if (wire is! String) return TechnicianTier.bronze;
    try {
      return TechnicianTierCodec.fromWire(wire);
    } on FormatException {
      return TechnicianTier.bronze;
    }
  }
}
