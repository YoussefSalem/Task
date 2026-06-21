import 'package:customer/app/customer_app.dart';
import 'package:customer/app/firebase_init.dart';
import 'package:customer/app/flavor.dart';
import 'package:customer/features/auth/auth_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single composition root for every flavor entrypoint.
///
/// Firebase is initialised against the demo-task emulator in dev. If that fails
/// (emulator not running, no config), [initFirebase] returns false and the auth
/// layer transparently falls back to a local mock so the app still runs.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool firebaseReady = await initFirebase(flavor);

  runApp(
    ProviderScope(
      overrides: <Override>[
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: CustomerApp(flavor: flavor),
    ),
  );
}
