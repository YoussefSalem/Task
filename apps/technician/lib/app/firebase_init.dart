import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:technician/app/flavor.dart';
import 'package:technician/firebase_options.dart';

/// Initialises Firebase against the live `task-app-20c5f` project (shared with
/// the Customer app). Returns true on success; false on any failure so the app
/// can still boot in a degraded, mock-auth state.
///
/// To test against the local emulator suite, route BOTH Auth and Firestore to
/// it (never one alone — a cloud token is rejected by an emulator and vice
/// versa) and make sure `firebase emulators:start` is running.
Future<bool> initFirebase(Flavor flavor) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _activateAppCheck();
    await _configureAuthForDebug();
    return true;
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
    return false;
  }
}

/// Activates App Check so App Check-enforced backends accept our calls. Debug
/// builds print `App Check debug token: <UUID>` on first run — register it in
/// Firebase Console → App Check → Manage debug tokens. Web is skipped (needs a
/// reCAPTCHA site key that isn't configured here). Failures never block startup.
Future<void> _activateAppCheck() async {
  if (kIsWeb) return;
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
  } catch (e) {
    debugPrint('App Check activation failed: $e');
  }
}

/// When true, debug builds disable phone-auth app verification so sign-in works
/// with fictional test numbers. Leave false to exercise the real SMS pipeline.
const bool _disablePhoneVerificationForTesting = false;

Future<void> _configureAuthForDebug() async {
  if (kIsWeb || !kDebugMode || !_disablePhoneVerificationForTesting) return;
  try {
    await FirebaseAuth.instance
        .setSettings(appVerificationDisabledForTesting: true);
  } catch (e) {
    debugPrint('Auth debug settings failed: $e');
  }
}
