import 'package:meta/meta.dart';

import 'messaging_enums.dart';

/// One entry in a user's in-app notification feed, stored under
/// `users/{uid}/notifications/{id}`.
///
/// There is no server fan-out: the side that performs an action writes the
/// notification straight into the recipient's feed. [jobId] and [threadId] let
/// a tap route back to the originating job or conversation.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.actorId,
    this.jobId,
    this.threadId,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;

  /// Who triggered the notification (the other party), if applicable.
  final String? actorId;

  /// The job this relates to, for routing.
  final String? jobId;

  /// The technician id identifying the thread, when [type] is
  /// [NotificationType.message].
  final String? threadId;

  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        actorId: actorId,
        jobId: jobId,
        threadId: threadId,
        read: read ?? this.read,
      );
}

/// A new notification to write into a recipient's feed. The id and timestamp are
/// assigned by the data layer (document id + server timestamp), so the caller
/// only supplies the payload.
@immutable
class NotificationDraft {
  const NotificationDraft({
    required this.type,
    required this.title,
    required this.body,
    this.actorId,
    this.jobId,
    this.threadId,
  });

  final NotificationType type;
  final String title;
  final String body;
  final String? actorId;
  final String? jobId;
  final String? threadId;
}
