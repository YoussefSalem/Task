import 'dart:async';

import 'package:customer/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../localization/locale_controller.dart';

/// Whether Firebase initialised successfully — overridden in `bootstrap`.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(
    ready: ref.watch(firebaseReadyProvider),
    l: lookupAppLocalizations(ref.watch(localeControllerProvider)),
  ),
);

/// The current signed-in user, or null. Emits null whenever Firebase is
/// unavailable (mock mode) so mock sessions deterministically land on sign-in.
final authStateProvider = StreamProvider<User?>((ref) {
  final bool ready = ref.watch(firebaseReadyProvider);
  if (!ready) return Stream<User?>.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

enum AuthStep { codeSent, signedIn, failed }

@immutable
class AuthOutcome {
  const AuthOutcome(this.step, {this.message, this.mock = false});
  final AuthStep step;
  final String? message;

  /// True when we served this through the local mock (emulator unavailable).
  final bool mock;

  bool get ok => step != AuthStep.failed;
}

/// Drives phone-OTP and social sign-in. Uses real [FirebaseAuth] when available
/// and points at the emulator in dev; if Firebase is down or unreachable it
/// falls back to a local mock so the prototype stays navigable.
class AuthController {
  AuthController({required this.ready, required this.l});

  final bool ready;
  final AppLocalizations l;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Carried between sendOtp and confirmOtp.
  ConfirmationResult? _webConfirmation;
  String? _verificationId;
  bool _mockPending = false;

  // Carried between startPhoneVerification and confirmPhoneVerification (the
  // signed-in "add/change my phone" flow, distinct from sign-in above).
  String? _phoneVerificationId;
  bool _mockPhonePending = false;

  bool get _looksOffline => !ready;

  /// Sends an OTP to an E.164 number (e.g. +201001234567).
  Future<AuthOutcome> sendOtp(String e164) async {
    _webConfirmation = null;
    _verificationId = null;
    _mockPending = false;

    if (_looksOffline) {
      _mockPending = true;
      return const AuthOutcome(AuthStep.codeSent, mock: true);
    }

    try {
      if (kIsWeb) {
        _webConfirmation = await _auth.signInWithPhoneNumber(e164);
        return const AuthOutcome(AuthStep.codeSent);
      }
      // Mobile: completer-style verify.
      final Completer<AuthOutcome> done = Completer<AuthOutcome>();
      await _auth.verifyPhoneNumber(
        phoneNumber: e164,
        verificationCompleted: (PhoneAuthCredential cred) async {
          await _auth.signInWithCredential(cred);
          if (!done.isCompleted) {
            done.complete(const AuthOutcome(AuthStep.signedIn));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!done.isCompleted) {
            done.complete(
                AuthOutcome(AuthStep.failed, message: _friendly(e)));
          }
        },
        codeSent: (String id, int? _) {
          _verificationId = id;
          if (!done.isCompleted) {
            done.complete(const AuthOutcome(AuthStep.codeSent));
          }
        },
        codeAutoRetrievalTimeout: (String id) => _verificationId = id,
      );
      // Guard against app-verification stalling with no callback firing (e.g.
      // Play Integrity/reCAPTCHA failing silently on an emulator): surface an
      // error instead of spinning forever.
      return done.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            AuthOutcome(AuthStep.failed, message: l.genericAuthError),
      );
    } on FirebaseAuthException catch (e) {
      // Real Firebase is up: surface the actual error instead of silently
      // falling back to the mock (which masks reCAPTCHA/config failures and
      // lets any code through). The mock only covers the no-Firebase case
      // handled by [_looksOffline] above.
      return AuthOutcome(AuthStep.failed,
          message: '[${e.code}] ${_friendly(e)}');
    } catch (e) {
      return AuthOutcome(AuthStep.failed, message: e.toString());
    }
  }

  /// Confirms the entered OTP and signs the user in.
  Future<AuthOutcome> confirmOtp(String code) async {
    if (_mockPending) {
      // Any 4–6 digit code clears the mock flow.
      if (code.length < 4) {
        return AuthOutcome(AuthStep.failed, message: l.enterFullCode);
      }
      return const AuthOutcome(AuthStep.signedIn, mock: true);
    }
    try {
      if (kIsWeb) {
        if (_webConfirmation == null) {
          return AuthOutcome(AuthStep.failed,
              message: l.requestNewCode);
        }
        await _webConfirmation!.confirm(code);
      } else {
        if (_verificationId == null) {
          return AuthOutcome(AuthStep.failed,
              message: l.requestNewCode);
        }
        final PhoneAuthCredential cred = PhoneAuthProvider.credential(
            verificationId: _verificationId!, smsCode: code);
        await _auth.signInWithCredential(cred);
      }
      return const AuthOutcome(AuthStep.signedIn);
    } on FirebaseAuthException catch (e) {
      return AuthOutcome(AuthStep.failed, message: _friendly(e));
    } catch (e) {
      return AuthOutcome(AuthStep.failed, message: e.toString());
    }
  }

  /// Starts verifying a phone number for the *already signed-in* user (adding a
  /// number for social sign-ups, or changing an existing one). Sends an OTP via
  /// [FirebaseAuth.verifyPhoneNumber] — supported on web and mobile in this
  /// firebase_auth version. On Android the code may auto-retrieve, in which case
  /// the credential is applied immediately and the outcome is [AuthStep.signedIn].
  Future<AuthOutcome> startPhoneVerification(String e164) async {
    _phoneVerificationId = null;
    _mockPhonePending = false;

    if (_looksOffline) {
      _mockPhonePending = true;
      return const AuthOutcome(AuthStep.codeSent, mock: true);
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      return AuthOutcome(AuthStep.failed, message: l.genericAuthError);
    }

    try {
      final Completer<AuthOutcome> done = Completer<AuthOutcome>();
      await _auth.verifyPhoneNumber(
        phoneNumber: e164,
        verificationCompleted: (PhoneAuthCredential cred) async {
          try {
            await _applyPhoneCredential(user, cred);
            if (!done.isCompleted) {
              done.complete(const AuthOutcome(AuthStep.signedIn));
            }
          } on FirebaseAuthException catch (e) {
            if (!done.isCompleted) {
              done.complete(AuthOutcome(AuthStep.failed, message: _friendly(e)));
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!done.isCompleted) {
            done.complete(AuthOutcome(AuthStep.failed, message: _friendly(e)));
          }
        },
        codeSent: (String id, int? _) {
          _phoneVerificationId = id;
          if (!done.isCompleted) {
            done.complete(const AuthOutcome(AuthStep.codeSent));
          }
        },
        codeAutoRetrievalTimeout: (String id) => _phoneVerificationId = id,
      );
      // Guard against app-verification stalling with no callback firing (e.g.
      // Play Integrity/reCAPTCHA failing silently on an emulator): surface an
      // error instead of spinning forever.
      return done.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            AuthOutcome(AuthStep.failed, message: l.genericAuthError),
      );
    } on FirebaseAuthException catch (e) {
      return AuthOutcome(AuthStep.failed, message: '[${e.code}] ${_friendly(e)}');
    } catch (e) {
      return AuthOutcome(AuthStep.failed, message: e.toString());
    }
  }

  /// Confirms the OTP from [startPhoneVerification] and writes the number onto
  /// the signed-in user (linking it if they had none, updating it otherwise).
  Future<AuthOutcome> confirmPhoneVerification(String code) async {
    if (_mockPhonePending) {
      if (code.length < 4) {
        return AuthOutcome(AuthStep.failed, message: l.enterFullCode);
      }
      return const AuthOutcome(AuthStep.signedIn, mock: true);
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      return AuthOutcome(AuthStep.failed, message: l.genericAuthError);
    }
    if (_phoneVerificationId == null) {
      return AuthOutcome(AuthStep.failed, message: l.requestNewCode);
    }

    try {
      final PhoneAuthCredential cred = PhoneAuthProvider.credential(
          verificationId: _phoneVerificationId!, smsCode: code);
      await _applyPhoneCredential(user, cred);
      await user.reload();
      return const AuthOutcome(AuthStep.signedIn);
    } on FirebaseAuthException catch (e) {
      return AuthOutcome(AuthStep.failed, message: _friendly(e));
    } catch (e) {
      return AuthOutcome(AuthStep.failed, message: e.toString());
    }
  }

  /// Sets the verified phone on the user: links the phone provider when the
  /// account has none, otherwise updates the existing number. Falls back across
  /// both so "add" and "change" both succeed regardless of starting state.
  Future<void> _applyPhoneCredential(User user, PhoneAuthCredential cred) async {
    final bool hasPhone = (user.phoneNumber ?? '').isNotEmpty;
    if (hasPhone) {
      await user.updatePhoneNumber(cred);
      return;
    }
    try {
      await user.linkWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        await user.updatePhoneNumber(cred);
      } else {
        rethrow;
      }
    }
  }

  /// Signs the user out of Firebase. After this the [authStateProvider] stream
  /// emits null, so the splash/router lands on sign-in. No-op in mock mode.
  Future<void> signOut() async {
    if (_looksOffline) return;
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  Future<AuthOutcome> signInWithGoogle() =>
      _oauth(GoogleAuthProvider(), 'Google');

  Future<AuthOutcome> signInWithApple() =>
      _oauth(AppleAuthProvider(), 'Apple');

  Future<AuthOutcome> _oauth(AuthProvider provider, String label) async {
    if (_looksOffline) return const AuthOutcome(AuthStep.signedIn, mock: true);
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
      return const AuthOutcome(AuthStep.signedIn);
    } on FirebaseAuthException catch (e) {
      if (_isConnectivity(e)) {
        return const AuthOutcome(AuthStep.signedIn, mock: true);
      }
      return AuthOutcome(AuthStep.failed, message: '$label: ${_friendly(e)}');
    } catch (e) {
      return AuthOutcome(AuthStep.failed, message: e.toString());
    }
  }

  bool _isConnectivity(FirebaseAuthException e) =>
      e.code == 'network-request-failed' ||
      e.code == 'unknown' ||
      e.code == 'internal-error';

  String _friendly(FirebaseAuthException e) => switch (e.code) {
        'invalid-phone-number' => l.invalidPhone,
        'invalid-verification-code' => l.incorrectCode,
        'too-many-requests' => l.tooManyAttempts,
        'popup-closed-by-user' => l.signInCancelled,
        'credential-already-in-use' => l.phoneNumberInUse,
        'account-exists-with-different-credential' => l.phoneNumberInUse,
        'requires-recent-login' => l.signInAgainToChangePhone,
        _ => e.message ?? l.genericAuthError,
      };
}
