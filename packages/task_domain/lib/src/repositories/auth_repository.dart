import 'package:task_core/task_core.dart';

/// Opaque handle returned after an OTP is dispatched, passed back on verify.
/// The concrete value (Firebase verificationId) is an implementation detail.
typedef OtpSession = String;

/// Authentication boundary for phone-OTP sign-in (PRD §1.1, primary auth).
///
/// Implemented in `task_data` over Firebase Auth + App Check. The domain knows
/// nothing about Firebase — only this contract.
abstract interface class AuthRepository {
  /// Emits the current user id, or `null` when signed out.
  Stream<String?> authStateChanges();

  /// Dispatch an OTP to [e164PhoneNumber]. Returns a session token to verify.
  Future<Result<OtpSession, Failure>> requestOtp(String e164PhoneNumber);

  /// Verify [smsCode] against [session]. Returns the authenticated user id.
  Future<Result<String, Failure>> verifyOtp({
    required OtpSession session,
    required String smsCode,
  });

  Future<Result<void, Failure>> signOut();
}
