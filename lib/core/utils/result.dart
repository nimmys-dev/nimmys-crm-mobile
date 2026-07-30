import 'package:equatable/equatable.dart';

import '../error/app_exception.dart';

/// A value or the reason it is missing.
///
/// Repositories return this instead of throwing, which makes the failure path
/// part of the signature: a bloc cannot forget to handle an error, because it
/// cannot read the data without deciding what to do when there is none.
///
/// Exhaustive over [Success] and [FailureResult], so `switch` on a `Result`
/// needs no default branch and the analyzer flags any new variant.
sealed class Result<T> extends Equatable {
  const Result();

  const factory Result.success(T data) = Success<T>;

  const factory Result.failure(AppException exception) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is FailureResult<T>;

  /// The value, or null when this is a failure. Prefer [fold] or a `switch`;
  /// this is here for the terse call sites where null genuinely is fine.
  T? get dataOrNull => switch (this) {
    Success<T>(data: final T data) => data,
    FailureResult<T>() => null,
  };

  AppException? get exceptionOrNull => switch (this) {
    Success<T>() => null,
    FailureResult<T>(exception: final AppException exception) => exception,
  };

  /// Collapse both branches into one value.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException exception) onFailure,
  }) => switch (this) {
    Success<T>(data: final T data) => onSuccess(data),
    FailureResult<T>(exception: final AppException exception) =>
      onFailure(exception),
  };

  /// Transform the value, leaving a failure untouched.
  ///
  /// This is what lets a repository map a data-layer model to a domain entity
  /// without unwrapping and rewrapping the result by hand.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(data: final T data) => Success<R>(transform(data)),
    FailureResult<T>(exception: final AppException exception) =>
      FailureResult<R>(exception),
  };

  /// Chain another fallible step; the first failure short-circuits the rest.
  Result<R> flatMap<R>(Result<R> Function(T data) transform) => switch (this) {
    Success<T>(data: final T data) => transform(data),
    FailureResult<T>(exception: final AppException exception) =>
      FailureResult<R>(exception),
  };

  @override
  List<Object?> get props => <Object?>[dataOrNull, exceptionOrNull];
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.exception);

  final AppException exception;
}

/// Runs [body] and converts anything it throws into a [FailureResult].
///
/// This is the single try/catch of the data layer. Repository methods stay
/// one expression long, and — importantly — the bare `catch` at the bottom
/// guarantees no raw error can escape a repository no matter what a new data
/// source starts throwing.
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Success<T>(await body());
  } on AppException catch (exception) {
    return FailureResult<T>(exception);
  } catch (error, stackTrace) {
    return FailureResult<T>(
      UnknownException(
        message: error.toString(),
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
