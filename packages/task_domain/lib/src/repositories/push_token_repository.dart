import 'package:task_core/task_core.dart';

/// Registry of a user's device push (FCM) tokens, stored under
/// `users/{uid}/fcm_tokens/{token}`.
///
/// A user may be signed in on several devices, so tokens are kept per-device
/// keyed by the token string itself. The backend reads this collection to fan a
/// notification out to every device. Implemented in `task_data` over Firestore.
abstract interface class PushTokenRepository {
  /// Upsert [token] for [uid], tagging the originating [platform]
  /// ('android' | 'ios' | 'web'). Safe to call repeatedly (idempotent).
  Future<Result<void, Failure>> register({
    required String uid,
    required String token,
    required String platform,
  });

  /// Remove [token] for [uid] — call on sign-out so a shared device stops
  /// receiving the previous user's pushes.
  Future<Result<void, Failure>> unregister({
    required String uid,
    required String token,
  });
}
