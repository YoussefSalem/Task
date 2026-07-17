import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

/// The technician's window onto the shared `jobs` collection.
///
/// Where the customer's marketplace repo scopes to `customer_id == me`, this one
/// reads the open market (jobs still taking bids) and the jobs this pro is
/// engaged on. Writes are constrained by the security rules to exactly two
/// things a technician may do: append/adjust *their own* entry in the `offers`
/// array (a job update whose only changed key is `offers`), and advance the job
/// `status` to `en_route` / `in_progress` / `completed` (snake_case wire values).
class TechnicianJobsRepository {
  TechnicianJobsRepository(this._uid);

  final String _uid;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      FirestorePaths.jobsCollection(FirebaseFirestore.instance);

  // ── Reads ────────────────────────────────────────────────────────────────

  /// Every job still open for bids. The customer stores `biddingActive` (the
  /// Dart enum name) on publish; we sort client-side so no composite index is
  /// needed. The caller filters out this pro's own postings.
  Stream<List<JobRequest>> watchOpenJobs() {
    return _jobs
        .where('status', isEqualTo: JobStatus.biddingActive.name)
        .snapshots()
        .map((qs) {
      final jobs = qs.docs.map(_jobFromDoc).toList();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    });
  }

  /// Jobs that have left the open market — the ones this pro is hired on, plus
  /// finished/cancelled history. Filtered client-side to this technician.
  Stream<List<JobRequest>> watchMyEngagements() {
    // Cover both wire and Dart-name spellings of every post-bidding status so a
    // job written by either app is seen (see [_statusFrom]).
    const List<String> statuses = <String>[
      'accepted',
      'en_route', 'enRoute',
      'in_progress', 'inProgress',
      'paused_for_approval', 'pausedForApproval',
      'completed',
      'cancelled',
    ];
    return _jobs
        .where('status', whereIn: statuses)
        .snapshots()
        .map((qs) {
      final jobs = qs.docs
          .map(_jobFromDoc)
          .where(_involvesMe)
          .toList();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    });
  }

  bool _involvesMe(JobRequest job) =>
      job.offers.any((Offer o) => o.technicianId == _uid);

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Places or updates this pro's bid on [jobId] at [amount] EGP. Appends a
  /// technician-authored proposal to their thread (creating it on first bid) and
  /// leaves the status `pending` — awaiting the customer. Only the `offers` key
  /// changes, satisfying the technician-edits-offers rule.
  Future<void> placeBid({
    required String jobId,
    required int amount,
    required String technicianName,
    required double rating,
    required int jobsDone,
    required String etaLabel,
  }) async {
    final ref = _jobs.doc(jobId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final JobRequest job = _jobFromDoc(snap);

    final DateTime now = DateTime.now();
    final Offer? existing =
        job.offers.where((o) => o.technicianId == _uid).firstOrNull;

    final List<Offer> updated;
    if (existing == null) {
      updated = <Offer>[
        ...job.offers,
        Offer(
          id: _uid,
          technicianId: _uid,
          technicianName: technicianName,
          rating: rating,
          jobsDone: jobsDone,
          etaLabel: etaLabel,
          status: OfferStatus.pending,
          proposals: <PriceProposal>[
            PriceProposal(
                amount: amount, by: ProposalAuthor.technician, at: now),
          ],
        ),
      ];
    } else {
      updated = job.offers.map((Offer o) {
        if (o.technicianId != _uid) return o;
        return o.copyWith(
          status: OfferStatus.pending,
          proposals: <PriceProposal>[
            ...o.proposals,
            PriceProposal(
                amount: amount, by: ProposalAuthor.technician, at: now),
          ],
        );
      }).toList();
    }

    await ref.update(<String, dynamic>{
      'offers': updated.map(_offerToMap).toList(),
    });
  }

  /// Withdraws this pro's bid, marking their own offer `withdrawn`.
  Future<void> withdrawBid(String jobId) async {
    final ref = _jobs.doc(jobId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final JobRequest job = _jobFromDoc(snap);
    final List<Offer> updated = job.offers
        .map((Offer o) => o.technicianId == _uid
            ? o.copyWith(status: OfferStatus.withdrawn)
            : o)
        .toList();
    await ref.update(<String, dynamic>{
      'offers': updated.map(_offerToMap).toList(),
    });
  }

  /// Upserts the technician↔job link in the `job_assignments` collection — the
  /// "technician database" join table connecting this pro to a customer's
  /// service request. Written when the pro is hired and on each status change;
  /// keyed by job id (one hired technician per job). Only the assigning
  /// technician may write, per the security rules.
  Future<void> upsertAssignment(
    JobRequest job, {
    required String technicianName,
    required JobStatus status,
  }) async {
    final ref = FirestorePaths.jobAssignmentDoc(
        FirebaseFirestore.instance, job.id);
    final bool exists = (await ref.get()).exists;
    await ref.set(<String, dynamic>{
      'job_id': job.id,
      'technician_id': _uid,
      'technician_name': technicianName,
      'customer_id': job.customerId,
      'category': job.category.name,
      'title': job.title,
      'agreed_price': job.settledPrice,
      'status': status.toWire(),
      'location_label': job.locationLabel,
      'lat': job.lat,
      'lng': job.lng,
      if (!exists) 'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Advances the job through the on-site lifecycle. Only `en_route`,
  /// `in_progress`, and `completed` are permitted for a technician; the value is
  /// written in snake_case wire form, which the security rules require.
  Future<void> advanceStatus(String jobId, JobStatus next) async {
    assert(
      next == JobStatus.enRoute ||
          next == JobStatus.inProgress ||
          next == JobStatus.completed,
      'Technicians may only advance to en_route / in_progress / completed',
    );
    await _jobs.doc(jobId).update(<String, dynamic>{
      'status': next.toWire(),
    });
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> _offerToMap(Offer o) => <String, dynamic>{
        'id': o.id,
        'technician_id': o.technicianId,
        'technician_name': o.technicianName,
        'rating': o.rating,
        'jobs_done': o.jobsDone,
        'eta_label': o.etaLabel,
        'status': o.status.name,
        'proposals': o.proposals
            .map((PriceProposal p) => <String, dynamic>{
                  'amount': p.amount,
                  'by': p.by.name,
                  'at': Timestamp.fromDate(p.at),
                })
            .toList(),
      };

  JobRequest _jobFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return JobRequest(
      id: doc.id,
      customerId: (d['customer_id'] as String?) ?? '',
      category: _byName(JobCategory.values, d['category'],
          JobCategory.plumbing, (c) => c.name),
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      fixedPrice: (d['fixed_price'] as num?)?.toInt() ?? 0,
      currency: (d['currency'] as String?) ?? 'EGP',
      urgency: _byName(Urgency.values, d['urgency'], Urgency.soon, (e) => e.name),
      propertyType: _byName(PropertyType.values, d['property_type'],
          PropertyType.apartment, (e) => e.name),
      timing: _byName(JobTiming.values, d['timing'], JobTiming.asap, (e) => e.name),
      scheduledAt: (d['scheduled_at'] as Timestamp?)?.toDate(),
      floor: d['floor'] as String?,
      parking: d['parking'] as bool?,
      photos: (d['photos'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      locationLabel: (d['location_label'] as String?) ?? '',
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      notes: (d['notes'] as String?) ?? '',
      status: _statusFrom(d['status']),
      offers: (d['offers'] as List<dynamic>?)
              ?.map((e) => _offerFromMap(e as Map<String, dynamic>))
              .toList() ??
          const <Offer>[],
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancellationReason: d['cancellation_reason'] as String?,
      searchingUntil: (d['searching_until'] as Timestamp?)?.toDate(),
    );
  }

  Offer _offerFromMap(Map<String, dynamic> m) => Offer(
        id: (m['id'] as String?) ?? '',
        technicianId: (m['technician_id'] as String?) ?? '',
        technicianName: (m['technician_name'] as String?) ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        jobsDone: (m['jobs_done'] as num?)?.toInt() ?? 0,
        etaLabel: (m['eta_label'] as String?) ?? '',
        status: _byName(
            OfferStatus.values, m['status'], OfferStatus.pending, (e) => e.name),
        proposals: (m['proposals'] as List<dynamic>?)
                ?.map((e) {
                  final p = e as Map<String, dynamic>;
                  return PriceProposal(
                    amount: (p['amount'] as num?)?.toInt() ?? 0,
                    by: _byName(ProposalAuthor.values, p['by'],
                        ProposalAuthor.technician, (e) => e.name),
                    at: (p['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  );
                })
                .toList() ??
            const <PriceProposal>[],
      );

  /// Tolerant [JobStatus] reader: matches either the Dart enum name (what the
  /// customer app writes, e.g. `enRoute`) or the snake_case wire value (what the
  /// technician app and the rules use, e.g. `en_route`). This keeps the two
  /// apps interoperable despite their differing status spellings.
  JobStatus _statusFrom(Object? raw) {
    if (raw is! String) return JobStatus.biddingActive;
    for (final JobStatus s in JobStatus.values) {
      if (s.name == raw || s.toWire() == raw) return s;
    }
    return JobStatus.biddingActive;
  }

  T _byName<T>(List<T> values, Object? name, T fallback, String Function(T) key) {
    if (name is! String) return fallback;
    for (final T v in values) {
      if (key(v) == name) return v;
    }
    return fallback;
  }
}
