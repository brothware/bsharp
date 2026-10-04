import 'package:bsharp/core/error/error_messages.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('errorMessage', () {
    test('InvalidCredentials returns credentials message', () {
      expect(
        errorMessage(const InvalidCredentials()),
        contains('username or password'),
      );
    });

    test('NoConnection returns network message', () {
      expect(errorMessage(const NoConnection()), contains('connection'));
    });

    test('ConnectionTimeout returns timeout message', () {
      expect(errorMessage(const ConnectionTimeout()), contains('timed out'));
    });

    test('DatabaseError returns database message', () {
      expect(errorMessage(const DatabaseError()), contains('Database'));
    });

    test('ProtocolMismatch returns protocol message', () {
      expect(errorMessage(const ProtocolMismatch()), contains('protocol'));
    });

    test('DatabaseIdChanged returns sync message', () {
      expect(
        errorMessage(const DatabaseIdChanged()),
        contains('synchronisation'),
      );
    });

    test('UnknownFailure with message returns that message', () {
      expect(
        errorMessage(const UnknownFailure(message: 'test error')),
        'test error',
      );
    });

    test('UnknownFailure without message returns generic', () {
      expect(errorMessage(const UnknownFailure()), contains('unexpected'));
    });

    test('ViewNotFound returns not found message', () {
      expect(errorMessage(const ViewNotFound()), contains('not found'));
    });

    test('SessionExpired returns session message', () {
      expect(errorMessage(const SessionExpired()), contains('Session expired'));
    });

    test('all failure types produce non-empty messages', () {
      final failures = <AppFailure>[
        const InvalidCredentials(),
        const ViewNotFound(),
        const NoData(),
        const NoConnection(),
        const ConnectionTimeout(),
        const SessionExpired(),
        const DatabaseError(),
        const ProtocolMismatch(),
        const DatabaseIdChanged(),
        const TranslationQuotaExceeded(),
        const TranslationFailed(),
        const PupilNotOnAccount(),
        const UnknownFailure(),
      ];

      for (final failure in failures) {
        expect(
          errorMessage(failure),
          isNotEmpty,
          reason: '${failure.runtimeType} should produce non-empty message',
        );
      }
    });
  });

  group('isRetryable', () {
    test('NoConnection is retryable', () {
      expect(isRetryable(const NoConnection()), isTrue);
    });

    test('ConnectionTimeout is retryable', () {
      expect(isRetryable(const ConnectionTimeout()), isTrue);
    });

    test('InvalidCredentials is not retryable', () {
      expect(isRetryable(const InvalidCredentials()), isFalse);
    });

    test('UnknownFailure is not retryable', () {
      expect(isRetryable(const UnknownFailure()), isFalse);
    });
  });
}
