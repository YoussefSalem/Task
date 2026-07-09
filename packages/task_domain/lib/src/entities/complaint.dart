import 'package:meta/meta.dart';

/// Who raised a complaint about a job.
enum ComplaintRaisedBy { customer, technician }

/// Lifecycle of a complaint, from being filed to resolution.
enum ComplaintStatus { open, investigating, resolved, closed }

/// A complaint filed against a specific job, stored under
/// `jobs/{jobId}/complaints/{id}`.
///
/// This mirrors the same "subcollection of the job" convention already used
/// by [Review] and job tracking, rather than a new top-level collection - a
/// complaint is always about exactly one job, and this keeps it queryable the
/// same way (per-job reads from the app, `collectionGroup` reads from the
/// Admin Dashboard).
@immutable
class Complaint {
  const Complaint({
    required this.id,
    required this.jobId,
    required this.raisedBy,
    required this.reporterId,
    this.subjectId,
    required this.category,
    required this.description,
    this.status = ComplaintStatus.open,
    this.evidence = const <String>[],
    required this.createdAt,
    this.resolvedAt,
    this.resolutionNote,
  });

  final String id;
  final String jobId;

  /// Which side filed this complaint.
  final ComplaintRaisedBy raisedBy;

  /// uid of whoever filed the complaint.
  final String reporterId;

  /// uid of the other party the complaint is about, when known (e.g. the
  /// technician if a customer complained, or vice versa).
  final String? subjectId;

  /// Short free-text reason, e.g. "no_show", "unsafe_behavior", "billing".
  /// Kept as a free string rather than a fixed enum since complaint reasons
  /// are inherently open-ended and app-side copy/localization can map them.
  final String category;

  final String description;
  final ComplaintStatus status;

  /// Storage download URLs for photos/attachments, if any were uploaded.
  final List<String> evidence;

  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;

  Complaint copyWith({
    ComplaintStatus? status,
    DateTime? resolvedAt,
    String? resolutionNote,
  }) =>
      Complaint(
        id: id,
        jobId: jobId,
        raisedBy: raisedBy,
        reporterId: reporterId,
        subjectId: subjectId,
        category: category,
        description: description,
        status: status ?? this.status,
        evidence: evidence,
        createdAt: createdAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        resolutionNote: resolutionNote ?? this.resolutionNote,
      );
}

/// A new complaint to file. The id/status/createdAt are assigned by the data
/// layer, so the caller only supplies the payload.
@immutable
class ComplaintDraft {
  const ComplaintDraft({
    required this.jobId,
    required this.raisedBy,
    required this.reporterId,
    this.subjectId,
    required this.category,
    required this.description,
    this.evidence = const <String>[],
  });

  final String jobId;
  final ComplaintRaisedBy raisedBy;
  final String reporterId;
  final String? subjectId;
  final String category;
  final String description;
  final List<String> evidence;
}
