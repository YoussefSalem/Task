import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_core/task_core.dart';
import 'package:task_domain/task_domain.dart';

import '../firestore_paths.dart';
import '../mappers/enum_codecs.dart';

/// Cloud Firestore implementation of [ComplaintRepository].
///
/// Layout: `jobs/{jobId}/complaints/{id}` - a subcollection of the job, same
/// convention as reviews/tracking/threads, so it's queryable per-job from the
/// app and via `collectionGroup('complaints')` from the Admin Dashboard.
class FirestoreComplaintRepository implements ComplaintRepository {
  FirestoreComplaintRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<Complaint>> watchForJob(String jobId) {
    return FirestorePaths.jobComplaintsCollection(_db, jobId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(_fromDoc).toList());
  }

  @override
  Future<Result<Complaint, Failure>> submit(ComplaintDraft draft) async {
    try {
      final ref = FirestorePaths.jobComplaintsCollection(_db, draft.jobId).doc();
      final complaint = Complaint(
        id: ref.id,
        jobId: draft.jobId,
        raisedBy: draft.raisedBy,
        reporterId: draft.reporterId,
        subjectId: draft.subjectId,
        category: draft.category,
        description: draft.description,
        evidence: draft.evidence,
        createdAt: DateTime.now(),
      );
      await ref.set(<String, dynamic>{
        'job_id': draft.jobId,
        'raised_by': draft.raisedBy.toWire(),
        'reporter_id': draft.reporterId,
        'subject_id': draft.subjectId,
        'category': draft.category,
        'description': draft.description,
        'status': ComplaintStatus.open.toWire(),
        'evidence': draft.evidence,
        'created_at': FieldValue.serverTimestamp(),
      });
      return Result.ok(complaint);
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

  Complaint _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Complaint(
      id: doc.id,
      jobId: (d['job_id'] as String?) ?? '',
      raisedBy: _raisedByOrDefault(d['raised_by']),
      reporterId: (d['reporter_id'] as String?) ?? '',
      subjectId: d['subject_id'] as String?,
      category: (d['category'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      status: _statusOrDefault(d['status']),
      evidence: (d['evidence'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (d['resolved_at'] as Timestamp?)?.toDate(),
      resolutionNote: d['resolution_note'] as String?,
    );
  }

  ComplaintRaisedBy _raisedByOrDefault(Object? wire) {
    if (wire is! String) return ComplaintRaisedBy.customer;
    try {
      return ComplaintRaisedByCodec.fromWire(wire);
    } on FormatException {
      return ComplaintRaisedBy.customer;
    }
  }

  ComplaintStatus _statusOrDefault(Object? wire) {
    if (wire is! String) return ComplaintStatus.open;
    try {
      return ComplaintStatusCodec.fromWire(wire);
    } on FormatException {
      return ComplaintStatus.open;
    }
  }
}
