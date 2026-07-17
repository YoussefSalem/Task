import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

import '../jobs/jobs_providers.dart';

/// Identifies one conversation. For the technician app the `technicianId` is
/// always this pro's own uid — a thread is keyed by (job, technician).
typedef ThreadKey = ({String jobId, String technicianId});

/// Firestore-backed chat, shared with the customer app via `task_data`.
final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => FirestoreMessagingRepository(),
);

/// Firestore-backed in-app notification feed (hired / new message / status).
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => FirestoreNotificationRepository(),
);

/// Every conversation this pro is part of, most-recent first.
final myThreadsProvider = StreamProvider<List<ChatThread>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream<List<ChatThread>>.value(const <ChatThread>[]);
  return ref.watch(messagingRepositoryProvider).watchThreadsForUser(uid);
});

/// Live messages in a thread, oldest first.
final threadMessagesProvider =
    StreamProvider.family<List<Message>, ThreadKey>((ref, key) {
  return ref.watch(messagingRepositoryProvider).watchMessages(
        jobId: key.jobId,
        technicianId: key.technicianId,
      );
});

/// Live thread metadata (read cursors, typing), or null until created.
final threadMetaProvider =
    StreamProvider.family<ChatThread?, ThreadKey>((ref, key) {
  return ref.watch(messagingRepositoryProvider).watchThread(
        jobId: key.jobId,
        technicianId: key.technicianId,
      );
});

/// Unread conversation count for the Messages tab badge.
final unreadThreadsProvider = Provider<int>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  final List<ChatThread> threads =
      ref.watch(myThreadsProvider).valueOrNull ?? const <ChatThread>[];
  if (uid == null) return 0;
  int count = 0;
  for (final ChatThread t in threads) {
    final DateTime? cursor = t.readCursorFor(SenderRole.technician);
    final DateTime? last = t.lastMessageAt;
    if (last == null) continue;
    // Unread when the last message is newer than our cursor. We can't see the
    // last sender here, so treat a fresh message as unread unless we've read up
    // to it — a slight over-count that clears as soon as the thread is opened.
    if (cursor == null || last.isAfter(cursor)) count++;
  }
  return count;
});
