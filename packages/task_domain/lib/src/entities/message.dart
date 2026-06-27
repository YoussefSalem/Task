import 'package:meta/meta.dart';

import 'messaging_enums.dart';

/// A single chat message inside a job conversation. Stored under
/// `jobs/{jobId}/threads/{technicianId}/messages/{id}`.
@immutable
class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final SenderRole senderRole;
  final String text;
  final DateTime createdAt;
}

/// A customer↔technician conversation about one job. There is one thread per
/// (job, technician) pair, so a customer can talk to several bidders separately
/// and the conversation carries over once one is hired.
///
/// Read state is tracked with cursors rather than per-message flags: a message
/// is "read" by a participant when its [Message.createdAt] is at or before that
/// participant's read cursor. Typing is tracked with a freshness stamp that the
/// sender refreshes while composing.
@immutable
class ChatThread {
  const ChatThread({
    required this.jobId,
    required this.customerId,
    required this.technicianId,
    required this.technicianName,
    this.lastMessage = '',
    this.lastMessageAt,
    this.lastReadByCustomer,
    this.lastReadByTechnician,
    this.typingCustomerAt,
    this.typingTechnicianAt,
  });

  final String jobId;
  final String customerId;
  final String technicianId;
  final String technicianName;

  /// Preview of the most recent message, for thread lists.
  final String lastMessage;
  final DateTime? lastMessageAt;

  /// How far each participant has read. A message is unread for a participant
  /// when it was sent by the *other* side after this cursor.
  final DateTime? lastReadByCustomer;
  final DateTime? lastReadByTechnician;

  /// Last moment each side signalled it was typing.
  final DateTime? typingCustomerAt;
  final DateTime? typingTechnicianAt;

  /// A typing stamp counts as "currently typing" only within this window.
  static const Duration typingWindow = Duration(seconds: 5);

  /// Whether [role] is actively typing as of [now] (defaults to the wall clock).
  bool isTyping(SenderRole role, {DateTime? now}) {
    final DateTime? stamp =
        role == SenderRole.customer ? typingCustomerAt : typingTechnicianAt;
    if (stamp == null) return false;
    final DateTime ref = now ?? DateTime.now();
    return ref.difference(stamp) <= typingWindow;
  }

  /// Read cursor for [role].
  DateTime? readCursorFor(SenderRole role) =>
      role == SenderRole.customer ? lastReadByCustomer : lastReadByTechnician;

  /// Whether [message] is unread for [viewer]: sent by the other side and newer
  /// than the viewer's read cursor.
  bool isUnreadFor(SenderRole viewer, Message message) {
    if (message.senderRole == viewer) return false;
    final DateTime? cursor = readCursorFor(viewer);
    if (cursor == null) return true;
    return message.createdAt.isAfter(cursor);
  }
}
