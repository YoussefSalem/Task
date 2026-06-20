import 'package:meta/meta.dart';

/// Base type for every recoverable error that crosses a domain boundary.
///
/// Implementations are exhaustive (a `sealed` hierarchy) so callers can switch
/// over them without a default branch. Infrastructure exceptions (Firebase,
/// Dio, Drift) are mapped to a [Failure] in the data layer; they never leak
/// into domain or presentation.
@immutable
sealed class Failure {
  const Failure(this.message, {this.cause, this.stackTrace});

  /// Human-facing, localizable key or message describing the failure.
  final String message;

  /// The originating error, if any (kept for logging/Crashlytics).
  final Object? cause;

  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

/// No connectivity, timeout, or transport-level error.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause, super.stackTrace});
}

/// Authentication / OTP / session errors.
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause, super.stackTrace});
}

/// Input or business-rule validation errors (e.g. missing before/after image).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause, super.stackTrace});
}

/// The caller is not allowed to perform the action (security rules, role gate).
final class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause, super.stackTrace});
}

/// Payment-gateway or wallet errors (Paymob, InstaPay, COD reconciliation).
final class PaymentFailure extends Failure {
  const PaymentFailure(super.message, {super.cause, super.stackTrace});
}

/// The device is offline and the action was queued locally instead.
final class OfflineFailure extends Failure {
  const OfflineFailure(super.message, {super.cause, super.stackTrace});
}

/// Anything unanticipated. Always logged as a non-fatal.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause, super.stackTrace});
}
