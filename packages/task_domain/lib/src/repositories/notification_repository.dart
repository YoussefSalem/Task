import 'package:task_core/task_core.dart';

import '../entities/app_notification.dart';

/// The in-app notification feed for a single user.
///
/// There is no push transport and no Cloud Function fan-out: the side that
/// performs an action calls [notify] to write straight into the recipient's
/// feed. Implemented in `task_data` over Cloud Firestore.
abstract interface class NotificationRepository {
  /// Live feed for [uid], newest first.
  Stream<List<AppNotification>> watchFeed(String uid);

  /// Live count of unread entries for [uid], for the badge.
  Stream<int> watchUnreadCount(String uid);

  /// Write [draft] into [recipientUid]'s feed.
  Future<Result<void, Failure>> notify({
    required String recipientUid,
    required NotificationDraft draft,
  });

  /// Mark a single entry read.
  Future<Result<void, Failure>> markRead({
    required String uid,
    required String notificationId,
  });

  /// Mark every entry in [uid]'s feed read.
  Future<Result<void, Failure>> markAllRead(String uid);
}
