import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_core/task_core.dart';
import 'package:task_domain/task_domain.dart';

import '../mappers/enum_codecs.dart';

/// Cloud Firestore implementation of [MessagingRepository].
///
/// Layout (one thread per job + technician):
/// ```
/// jobs/{jobId}/threads/{technicianId}            ← thread metadata
/// jobs/{jobId}/threads/{technicianId}/messages/{id}
/// ```
/// Read state is cursor-based (`last_read_customer` / `last_read_technician`)
/// and typing is a freshness stamp (`typing_customer_at` / `typing_technician_at`),
/// so neither costs a write per message.
class FirestoreMessagingRepository implements MessagingRepository {
  FirestoreMessagingRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _threadDoc(
          String jobId, String technicianId) =>
      _db.collection('jobs').doc(jobId).collection('threads').doc(technicianId);

  CollectionReference<Map<String, dynamic>> _messages(
          String jobId, String technicianId) =>
      _threadDoc(jobId, technicianId).collection('messages');

  @override
  Stream<List<Message>> watchMessages({
    required String jobId,
    required String technicianId,
  }) {
    return _messages(jobId, technicianId)
        .orderBy('created_at')
        .snapshots()
        .map((qs) => qs.docs.map(_messageFromDoc).toList());
  }

  @override
  Stream<ChatThread?> watchThread({
    required String jobId,
    required String technicianId,
  }) {
    return _threadDoc(jobId, technicianId).snapshots().map(
          (snap) => snap.exists ? _threadFromDoc(jobId, technicianId, snap) : null,
        );
  }

  @override
  Future<Result<void, Failure>> sendMessage({
    required String jobId,
    required String technicianId,
    required String technicianName,
    required String customerId,
    required String senderId,
    required SenderRole senderRole,
    required String text,
  }) async {
    final String body = text.trim();
    if (body.isEmpty) {
      return const Result.err(ValidationFailure('Message is empty'));
    }
    return _guard(() async {
      final WriteBatch batch = _db.batch();

      final DocumentReference<Map<String, dynamic>> msgRef =
          _messages(jobId, technicianId).doc();
      batch.set(msgRef, <String, dynamic>{
        'sender_id': senderId,
        'sender_role': senderRole.toWire(),
        'text': body,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Upsert thread metadata + bump the sender's own read cursor (you have, by
      // definition, read everything up to your own latest message).
      batch.set(_threadDoc(jobId, technicianId), <String, dynamic>{
        'job_id': jobId,
        'customer_id': customerId,
        'technician_id': technicianId,
        'technician_name': technicianName,
        'last_message': body,
        'last_message_at': FieldValue.serverTimestamp(),
        if (senderRole == SenderRole.customer)
          'last_read_customer': FieldValue.serverTimestamp()
        else
          'last_read_technician': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    });
  }

  @override
  Future<Result<void, Failure>> markRead({
    required String jobId,
    required String technicianId,
    required SenderRole role,
  }) {
    final String field =
        role == SenderRole.customer ? 'last_read_customer' : 'last_read_technician';
    return _guard(() => _threadDoc(jobId, technicianId).set(
          <String, dynamic>{field: FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        ));
  }

  @override
  Future<Result<void, Failure>> setTyping({
    required String jobId,
    required String technicianId,
    required SenderRole role,
  }) {
    final String field =
        role == SenderRole.customer ? 'typing_customer_at' : 'typing_technician_at';
    return _guard(() => _threadDoc(jobId, technicianId).set(
          <String, dynamic>{field: FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        ));
  }

  @override
  Stream<List<ChatThread>> watchThreadsForUser(String uid) {
    // Threads where this user is the customer.
    final customerQ = _db
        .collectionGroup('threads')
        .where('customer_id', isEqualTo: uid)
        .orderBy('last_message_at', descending: true);

    // Threads where this user is the technician (doc id == uid, but we match
    // on the stored field for the collectionGroup query).
    final techQ = _db
        .collectionGroup('threads')
        .where('technician_id', isEqualTo: uid)
        .orderBy('last_message_at', descending: true);

    // Merge both streams, deduplicate by (jobId, technicianId).
    return customerQ.snapshots().asyncExpand((customerSnap) {
      return techQ.snapshots().map((techSnap) {
        final Map<String, ChatThread> seen = {};
        for (final doc in customerSnap.docs) {
          final jobId = doc.reference.parent.parent?.id ?? '';
          final techId = doc.id;
          final key = '$jobId/$techId';
          if (!seen.containsKey(key)) {
            seen[key] = _threadFromDoc(jobId, techId, doc);
          }
        }
        for (final doc in techSnap.docs) {
          final jobId = doc.reference.parent.parent?.id ?? '';
          final techId = doc.id;
          final key = '$jobId/$techId';
          if (!seen.containsKey(key)) {
            seen[key] = _threadFromDoc(jobId, techId, doc);
          }
        }
        final threads = seen.values.toList();
        threads.sort((a, b) {
          final aTime = a.lastMessageAt ?? DateTime(2000);
          final bTime = b.lastMessageAt ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
        return threads;
      });
    });
  }

  // --- serialization -------------------------------------------------------

  Message _messageFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
    return Message(
      id: doc.id,
      senderId: (d['sender_id'] as String?) ?? '',
      senderRole: _roleOrDefault(d['sender_role']),
      text: (d['text'] as String?) ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ChatThread _threadFromDoc(
    String jobId,
    String technicianId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> d = doc.data() ?? const <String, dynamic>{};
    return ChatThread(
      jobId: jobId,
      customerId: (d['customer_id'] as String?) ?? '',
      technicianId: technicianId,
      technicianName: (d['technician_name'] as String?) ?? '',
      lastMessage: (d['last_message'] as String?) ?? '',
      lastMessageAt: (d['last_message_at'] as Timestamp?)?.toDate(),
      lastReadByCustomer: (d['last_read_customer'] as Timestamp?)?.toDate(),
      lastReadByTechnician: (d['last_read_technician'] as Timestamp?)?.toDate(),
      typingCustomerAt: (d['typing_customer_at'] as Timestamp?)?.toDate(),
      typingTechnicianAt: (d['typing_technician_at'] as Timestamp?)?.toDate(),
    );
  }

  SenderRole _roleOrDefault(Object? wire) {
    if (wire is! String) return SenderRole.customer;
    try {
      return SenderRoleCodec.fromWire(wire);
    } on FormatException {
      return SenderRole.customer;
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
