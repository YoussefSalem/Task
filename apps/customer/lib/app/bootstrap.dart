import 'package:customer/app/customer_app.dart';
import 'package:customer/app/firebase_init.dart';
import 'package:customer/app/flavor.dart';
import 'package:customer/features/auth/auth_controller.dart';
import 'package:customer/features/settings/theme_controller.dart';
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
