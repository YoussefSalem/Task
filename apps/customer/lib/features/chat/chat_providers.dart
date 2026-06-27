// apps/customer/lib/features/chat/chat_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

import '../auth/auth_controller.dart';

/// Identifies one customer↔technician conversation. A Dart record gives value
/// equality for free, so `.family` caches one provider per (job, technician).
typedef ThreadKey = ({String jobId, String technicianId});

/// The signed-in customer's uid, or null when signed out.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.uid,
);

/// Firestore-backed chat. Lazily touches Firestore only when used.
final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => FirestoreMessagingRepository(),
);

/// Firestore-backed in-app notification feed.
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => FirestoreNotificationRepository(),
);

/// Live messages in a thread, oldest first.
final threadMessagesProvider =
    StreamProvider.family<List<Message>, ThreadKey>((ref, key) {
  return ref.watch(messagingRepositoryProvider).watchMessages(
        jobId: key.jobId,
        technicianId: key.technicianId,
      );
});

/// Live thread metadata (read cursors, typing stamps), or null until created.
final threadMetaProvider =
    StreamProvider.family<ChatThread?, ThreadKey>((ref, key) {
  return ref.watch(messagingRepositoryProvider).watchThread(
        jobId: key.jobId,
        technicianId: key.technicianId,
      );
});

/// The customer's notification feed, newest first.
final notificationFeedProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream<List<AppNotification>>.value(const []);
  return ref.watch(notificationRepositoryProvider).watchFeed(uid);
});

/// Unread count for the bell badge. Zero when signed out.
final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream<int>.value(0);
  return ref.watch(notificationRepositoryProvider).watchUnreadCount(uid);
});
