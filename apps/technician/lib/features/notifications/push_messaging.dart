import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_domain/task_domain.dart';

import '../../app/router.dart';
import 'notifications_screen.dart';
import 'push_providers.dart';

/// Background/terminated message handler. Must be a top-level function annotated
/// with [pragma] so it survives tree-shaking and can run in its own isolate.
/// The server sends a `notification` payload, so the OS renders the tray entry
/// itself — the hook exists only because [FirebaseMessaging.onBackgroundMessage]
/// requires one.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Owns the FCM lifecycle for the technician app: permission, token
/// registration keyed to the signed-in pro, and routing a notification tap into
/// the in-app feed. One instance lives for the app's lifetime.
class PushMessaging {
  PushMessaging(this._ref);

  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  String? _registeredUid;
  String? _registeredToken;
  bool _started = false;

  PushTokenRepository get _tokens => _ref.read(pushTokenRepositoryProvider);

  Future<void> start() async {
    if (_started || kIsWeb) return; // Web push is out of scope for now.
    _started = true;

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage _) {
      // The in-app feed already updates live from Firestore; nothing extra.
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

  /// Called after sign-in: requests permission, fetches the token, registers it,
  /// and drains any tap that cold-started the app.
  Future<void> registerFor(String uid) async {
    if (kIsWeb) return;
    await start();

    final NotificationSettings settings = await _fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final String? token = await _safeToken();
    if (token == null) return;

    _registeredUid = uid;
    _registeredToken = token;
    await _tokens.register(uid: uid, token: token, platform: _platform);

    final RemoteMessage? initial = await _fcm.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  /// Called on sign-out: remove this device's token so a shared phone stops
  /// receiving the previous pro's pushes.
  Future<void> unregister() async {
    final String? uid = _registeredUid;
    final String? token = _registeredToken;
    _registeredUid = null;
    _registeredToken = null;
    if (uid != null && token != null) {
      await _tokens.unregister(uid: uid, token: token);
    }
    try {
      await _fcm.deleteToken();
    } catch (_) {/* best-effort */}
  }

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

/// App-lifetime push controller. Kept alive by a `ref.watch` in [TechnicianApp].
final pushMessagingProvider = Provider<PushMessaging>((ref) {
  final PushMessaging push = PushMessaging(ref);
  ref.onDispose(push.dispose);
  return push;
});
