import 'package:flutter/foundation.dart' show immutable;

@immutable
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;

  const factory Result.failure(AppFailure failure) = Failure<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success(:final value) => success(value),
      Failure(failure: final f) => failure(f),
    };
  }

  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  AppFailure? get failureOrNull => switch (this) {
    Success() => null,
    Failure(:final failure) => failure,
  };

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Result.success(transform(value)),
      Failure(:final failure) => Result.failure(failure),
    };
  }

  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success(:final value) => transform(value),
      Failure(:final failure) => Result.failure(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Failure($failure)';
}

@immutable
sealed class AppFailure {
  const AppFailure({this.message});

  factory AppFailure.fromErrno(int errno, [String? message]) {
    return switch (errno) {
      101 => AuthFailure.missingCredentials(message: message),
      102 => AuthFailure.expiredSession(message: message),
      103 => ServerFailure.viewNotFound(message: message),
      105 => AuthFailure.invalidCredentials(message: message),
      106 => AuthFailure.invalidCredentials(message: message),
      107 => AuthFailure.invalidCredentials(message: message),
      108 => ServerFailure.missingParameter(message: message),
      110 => ServerFailure.noData(message: message),
      111 => ServerFailure.mutationFailed(message: message),
      199 => ServerFailure.informational(message: message),
      200 => LicenseExpired(message: message),
      201 => RateLimited(message: message),
      _ => UnknownFailure(errno: errno, message: message),
    };
  }

  final String? message;
}

sealed class AuthFailure extends AppFailure {
  const AuthFailure({super.message});

  const factory AuthFailure.missingCredentials({String? message}) =
      MissingCredentials;
  const factory AuthFailure.expiredSession({String? message}) = ExpiredSession;
  const factory AuthFailure.invalidCredentials({String? message}) =
      InvalidCredentials;
}

final class MissingCredentials extends AuthFailure {
  const MissingCredentials({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissingCredentials && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class ExpiredSession extends AuthFailure {
  const ExpiredSession({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpiredSession && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class InvalidCredentials extends AuthFailure {
  const InvalidCredentials({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvalidCredentials && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

sealed class ServerFailure extends AppFailure {
  const ServerFailure({super.message});

  const factory ServerFailure.viewNotFound({String? message}) = ViewNotFound;
  const factory ServerFailure.missingParameter({String? message}) =
      MissingParameter;
  const factory ServerFailure.noData({String? message}) = NoData;
  const factory ServerFailure.mutationFailed({String? message}) =
      MutationFailed;
  const factory ServerFailure.informational({String? message}) = Informational;
}

final class ViewNotFound extends ServerFailure {
  const ViewNotFound({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ViewNotFound && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class MissingParameter extends ServerFailure {
  const MissingParameter({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissingParameter && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class NoData extends ServerFailure {
  const NoData({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoData && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class MutationFailed extends ServerFailure {
  const MutationFailed({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MutationFailed && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class Informational extends ServerFailure {
  const Informational({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Informational && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class LicenseExpired extends AppFailure {
  const LicenseExpired({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LicenseExpired && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class RateLimited extends AppFailure {
  const RateLimited({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RateLimited && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class NoConnection extends AppFailure {
  const NoConnection({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoConnection && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class ConnectionTimeout extends AppFailure {
  const ConnectionTimeout({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionTimeout && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class SessionExpired extends AppFailure {
  const SessionExpired({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionExpired && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class DatabaseError extends AppFailure {
  const DatabaseError({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseError && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class ProtocolMismatch extends AppFailure {
  const ProtocolMismatch({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProtocolMismatch && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class DatabaseIdChanged extends AppFailure {
  const DatabaseIdChanged({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseIdChanged && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class TranslationQuotaExceeded extends AppFailure {
  const TranslationQuotaExceeded({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationQuotaExceeded && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class TranslationFailed extends AppFailure {
  const TranslationFailed({super.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationFailed && message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({this.errno, super.message});

  final int? errno;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnknownFailure &&
          errno == other.errno &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, errno, message);
}
