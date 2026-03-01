import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/l10n/strings.g.dart';

String errorMessage(AppFailure failure) {
  return switch (failure) {
    MissingCredentials() => t.errors.missingCredentials,
    ExpiredSession() => t.errors.expiredSession,
    InvalidCredentials() => t.errors.invalidCredentials,
    ViewNotFound() => t.errors.viewNotFound,
    MissingParameter() => t.errors.missingParameter,
    NoData() => t.errors.noData,
    MutationFailed() => t.errors.mutationFailed,
    Informational() => failure.message ?? t.errors.informational,
    LicenseExpired() => t.errors.licenseExpiredLong,
    RateLimited() => t.errors.rateLimitedLong,
    NoConnection() => t.errors.noConnection,
    ConnectionTimeout() => t.errors.timeoutLong,
    SessionExpired() => t.errors.sessionExpired,
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
    RateLimited() => true,
    MutationFailed() => true,
    _ => false,
  };
}
