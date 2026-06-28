import 'package:customer/app/customer_app.dart';
import 'package:customer/app/firebase_init.dart';
import 'package:customer/app/flavor.dart';
import 'package:customer/features/auth/auth_controller.dart';
import 'package:customer/features/notifications/push_messaging.dart';
import 'package:customer/features/settings/theme_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single composition root for every flavor entrypoint.
///
/// Firebase is initialised against the demo-task emulator in dev. If that fails
/// (emulator not running, no config), [initFirebase] returns false and the auth
/// layer transparently falls back to a local mock so the app still runs.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  final results = await Future.wait(<Future<dynamic>>[
    initFirebase(flavor),
    loadPersistedThemeMode(),
  ]);

  final bool firebaseReady = results[0] as bool;
  final ThemeMode themeMode = results[1] as ThemeMode;

  // Register the FCM background/terminated handler before the app starts. Only
  // meaningful when Firebase actually initialised (the mock fallback has no
  // messaging transport) and on mobile (web push needs a service worker that is
  // out of scope for now).
  if (firebaseReady && !kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(
    ProviderScope(
      overrides: <Override>[
        firebaseReadyProvider.overrideWithValue(firebaseReady),
        themeModeProvider.overrideWith((ref) => themeMode),
      ],
      child: CustomerApp(flavor: flavor),
    ),
  );
}
