import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_core/task_core.dart';
import 'package:task_domain/task_domain.dart';

import '../mappers/enum_codecs.dart';

/// Cloud Firestore implementation of [NotificationRepository].
///
/// Feed layout: `users/{uid}/notifications/{id}`, newest first. There is no
/// server fan-out — the acting client calls [notify] to write into the
/// recipient's feed directly.
class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _feed(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  @override
  Stream<List<AppNotification>> watchFeed(String uid) {
    return _feed(uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(_fromDoc).toList());
  }

  @override
  Stream<int> watchUnreadCount(String uid) {
    return _feed(uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((qs) => qs.docs.length);
  }

  @override
  Future<Result<void, Failure>> notify({
    required String recipientUid,
    required NotificationDraft draft,
  }) {
    return _guard(() => _feed(recipientUid).add(<String, dynamic>{
          'type': draft.type.toWire(),
          'title': draft.title,
          'body': draft.body,
          'actor_id': draft.actorId,
          'job_id': draft.jobId,
          'thread_id': draft.threadId,
          'read': false,
          'created_at': FieldValue.serverTimestamp(),
        }));
  }

  @override
  Future<Result<void, Failure>> markRead({
    required String uid,
    required String notificationId,
  }) {
    return _guard(() => _feed(uid).doc(notificationId).update(
          <String, dynamic>{'read': true},
        ));
  }

  @override
  Future<Result<void, Failure>> markAllRead(String uid) {
    return _guard(() async {
      final QuerySnapshot<Map<String, dynamic>> unread =
          await _feed(uid).where('read', isEqualTo: false).get();
      if (unread.docs.isEmpty) return;
      final WriteBatch batch = _db.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in unread.docs) {
        batch.update(doc.reference, <String, dynamic>{'read': true});
      }
      await batch.commit();
    });
  }

  // --- serialization -------------------------------------------------------

  AppNotification _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      type: _typeOrDefault(d['type']),
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actorId: d['actor_id'] as String?,
      jobId: d['job_id'] as String?,
      threadId: d['thread_id'] as String?,
      read: (d['read'] as bool?) ?? false,
    );
  }

  NotificationType _typeOrDefault(Object? wire) {
    if (wire is! String) return NotificationType.jobStatus;
    try {
      return NotificationTypeCodec.fromWire(wire);
    } on FormatException {
      return NotificationType.jobStatus;
    }
  }

  Future<Result<void, Failure>> _guard(Future<void> Function() op) async {
    try {
      await op();
      return const Result.ok(null);
    } on FirebaseException catch (e, st) {
      if (e.code == 'permission-denied') {
        return Result.err(
            PermissionFailure(e.message ?? e.code, cause: e, stackTrace: st));
      }
      return Result.err(
          NetworkFailure(e.message ?? e.code, cause: e, stackTrace: st));
    } catch (e, st) {
      return Result.err(UnexpectedFailure('$e', cause: e, stackTrace: st));
    }
  }
}
