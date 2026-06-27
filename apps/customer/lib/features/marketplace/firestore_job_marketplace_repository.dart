import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_domain/task_domain.dart';

/// Firestore-backed [JobMarketplaceRepository]. Each job is one document in the
/// top-level `jobs` collection, tagged with `customer_id` so a customer's jobs
/// pull on any device they sign in from. Offers are stored inline as an array.
class FirestoreJobMarketplaceRepository implements JobMarketplaceRepository {
  FirestoreJobMarketplaceRepository(this._uid);

  final String _uid;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      FirebaseFirestore.instance.collection('jobs');

  @override
  Stream<List<JobRequest>> watchMyJobs() {
    // Filter by owner only; sort client-side so no composite index is needed.
    return _jobs.where('customer_id', isEqualTo: _uid).snapshots().map((qs) {
      final jobs = qs.docs.map(_jobFromDoc).toList();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    });
  }

  @override
  Future<JobRequest> publish(JobRequestDraft draft) async {
    final docRef = _jobs.doc();
    final JobRequest job = JobRequest(
      id: docRef.id,
      category: draft.category ?? JobCategory.plumbing,
      title: draft.title,
      description: draft.description,
      fixedPrice: draft.fixedPrice,
      urgency: draft.urgency,
      propertyType: draft.propertyType,
      floor: draft.floor,
      parking: draft.parking,
      photos: draft.photos,
      locationLabel: draft.locationLabel,
      notes: draft.notes,
      status: JobStatus.biddingActive,
      offers: const <Offer>[],
      createdAt: DateTime.now(),
    );
    await docRef.set(<String, dynamic>{
      ..._jobToMap(job),
      'customer_id': _uid,
      'created_at': FieldValue.serverTimestamp(),
    });
    return job;
  }

  @override
  Future<void> acceptOffer(String jobId, String offerId) async {
    final ref = _jobs.doc(jobId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final job = _jobFromDoc(snap);
    final offers = job.offers
        .map((Offer o) => o.copyWith(
              status: o.id == offerId
                  ? OfferStatus.accepted
                  : OfferStatus.declined,
            ))
        .toList();
    await ref.update(<String, dynamic>{
      'status': JobStatus.accepted.name,
      'offers': offers.map(_offerToMap).toList(),
    });
  }

  @override
  Future<void> counterOffer(String jobId, String offerId, int amount) async {
    final ref = _jobs.doc(jobId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final job = _jobFromDoc(snap);
    final offers = job.offers.map((Offer o) {
      if (o.id != offerId) return o;
      return o.copyWith(
        proposals: <PriceProposal>[
          ...o.proposals,
          PriceProposal(
              amount: amount,
              by: ProposalAuthor.customer,
              at: DateTime.now()),
        ],
        status: OfferStatus.countered,
      );
    }).toList();
    await ref.update(<String, dynamic>{
      'offers': offers.map(_offerToMap).toList(),
    });
  }

  @override
  Future<void> cancelJob(String jobId) async {
    await _jobs.doc(jobId).update(<String, dynamic>{
      'status': JobStatus.cancelled.name,
    });
  }

  @override
  Future<void> submitReview(String jobId, Review review) async {
    await _jobs.doc(jobId).collection('reviews').doc(review.reviewerId).set(<String, dynamic>{
      'rating': review.rating,
      'tags': review.tags,
      'note': review.note,
      'reviewer_id': review.reviewerId,
      'technician_id': review.technicianId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // --- serialization -------------------------------------------------------

  Map<String, dynamic> _jobToMap(JobRequest j) => <String, dynamic>{
        'category': j.category.name,
        'title': j.title,
        'description': j.description,
        'fixed_price': j.fixedPrice,
        'currency': j.currency,
        'urgency': j.urgency.name,
        'property_type': j.propertyType.name,
        'floor': j.floor,
        'parking': j.parking,
        'photos': j.photos,
        'location_label': j.locationLabel,
        'notes': j.notes,
        'status': j.status.name,
        'offers': j.offers.map(_offerToMap).toList(),
      };

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
      category: _byName(JobCategory.values, d['category'], JobCategory.plumbing),
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      fixedPrice: (d['fixed_price'] as num?)?.toInt() ?? 0,
      currency: (d['currency'] as String?) ?? 'EGP',
      urgency: _byName(Urgency.values, d['urgency'], Urgency.soon),
      propertyType:
          _byName(PropertyType.values, d['property_type'], PropertyType.apartment),
      floor: d['floor'] as String?,
      parking: d['parking'] as bool?,
      photos: (d['photos'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      locationLabel: (d['location_label'] as String?) ?? '',
      notes: (d['notes'] as String?) ?? '',
      status: _byName(JobStatus.values, d['status'], JobStatus.biddingActive),
      offers: (d['offers'] as List<dynamic>?)
              ?.map((e) => _offerFromMap(e as Map<String, dynamic>))
              .toList() ??
          const <Offer>[],
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Offer _offerFromMap(Map<String, dynamic> m) => Offer(
        id: (m['id'] as String?) ?? '',
        technicianId: (m['technician_id'] as String?) ?? '',
        technicianName: (m['technician_name'] as String?) ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        jobsDone: (m['jobs_done'] as num?)?.toInt() ?? 0,
        etaLabel: (m['eta_label'] as String?) ?? '',
        status: _byName(OfferStatus.values, m['status'], OfferStatus.pending),
        proposals: (m['proposals'] as List<dynamic>?)
                ?.map((e) {
                  final p = e as Map<String, dynamic>;
                  return PriceProposal(
                    amount: (p['amount'] as num?)?.toInt() ?? 0,
                    by: _byName(
                        ProposalAuthor.values, p['by'], ProposalAuthor.technician),
                    at: (p['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  );
                })
                .toList() ??
            const <PriceProposal>[],
      );

  T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
    if (name is! String) return fallback;
    for (final T v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}

/// Used when no user is signed in (e.g. transient auth state). Emits no jobs and
/// rejects mutations so the UI never writes orphaned data.
class EmptyJobMarketplaceRepository implements JobMarketplaceRepository {
  const EmptyJobMarketplaceRepository();

  @override
  Stream<List<JobRequest>> watchMyJobs() =>
      Stream<List<JobRequest>>.value(const <JobRequest>[]);

  @override
  Future<JobRequest> publish(JobRequestDraft draft) =>
      throw StateError('Not signed in');

  @override
  Future<void> acceptOffer(String jobId, String offerId) async {}

  @override
  Future<void> counterOffer(String jobId, String offerId, int amount) async {}

  @override
  Future<void> cancelJob(String jobId) async {}

  @override
  Future<void> submitReview(String jobId, Review review) async {}
}
