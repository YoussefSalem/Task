import 'package:meta/meta.dart';
import 'package:task_core/src/failures/failure.dart';

/// A success-or-failure value used across domain boundaries instead of throwing.
///
/// ```dart
/// final Result<User, Failure> r = await repo.signIn(...);
/// return r.fold(
///   onOk: (user) => ...,
///   onErr: (failure) => ...,
/// );
/// ```
@immutable
sealed class Result<S, F extends Failure> {
  const Result();

  /// Wraps a success value.
  const factory Result.ok(S value) = Ok<S, F>;

  /// Wraps a failure.
  const factory Result.err(F failure) = Err<S, F>;

  bool get isOk => this is Ok<S, F>;
  bool get isErr => this is Err<S, F>;

  /// The success value or `null`.
  S? get valueOrNull => switch (this) {
        Ok<S, F>(:final value) => value,
        Err<S, F>() => null,
      };

  /// The failure or `null`.
  F? get failureOrNull => switch (this) {
        Ok<S, F>() => null,
        Err<S, F>(:final failure) => failure,
      };

  /// Exhaustively collapse both branches into a single value.
  T fold<T>({
    required T Function(S value) onOk,
    required T Function(F failure) onErr,
  }) =>
      switch (this) {
        Ok<S, F>(:final value) => onOk(value),
        Err<S, F>(:final failure) => onErr(failure),
      };

  /// Transform the success value, preserving the failure.
  Result<T, F> map<T>(T Function(S value) transform) => switch (this) {
        Ok<S, F>(:final value) => Ok<T, F>(transform(value)),
        Err<S, F>(:final failure) => Err<T, F>(failure),
      };
}

final class Ok<S, F extends Failure> extends Result<S, F> {
  const Ok(this.value);
  final S value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<S, F> && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

final class Err<S, F extends Failure> extends Result<S, F> {
  const Err(this.failure);
  final F failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Err<S, F> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;
}
