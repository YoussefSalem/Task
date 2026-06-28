import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_domain/task_domain.dart';

import '../mappers/enum_codecs.dart';

/// Cloud Firestore implementation of [WalletRepository].
///
/// Layout:
///   - balance:      `users/{uid}/wallet/summary`
///   - ledger:       `users/{uid}/wallet_transactions/{id}` (newest first)
///
/// Read-only from the client: the balance and ledger are written by the backend
/// (referrals, refunds, admin credits) once the payments phase lands, and the
/// security rules deny client writes. A missing summary doc is treated as an
/// empty wallet rather than an error, so a brand-new user sees a clean 0.
class FirestoreWalletRepository implements WalletRepository {
  FirestoreWalletRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _summaryDoc(String uid) =>
      _db.collection('users').doc(uid).collection('wallet').doc('summary');

  CollectionReference<Map<String, dynamic>> _ledger(String uid) =>
      _db.collection('users').doc(uid).collection('wallet_transactions');

  @override
  Stream<WalletSummary> watchSummary(String uid) {
    return _summaryDoc(uid).snapshots().map((doc) {
      final Map<String, dynamic>? d = doc.data();
      if (d == null) return WalletSummary.empty;
      return WalletSummary(
        balanceMinor: (d['balance_minor'] as num?)?.toInt() ?? 0,
        currency: (d['currency'] as String?) ?? 'EGP',
        updatedAt: (d['updated_at'] as Timestamp?)?.toDate(),
      );
    });
  }

  @override
  Stream<List<WalletTransaction>> watchTransactions(String uid) {
    return _ledger(uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(_fromDoc).toList());
  }

  WalletTransaction _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
    return WalletTransaction(
      id: doc.id,
      type: _typeOrDefault(d['type']),
      amountMinor: (d['amount_minor'] as num?)?.toInt() ?? 0,
      title: (d['title'] as String?) ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  WalletTransactionType _typeOrDefault(Object? wire) {
    if (wire is! String) return WalletTransactionType.credit;
    try {
      return WalletTransactionTypeCodec.fromWire(wire);
    } on FormatException {
      return WalletTransactionType.credit;
    }
  }
}
