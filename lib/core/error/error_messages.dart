import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/l10n/strings.g.dart';

String errorMessage(AppFailure failure) {
  return switch (failure) {
    InvalidCredentials() => t.errors.invalidCredentials,
    ViewNotFound() => t.errors.viewNotFound,
    NoData() => t.errors.noData,
    SchoolNotFound() => t.errors.schoolNotFound,
    NoConnection() => t.errors.noConnection,
    ConnectionTimeout() => t.errors.timeoutLong,
    SessionExpired() => t.errors.sessionExpired,
    PupilNotOnAccount() => t.dashboard.pupilNotOnAccount,
    DatabaseError() => t.errors.databaseError,
    ProtocolMismatch() => t.errors.protocolMismatch,
    DatabaseIdChanged() => t.errors.databaseIdChanged,
    TranslationQuotaExceeded() => t.translation.quotaExceeded,
    TranslationFailed() => t.translation.translationFailed,
    UnknownFailure() => failure.message ?? t.errors.unknownFailure,
  };
}

bool isRetryable(AppFailure failure) {
  return switch (failure) {
    NoConnection() => true,
    ConnectionTimeout() => true,
    _ => false,
  };
}
