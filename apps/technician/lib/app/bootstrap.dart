import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:technician/app/firebase_init.dart';
import 'package:technician/app/flavor.dart';
import 'package:technician/app/technician_app.dart';
import 'package:technician/features/auth/auth_controller.dart';
import 'package:technician/features/notifications/push_messaging.dart';
import 'package:technician/features/settings/theme_controller.dart';

/// Single composition root for every flavor entrypoint.
///
/// Firebase is initialised against the live project; if that fails, [initFirebase]
/// returns false and the auth layer transparently falls back to a local mock so
/// the app still runs and stays navigable.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  final results = await Future.wait(<Future<dynamic>>[
    initFirebase(flavor),
    loadPersistedThemeMode(),
  ]);

  final bool firebaseReady = results[0] as bool;
  final ThemeMode themeMode = results[1] as ThemeMode;

  // Register the FCM background/terminated handler before the app starts. Only
  // meaningful when Firebase actually initialised and on mobile (web push needs
  // a service worker that is out of scope for now).
  if (firebaseReady && !kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(
    ProviderScope(
      overrides: <Override>[
        firebaseReadyProvider.overrideWithValue(firebaseReady),
        themeModeProvider.overrideWith(() => _SeededThemeMode(themeMode)),
      ],
      child: TechnicianApp(flavor: flavor),
    ),
  );
}

/// Seeds [themeModeProvider] with the persisted value while keeping the
/// controller's mutation API intact.
class _SeededThemeMode extends ThemeModeController {
  _SeededThemeMode(this._initial);
  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;
}
