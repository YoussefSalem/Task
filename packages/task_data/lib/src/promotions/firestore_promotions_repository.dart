import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_domain/task_domain.dart';

/// Cloud Firestore implementation of [PromotionsRepository], reading the
/// admin-managed top-level `promotions` collection.
class FirestorePromotionsRepository implements PromotionsRepository {
  FirestorePromotionsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<Promotion>> watchActive() {
    return _db
        .collection('promotions')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((qs) => qs.docs.map(_fromDoc).toList());
  }

  Promotion _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
    return Promotion(
      id: doc.id,
      headline: (d['headline'] as String?) ?? '',
      subtitle: (d['subtitle'] as String?) ?? '',
      badge: (d['badge'] as String?)?.isNotEmpty == true
          ? d['badge'] as String
          : null,
      accentHex: (d['accent_hex'] as String?)?.isNotEmpty == true
          ? d['accent_hex'] as String
          : null,
      iconName: (d['icon_name'] as String?)?.isNotEmpty == true
          ? d['icon_name'] as String
          : null,
      order: (d['order'] as num?)?.toInt() ?? 0,
    );
  }
}
