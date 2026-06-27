import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_core/task_core.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreNotificationRepository repo;

  const String uid = 'cust1';

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreNotificationRepository(firestore: db);
  });

  NotificationDraft draft({NotificationType type = NotificationType.message}) =>
      NotificationDraft(
        type: type,
        title: 'New message',
        body: 'Sam: on my way',
        actorId: 'tech1',
        jobId: 'job1',
        threadId: 'tech1',
      );

  test('notify writes an unread entry into the recipient feed', () async {
    final Result<void, Failure> r =
        await repo.notify(recipientUid: uid, draft: draft());
    expect(r.isOk, isTrue);

    final List<AppNotification> feed = await repo.watchFeed(uid).first;
    expect(feed.length, 1);
    expect(feed.single.title, 'New message');
    expect(feed.single.type, NotificationType.message);
    expect(feed.single.read, isFalse);
    expect(feed.single.jobId, 'job1');
  });

  test('watchUnreadCount reflects unread entries', () async {
    expect(await repo.watchUnreadCount(uid).first, 0);
    await repo.notify(recipientUid: uid, draft: draft());
    await repo.notify(
        recipientUid: uid, draft: draft(type: NotificationType.offer));
    expect(await repo.watchUnreadCount(uid).first, 2);
  });

  test('markRead clears a single entry', () async {
    await repo.notify(recipientUid: uid, draft: draft());
    final AppNotification n = (await repo.watchFeed(uid).first).single;

    final Result<void, Failure> r =
        await repo.markRead(uid: uid, notificationId: n.id);
    expect(r.isOk, isTrue);

    expect(await repo.watchUnreadCount(uid).first, 0);
    expect((await repo.watchFeed(uid).first).single.read, isTrue);
  });

  test('markAllRead clears the whole feed', () async {
    await repo.notify(recipientUid: uid, draft: draft());
    await repo.notify(
        recipientUid: uid, draft: draft(type: NotificationType.hired));
    await repo.notify(
        recipientUid: uid, draft: draft(type: NotificationType.jobStatus));
    expect(await repo.watchUnreadCount(uid).first, 3);

    final Result<void, Failure> r = await repo.markAllRead(uid);
    expect(r.isOk, isTrue);
    expect(await repo.watchUnreadCount(uid).first, 0);
  });

  test('feeds are isolated per recipient', () async {
    await repo.notify(recipientUid: uid, draft: draft());
    expect(await repo.watchUnreadCount('someone_else').first, 0);
  });
}
