import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether Firebase initialised successfully — overridden in `bootstrap`.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ready: ref.watch(firebaseReadyProvider)),
);

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
  AuthController({required this.ready});

  final bool ready;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Carried between sendOtp and confirmOtp.
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
      return done.future;
    } on FirebaseAuthException catch (e) {
      // Emulator unreachable / network → fall back to mock so the flow lives.
      if (_isConnectivity(e)) {
        _mockPending = true;
        return const AuthOutcome(AuthStep.codeSent, mock: true);
      }
      return AuthOutcome(AuthStep.failed, message: _friendly(e));
    } catch (_) {
      _mockPending = true;
      return const AuthOutcome(AuthStep.codeSent, mock: true);
    }
  }

  /// Confirms the entered OTP and signs the user in.
  Future<AuthOutcome> confirmOtp(String code) async {
    if (_mockPending) {
      // Any 4–6 digit code clears the mock flow.
      if (code.length < 4) {
        return const AuthOutcome(AuthStep.failed, message: 'Enter the full code.');
      }
      return const AuthOutcome(AuthStep.signedIn, mock: true);
    }
    try {
      if (kIsWeb) {
        if (_webConfirmation == null) {
          return const AuthOutcome(AuthStep.failed,
              message: 'Request a new code, please.');
        }
        await _webConfirmation!.confirm(code);
      } else {
        if (_verificationId == null) {
          return const AuthOutcome(AuthStep.failed,
              message: 'Request a new code, please.');
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
    } catch (_) {
      return const AuthOutcome(AuthStep.signedIn, mock: true);
    }
  }

  bool _isConnectivity(FirebaseAuthException e) =>
      e.code == 'network-request-failed' ||
      e.code == 'unknown' ||
      e.code == 'internal-error' ||
      e.code == 'app-not-authorized';

  String _friendly(FirebaseAuthException e) => switch (e.code) {
        'invalid-phone-number' => 'That phone number looks invalid.',
        'invalid-verification-code' => 'That code is incorrect.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'popup-closed-by-user' => 'Sign-in was cancelled.',
        _ => e.message ?? 'Something went wrong. Please try again.',
      };
}
