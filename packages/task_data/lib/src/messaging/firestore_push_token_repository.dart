import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_core/task_core.dart';
import 'package:task_domain/task_domain.dart';

/// Cloud Firestore implementation of [PushTokenRepository].
///
/// Tokens live at `users/{uid}/fcm_tokens/{token}` — keyed by the token string
/// so re-registering the same device is a harmless overwrite. The backend's
/// notification fan-out reads this collection to target every device.
class FirestorePushTokenRepository implements PushTokenRepository {
  FirestorePushTokenRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tokens(String uid) =>
      _db.collection('users').doc(uid).collection('fcm_tokens');

  @override
  Future<Result<void, Failure>> register({
    required String uid,
    required String token,
    required String platform,
  }) {
    return _guard(() => _tokens(uid).doc(token).set(<String, dynamic>{
          'token': token,
          'platform': platform,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)));
  }

  @override
  Future<Result<void, Failure>> unregister({
    required String uid,
    required String token,
  }) {
    return _guard(() => _tokens(uid).doc(token).delete());
  }

  Future<Result<void, Failure>> _guard(Future<void> Function() op) async {
    try {
      await op();
      return const Result.ok(null);
    } on FirebaseException catch (e, st) {
      if (e.code == 'permission-denied') {
        return Result.err(
            PermissionFailure(e.message ?? e.code, cause: e, stackTrace: st));
      }
      return Result.err(
          NetworkFailure(e.message ?? e.code, cause: e, stackTrace: st));
    } catch (e, st) {
      return Result.err(UnexpectedFailure('$e', cause: e, stackTrace: st));
    }
  }
}
