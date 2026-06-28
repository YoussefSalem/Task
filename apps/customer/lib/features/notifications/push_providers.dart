import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_data/task_data.dart';
import 'package:task_domain/task_domain.dart';

/// Firestore registry of this user's device push tokens
/// (`users/{uid}/fcm_tokens/{token}`), read by the backend fan-out function.
final pushTokenRepositoryProvider = Provider<PushTokenRepository>(
  (ref) => FirestorePushTokenRepository(),
);
