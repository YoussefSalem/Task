import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_core/task_core.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreMessagingRepository repo;

  const String jobId = 'job1';
  const String techId = 'tech1';
  const String custId = 'cust1';

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreMessagingRepository(firestore: db);
  });

  Future<Result<void, Failure>> send(SenderRole role, String text) =>
      repo.sendMessage(
        jobId: jobId,
        technicianId: techId,
        technicianName: 'Sam Wrench',
        customerId: custId,
        senderId: role == SenderRole.customer ? custId : techId,
        senderRole: role,
        text: text,
      );

  test('sendMessage stores the message and creates thread metadata', () async {
    final Result<void, Failure> r = await send(SenderRole.customer, 'Hello');
    expect(r.isOk, isTrue);

    final List<Message> msgs =
        await repo.watchMessages(jobId: jobId, technicianId: techId).first;
    expect(msgs.length, 1);
    expect(msgs.single.text, 'Hello');
    expect(msgs.single.senderRole, SenderRole.customer);

    final ChatThread? thread =
        await repo.watchThread(jobId: jobId, technicianId: techId).first;
    expect(thread, isNotNull);
    expect(thread!.lastMessage, 'Hello');
    expect(thread.technicianName, 'Sam Wrench');
    expect(thread.customerId, custId);
  });

  test('empty message is rejected as a ValidationFailure', () async {
    final Result<void, Failure> r = await send(SenderRole.customer, '   ');
    expect(r.isErr, isTrue);
    expect(r.failureOrNull, isA<ValidationFailure>());
    final List<Message> msgs =
        await repo.watchMessages(jobId: jobId, technicianId: techId).first;
    expect(msgs, isEmpty);
  });

  test('a message from the other side is unread until markRead', () async {
    await send(SenderRole.technician, 'Quote is 400');

    ChatThread thread =
        (await repo.watchThread(jobId: jobId, technicianId: techId).first)!;
    final Message msg =
        (await repo.watchMessages(jobId: jobId, technicianId: techId).first)
            .single;

    // The customer has no read cursor yet → technician's message is unread.
    expect(thread.isUnreadFor(SenderRole.customer, msg), isTrue);
    // The technician authored it → never unread for the technician.
    expect(thread.isUnreadFor(SenderRole.technician, msg), isFalse);

    final Result<void, Failure> r = await repo.markRead(
        jobId: jobId, technicianId: techId, role: SenderRole.customer);
    expect(r.isOk, isTrue);

    thread = (await repo.watchThread(jobId: jobId, technicianId: techId).first)!;
    expect(thread.isUnreadFor(SenderRole.customer, msg), isFalse);
  });

  test('setTyping records a fresh stamp the other side can observe', () async {
    await send(SenderRole.customer, 'hi'); // create the thread first
    final Result<void, Failure> r = await repo.setTyping(
        jobId: jobId, technicianId: techId, role: SenderRole.technician);
    expect(r.isOk, isTrue);

    final ChatThread thread =
        (await repo.watchThread(jobId: jobId, technicianId: techId).first)!;
    expect(thread.isTyping(SenderRole.technician), isTrue);
    expect(thread.isTyping(SenderRole.customer), isFalse);
  });

  test('threads are isolated per technician', () async {
    await send(SenderRole.customer, 'for tech1');
    await repo.sendMessage(
      jobId: jobId,
      technicianId: 'tech2',
      technicianName: 'Other Tech',
      customerId: custId,
      senderId: custId,
      senderRole: SenderRole.customer,
      text: 'for tech2',
    );

    final List<Message> t1 =
        await repo.watchMessages(jobId: jobId, technicianId: techId).first;
    final List<Message> t2 =
        await repo.watchMessages(jobId: jobId, technicianId: 'tech2').first;
    expect(t1.single.text, 'for tech1');
    expect(t2.single.text, 'for tech2');
  });
}
