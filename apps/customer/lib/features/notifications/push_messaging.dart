import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_domain/task_domain.dart';

import '../../app/router.dart';
import '../notifications/notifications_screen.dart';
import 'push_providers.dart';

/// Background/terminated message handler. Must be a top-level function annotated
/// with [pragma] so it survives tree-shaking and can run in its own isolate.
///
/// When the server sends a `notification` payload (it does), Android/iOS render
/// the system tray entry automatically — there is nothing to do here. The hook
/// exists only because [FirebaseMessaging.onBackgroundMessage] requires one.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Owns the FCM lifecycle for the customer app: permission, token registration
/// keyed to the signed-in user, and routing a notification tap into the in-app
/// feed. One instance lives for the life of the app (see [pushMessagingProvider]).
///
/// Token storage and the in-app feed are decoupled: the acting client still
/// writes the notification document (live feed + badge), while a Cloud Function
/// reads the tokens registered here to deliver the push. This service only
/// manages tokens and taps — it never writes feed entries.
class PushMessaging {
  PushMessaging(this._ref);

  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  /// The uid the current token is registered against, so a sign-out can clean
  /// up the right device entry even after [authState] has moved to null.
  String? _registeredUid;
  String? _registeredToken;
  bool _started = false;

  PushTokenRepository get _tokens => _ref.read(pushTokenRepositoryProvider);

  /// Wire the message-tap and token-refresh listeners exactly once. Safe to call
  /// repeatedly. Does not request permission — that happens in [registerFor].
  Future<void> start() async {
    if (_started || kIsWeb) return; // Web push is out of scope for now.
    _started = true;

    // Show foreground notifications on iOS as a banner (Android always queues
    // them via the system tray once a channel exists).
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage _) {
      // The in-app feed already updates live from Firestore; nothing extra to
      // do for a foreground message beyond letting the OS banner (iOS) show.
    });

    _onOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    _tokenRefreshSub = _fcm.onTokenRefresh.listen((String token) {
      final String? uid = _registeredUid;
      if (uid != null) {
        _registeredToken = token;
        _tokens.register(uid: uid, token: token, platform: _platform);
      }
    });
  }

  /// Called after sign-in. Requests permission (no-op if already granted),
  /// fetches the token, and registers it for [uid]. Also drains any tap that
  /// launched the app from a terminated state.
  Future<void> registerFor(String uid) async {
    if (kIsWeb) return; // Web push is out of scope for now.
    await start();

    final NotificationSettings settings = await _fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // Respect the user's choice; nothing to register.
    }

    final String? token = await _safeToken();
    if (token == null) return; // e.g. iOS before APNs is configured.

    _registeredUid = uid;
    _registeredToken = token;
    await _tokens.register(uid: uid, token: token, platform: _platform);

    // A tap that cold-started the app is delivered once via getInitialMessage.
    final RemoteMessage? initial = await _fcm.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  /// Called on sign-out: remove this device's token so a shared phone stops
  /// receiving the previous user's pushes.
  Future<void> unregister() async {
    final String? uid = _registeredUid;
    final String? token = _registeredToken;
    _registeredUid = null;
    _registeredToken = null;
    if (uid != null && token != null) {
      await _tokens.unregister(uid: uid, token: token);
    }
    // Invalidate the token so the next user gets a fresh one.
    try {
      await _fcm.deleteToken();
    } catch (_) {/* best-effort */}
  }

  // Every push routes to the in-app feed, which already knows how to open the
  // specific job/thread on tap. Reconstructing ChatArgs from the payload here
  // would duplicate that logic, so we keep a single destination.
  void _handleNotificationTap(RemoteMessage _) {
    final router = _ref.read(goRouterProvider);
    router.push(NotificationsScreen.routePath);
  }

  Future<String?> _safeToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
  }
}

/// App-lifetime push controller. Kept alive by a `ref.watch` in [CustomerApp].
final pushMessagingProvider = Provider<PushMessaging>((ref) {
  final PushMessaging push = PushMessaging(ref);
  ref.onDispose(push.dispose);
  return push;
});
