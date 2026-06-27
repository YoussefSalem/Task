import 'package:task_core/task_core.dart';

import '../entities/message.dart';
import '../entities/messaging_enums.dart';

/// Real-time chat between a customer and a technician about one job.
///
/// Threads are keyed by (jobId, technicianId): a customer may hold a separate
/// conversation with each technician bidding on a job. Implemented in
/// `task_data` over Cloud Firestore; the domain knows nothing about Firebase.
abstract interface class MessagingRepository {
  /// Live messages in a thread, oldest first.
  Stream<List<Message>> watchMessages({
    required String jobId,
    required String technicianId,
  });

  /// Live thread metadata (last message, read cursors, typing stamps), or
  /// `null` until the first message creates it.
  Stream<ChatThread?> watchThread({
    required String jobId,
    required String technicianId,
  });

  /// Append a message authored by [senderRole]. Creates the thread on first
  /// send and refreshes its last-message preview.
  Future<Result<void, Failure>> sendMessage({
    required String jobId,
    required String technicianId,
    required String technicianName,
    required String customerId,
    required String senderId,
    required SenderRole senderRole,
    required String text,
  });

  /// Advance [role]'s read cursor to now, marking everything currently visible
  /// as read.
  Future<Result<void, Failure>> markRead({
    required String jobId,
    required String technicianId,
    required SenderRole role,
  });

  /// Refresh [role]'s typing stamp. Callers should debounce; the stamp is only
  /// considered fresh for [ChatThread.typingWindow].
  Future<Result<void, Failure>> setTyping({
    required String jobId,
    required String technicianId,
    required SenderRole role,
  });

  /// All threads the user participates in (as customer or technician), for the
  /// inbox screen. Returns threads ordered by most recent message first.
  Stream<List<ChatThread>> watchThreadsForUser(String uid);
}
