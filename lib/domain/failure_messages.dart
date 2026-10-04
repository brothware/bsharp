import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/l10n/strings.g.dart';

String failureMessage(AppFailure failure) {
  return switch (failure) {
    InvalidCredentials() => t.accounts.credentialsInvalid,
    SchoolNotFound() => t.errors.schoolNotFound,
    NoConnection() => t.errors.noConnection,
    ConnectionTimeout() => t.errors.timeout,
    _ => t.errors.unknownError,
  };
}
