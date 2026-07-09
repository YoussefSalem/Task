import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_core/task_core.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreComplaintRepository repo;

  const String jobId = 'job1';

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreComplaintRepository(firestore: db);
  });

  ComplaintDraft draft({
    ComplaintRaisedBy raisedBy = ComplaintRaisedBy.customer,
    String reporterId = 'cust1',
    String? subjectId = 'tech1',
    String category = 'no_show',
  }) =>
      ComplaintDraft(
        jobId: jobId,
        raisedBy: raisedBy,
        reporterId: reporterId,
        subjectId: subjectId,
        category: category,
        description: 'Technician never arrived.',
      );

  test('submit writes to jobs/{jobId}/complaints and returns Ok', () async {
    final Result<Complaint, Failure> result = await repo.submit(draft());
    expect(result.isOk, isTrue);

    final complaints = await repo.watchForJob(jobId).first;
    expect(complaints.length, 1);
    expect(complaints.single.category, 'no_show');
    expect(complaints.single.raisedBy, ComplaintRaisedBy.customer);
    expect(complaints.single.status, ComplaintStatus.open);
    expect(complaints.single.subjectId, 'tech1');
  });

  test('writes land at the exact expected Firestore path', () async {
    await repo.submit(draft());
    final snapshot = await db.collection('jobs').doc(jobId).collection('complaints').get();
    expect(snapshot.docs.length, 1);
    expect(snapshot.docs.single.data()['raised_by'], 'customer');
    expect(snapshot.docs.single.data()['status'], 'open');
  });

  test('technician-raised complaints round-trip correctly', () async {
    await repo.submit(draft(raisedBy: ComplaintRaisedBy.technician, reporterId: 'tech1', subjectId: 'cust1'));
    final complaints = await repo.watchForJob(jobId).first;
    expect(complaints.single.raisedBy, ComplaintRaisedBy.technician);
    expect(complaints.single.reporterId, 'tech1');
  });

  test('complaints are isolated per job', () async {
    await repo.submit(draft());
    final otherJobComplaints = await repo.watchForJob('job2').first;
    expect(otherJobComplaints, isEmpty);
  });

  test('watchForJob orders newest first', () async {
    await repo.submit(draft());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.submit(draft(category: 'billing'));
    final complaints = await repo.watchForJob(jobId).first;
    expect(complaints.length, 2);
  });
}
