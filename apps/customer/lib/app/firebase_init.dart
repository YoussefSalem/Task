import 'package:customer/app/flavor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Demo Firebase options for the `demo-task` project used by the local emulator
/// suite (see `firebase.json`). These are NOT secrets — a `demo-` project never
/// talks to production Google servers; every call is routed to the emulators.
/// Replace with `flutterfire configure` output once a real project exists.
const FirebaseOptions _demoOptions = FirebaseOptions(
  apiKey: 'demo-task-key',
  appId: '1:000000000000:web:demotaskcustomer',
  messagingSenderId: '000000000000',
  projectId: 'demo-task',
  authDomain: 'demo-task.firebaseapp.com',
  storageBucket: 'demo-task.appspot.com',
);

/// Initialises Firebase and, in dev, points Auth at the local emulator.
///
/// Returns `true` if Firebase is usable. On any failure it returns `false` so
/// the app still boots — the auth layer then falls back to a local mock flow,
/// keeping the prototype fully navigable without a running emulator.
Future<bool> initFirebase(Flavor flavor) async {
  try {
    await Firebase.initializeApp(options: _demoOptions);

    if (flavor == Flavor.dev) {
      // Route auth to the emulator (firebase.json → auth: 9099). On web the
      // host must be reachable from the browser, so use 127.0.0.1.
      final String host = kIsWeb ? '127.0.0.1' : 'localhost';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    }
    return true;
  } catch (e, st) {
    debugPrint('Firebase init skipped — falling back to mock auth: $e\n$st');
    return false;
  }
}
