import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_domain/task_domain.dart';

import '../chat/chat_providers.dart';
import '../jobs/jobs_providers.dart';

/// The signed-in pro's notification feed, newest first.
final notificationFeedProvider = StreamProvider<List<AppNotification>>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) {
    return Stream<List<AppNotification>>.value(const <AppNotification>[]);
  }
  return ref.watch(notificationRepositoryProvider).watchFeed(uid);
});

/// Unread count for the dashboard bell badge. Zero when signed out.
final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final String? uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream<int>.value(0);
  return ref.watch(notificationRepositoryProvider).watchUnreadCount(uid);
});

/// True when there's an un-viewed "you were hired" notification — a new job
/// assignment. Drives the red dot on the Jobs tab; clears once the pro reads
/// their notifications.
final hasNewAssignmentProvider = Provider<bool>((ref) {
  final List<AppNotification> items =
      ref.watch(notificationFeedProvider).valueOrNull ??
          const <AppNotification>[];
  return items.any((n) => n.type == NotificationType.hired && !n.read);
});
