import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether Firebase initialised successfully — overridden in `bootstrap`.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ready: ref.watch(firebaseReadyProvider)),
);

/// The current signed-in user, or null. Emits null whenever Firebase is
/// unavailable (mock mode) so mock sessions deterministically land on sign-in.
final authStateProvider = StreamProvider<User?>((ref) {
  final bool ready = ref.watch(firebaseReadyProvider);
  if (!ready) return Stream<User?>.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

enum AuthStep { codeSent, signedIn, failed }

/// Outcome of an account-deletion attempt. [needsReauth] means Firebase wants a
/// recent login first — the caller must re-authenticate, then retry.
enum DeleteAccountResult { deleted, needsReauth, failed }

@immutable
class AuthOutcome {
  const AuthOutcome(this.step, {this.message, this.mock = false});
  final AuthStep step;
  final String? message;

  /// True when served through the local mock (Firebase unavailable).
  final bool mock;

  bool get ok => step != AuthStep.failed;
}

/// Drives phone-OTP and social sign-in for technicians. Uses real [FirebaseAuth]
/// when available; if Firebase is down it falls back to a local mock so the app
/// stays navigable in dev.
class AuthController {
  AuthController({required this.ready});

  final bool ready;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  ConfirmationResult? _webConfirmation;
  String? _verificationId;
  bool _mockPending = false;

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
            done.complete(AuthOutcome(AuthStep.failed, message: _friendly(e)));
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
      return done.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => const AuthOutcome(AuthStep.failed,
            message: 'Something went wrong. Please try again.'),
      );
    } on FirebaseAuthException catch (e) {
      return AuthOutcome(AuthStep.failed, message: '[${e.code}] ${_friendly(e)}');
    } catch (e) {
      return AuthOutcome(AuthStep.failed, message: e.toString());
    }
  }

  /// Confirms the entered OTP and signs the technician in.
  Future<AuthOutcome> confirmOtp(String code) async {
    if (_mockPending) {
      if (code.length < 4) {
        return const AuthOutcome(AuthStep.failed,
            message: 'Enter the full code.');
      }
      return const AuthOutcome(AuthStep.signedIn, mock: true);
    }
    try {
      if (kIsWeb) {
        if (_webConfirmation == null) {
          return const AuthOutcome(AuthStep.failed,
              message: 'Request a new code.');
        }
        await _webConfirmation!.confirm(code);
      } else {
        if (_verificationId == null) {
          return const AuthOutcome(AuthStep.failed,
              message: 'Request a new code.');
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

  Future<AuthOutcome> signInWithGoogle() =>
      _oauth(GoogleAuthProvider(), 'Google');

  Future<AuthOutcome> signInWithApple() => _oauth(AppleAuthProvider(), 'Apple');

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

  /// Signs the technician out. No-op in mock mode.
  Future<void> signOut() async {
    if (_looksOffline) return;
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  // Carried between startReauthOtp and confirmReauthOtp.
  String? _reauthVerificationId;
  bool _mockReauthPending = false;

  /// Whether the pro re-authenticates by phone OTP (has a phone number) versus a
  /// social provider popup. Drives the deletion reauth path.
  bool get reauthUsesPhone => (_auth.currentUser?.phoneNumber ?? '').isNotEmpty;

  /// Permanently deletes the signed-in pro's Firebase Auth account. [cleanup]
  /// runs first, while still authenticated, so it can remove device tokens under
  /// the security rules. Returns [DeleteAccountResult.needsReauth] when Firebase
  /// requires a recent login.
  Future<DeleteAccountResult> deleteAccount(
      {Future<void> Function()? cleanup}) async {
    if (_looksOffline) {
      await _safeCleanup(cleanup);
      return DeleteAccountResult.deleted;
    }
    final User? user = _auth.currentUser;
    if (user == null) return DeleteAccountResult.deleted;
    try {
      await _safeCleanup(cleanup);
      await user.delete();
      return DeleteAccountResult.deleted;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return DeleteAccountResult.needsReauth;
      }
      return DeleteAccountResult.failed;
    } catch (_) {
      return DeleteAccountResult.failed;
    }
  }

  Future<void> _safeCleanup(Future<void> Function()? cleanup) async {
    if (cleanup == null) return;
    try {
      await cleanup();
    } catch (_) {/* best-effort: still proceed with deletion */}
  }

  /// Sends a re-auth OTP to the pro's own phone number. Used before deletion
  /// when [reauthUsesPhone] is true.
  Future<AuthOutcome> startReauthOtp() async {
    _reauthVerificationId = null;
    _mockReauthPending = false;
    if (_looksOffline) {
      _mockReauthPending = true;
      return const AuthOutcome(AuthStep.codeSent, mock: true);
    }
    final User? user = _auth.currentUser;
    final String phone = user?.phoneNumber ?? '';
    if (user == null || phone.isEmpty) {
      return const AuthOutcome(AuthStep.failed,
          message: 'Could not verify your identity.');
    }
    try {
      final Completer<AuthOutcome> done = Completer<AuthOutcome>();
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential _) {},
        verificationFailed: (FirebaseAuthException e) {
          if (!done.isCompleted) {
            done.complete(AuthOutcome(AuthStep.failed, message: _friendly(e)));
          }
        },
        codeSent: (String id, int? _) {
          _reauthVerificationId = id;
          if (!done.isCompleted) {
            done.complete(const AuthOutcome(AuthStep.codeSent));
          }
        },
        codeAutoRetrievalTimeout: (String id) => _reauthVerificationId = id,
      );
      return done.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => const AuthOutcome(AuthStep.failed,
            message: 'Something went wrong. Please try again.'),
      );
    } on FirebaseAuthException catch (e) {
      return AuthOutcome(AuthStep.failed, message: '[${e.code}] ${_friendly(e)}');
    } catch (e) {
      return AuthOutcome(AuthStep.failed, message: e.toString());
    }
  }

  /// Confirms the re-auth OTP and re-authenticates, satisfying the recent-login
  /// requirement for deletion.
  Future<AuthOutcome> confirmReauthOtp(String code) async {
    if (_mockReauthPending) {
      if (code.length < 4) {
        return const AuthOutcome(AuthStep.failed,
            message: 'Enter the full code.');
      }
      return const AuthOutcome(AuthStep.signedIn, mock: true);
    }
    final User? user = _auth.currentUser;
    if (user == null || _reauthVerificationId == null) {
      return const AuthOutcome(AuthStep.failed, message: 'Request a new code.');
    }
    try {
      final PhoneAuthCredential cred = PhoneAuthProvider.credential(
          verificationId: _reauthVerificationId!, smsCode: code);
      await user.reauthenticateWithCredential(cred);
      return const AuthOutcome(AuthStep.signedIn);
    } on FirebaseAuthException catch (e) {
      return AuthOutcome(AuthStep.failed, message: _friendly(e));
    } catch (e) {
      return AuthOutcome(AuthStep.failed, message: e.toString());
    }
  }

  /// Re-authenticates a social (Google/Apple) user via the provider flow.
  Future<AuthOutcome> reauthenticateWithSocial() async {
    if (_looksOffline) return const AuthOutcome(AuthStep.signedIn, mock: true);
    final User? user = _auth.currentUser;
    if (user == null) {
      return const AuthOutcome(AuthStep.failed,
          message: 'Could not verify your identity.');
    }
    final String providerId = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : '';
    final AuthProvider provider =
        providerId.contains('apple') ? AppleAuthProvider() : GoogleAuthProvider();
    try {
      if (kIsWeb) {
        await user.reauthenticateWithPopup(provider);
      } else {
        await user.reauthenticateWithProvider(provider);
      }
      return const AuthOutcome(AuthStep.signedIn);
    } on FirebaseAuthException catch (e) {
      return AuthOutcome(AuthStep.failed, message: _friendly(e));
    } catch (e) {
      return AuthOutcome(AuthStep.failed, message: e.toString());
    }
  }

  bool _isConnectivity(FirebaseAuthException e) =>
      e.code == 'network-request-failed' ||
      e.code == 'unknown' ||
      e.code == 'internal-error';

  String _friendly(FirebaseAuthException e) => switch (e.code) {
        'invalid-phone-number' => 'That phone number looks wrong.',
        'invalid-verification-code' => 'That code is incorrect.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'popup-closed-by-user' => 'Sign-in was cancelled.',
        'credential-already-in-use' => 'That number is already in use.',
        _ => e.message ?? 'Something went wrong. Please try again.',
      };
}
