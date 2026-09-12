import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/domain/failure_messages.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('failureMessage', () {
    test('maps InvalidCredentials', () {
      expect(
        failureMessage(const InvalidCredentials()),
        t.accounts.credentialsInvalid,
      );
    });

    test('maps SchoolNotFound', () {
      expect(failureMessage(const SchoolNotFound()), t.errors.schoolNotFound);
    });

    test('maps NoConnection', () {
      expect(failureMessage(const NoConnection()), t.errors.noConnection);
    });

    test('maps ConnectionTimeout', () {
      expect(failureMessage(const ConnectionTimeout()), t.errors.timeout);
    });

    test('maps LicenseExpired', () {
      expect(failureMessage(const LicenseExpired()), t.errors.licenseExpired);
    });

    test('falls back to the unknown error message', () {
      expect(
        failureMessage(const MissingCredentials()),
        t.errors.unknownError,
      );
    });
  });
}
