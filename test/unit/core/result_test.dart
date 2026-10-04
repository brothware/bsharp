import 'package:bsharp/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success holds value', () {
      const result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('Failure holds failure', () {
      const result = Result<int>.failure(NoConnection());
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isA<NoConnection>());
    });

    test('when dispatches correctly', () {
      const success = Result<int>.success(42);
      const failure = Result<int>.failure(NoConnection());

      final successResult = success.when(
        success: (v) => 'got $v',
        failure: (f) => 'failed',
      );
      expect(successResult, 'got 42');

      final failureResult = failure.when(
        success: (v) => 'got $v',
        failure: (f) => 'failed',
      );
      expect(failureResult, 'failed');
    });

    test('map transforms success value', () {
      const result = Result<int>.success(42);
      final mapped = result.map((v) => v.toString());
      expect(mapped.valueOrNull, '42');
    });

    test('map preserves failure', () {
      const result = Result<int>.failure(NoConnection());
      final mapped = result.map((v) => v.toString());
      expect(mapped.isFailure, isTrue);
    });

    test('flatMap chains results', () {
      const result = Result<int>.success(42);
      final chained = result.flatMap(
        (v) => Result<String>.success('value: $v'),
      );
      expect(chained.valueOrNull, 'value: 42');
    });

    test('flatMap short-circuits on failure', () {
      const result = Result<int>.failure(NoConnection());
      final chained = result.flatMap(
        (v) => Result<String>.success('value: $v'),
      );
      expect(chained.isFailure, isTrue);
    });

    test('pattern matching is exhaustive', () {
      const result = Result<int>.success(42);
      final output = switch (result) {
        Success(:final value) => 'Success: $value',
        Failure(:final failure) => 'Failure: $failure',
      };
      expect(output, 'Success: 42');
    });

    test('Success equality', () {
      expect(
        const Result<int>.success(42),
        equals(const Result<int>.success(42)),
      );
      expect(
        const Result<int>.success(42),
        isNot(equals(const Result<int>.success(43))),
      );
    });

    test('Failure equality', () {
      expect(
        const Result<int>.failure(NoConnection()),
        equals(const Result<int>.failure(NoConnection())),
      );
    });
  });

  group('AppFailure.fromErrno', () {
    test('102 maps to PupilNotOnAccount', () {
      expect(AppFailure.fromErrno(102), isA<PupilNotOnAccount>());
    });

    test('103 maps to ViewNotFound', () {
      expect(AppFailure.fromErrno(103), isA<ViewNotFound>());
    });

    test('the njson errno codes app.php never sends are unknown', () {
      for (final errno in [101, 105, 106, 107, 108, 110, 111, 199, 200, 201]) {
        final failure = AppFailure.fromErrno(errno);
        expect(failure, isA<UnknownFailure>(), reason: '$errno');
        expect((failure as UnknownFailure).errno, errno);
      }
    });

    test('unknown errno maps to UnknownFailure', () {
      final failure = AppFailure.fromErrno(999, 'test');
      expect(failure, isA<UnknownFailure>());
      expect((failure as UnknownFailure).errno, 999);
      expect(failure.message, 'test');
    });

    test('message is preserved', () {
      final failure = AppFailure.fromErrno(102, 'custom msg');
      expect(failure.message, 'custom msg');
    });
  });

  group('AppFailure subtypes', () {
    test('AuthFailure exhaustive matching', () {
      const failures = <AuthFailure>[InvalidCredentials()];

      for (final failure in failures) {
        final result = switch (failure) {
          InvalidCredentials() => 'invalid',
        };
        expect(result, isNotEmpty);
      }
    });

    test('ServerFailure exhaustive matching', () {
      const failures = <ServerFailure>[ViewNotFound(), NoData()];

      for (final failure in failures) {
        final result = switch (failure) {
          ViewNotFound() => 'not_found',
          NoData() => 'no_data',
        };
        expect(result, isNotEmpty);
      }
    });

    test('AppFailure exhaustive matching', () {
      const failures = <AppFailure>[
        InvalidCredentials(),
        ViewNotFound(),
        NoData(),
        NoConnection(),
        ConnectionTimeout(),
        SessionExpired(),
        DatabaseError(),
        ProtocolMismatch(),
        DatabaseIdChanged(),
        SchoolNotFound(),
        TranslationQuotaExceeded(),
        TranslationFailed(),
        PupilNotOnAccount(),
        UnknownFailure(),
      ];

      for (final failure in failures) {
        final result = switch (failure) {
          PupilNotOnAccount() => 'q',
          InvalidCredentials() => 'c',
          ViewNotFound() => 'd',
          NoData() => 'f',
          NoConnection() => 'k',
          ConnectionTimeout() => 'l',
          SessionExpired() => 'm',
          DatabaseError() => 'n',
          ProtocolMismatch() => 'o',
          DatabaseIdChanged() => 'p',
          SchoolNotFound() => 'p2',
          TranslationQuotaExceeded() => 'r',
          TranslationFailed() => 's',
          UnknownFailure() => 'q',
        };
        expect(result, isNotEmpty);
      }
    });

    test('equality works for all failure types', () {
      expect(const NoConnection(), equals(const NoConnection()));
      expect(
        const NoConnection(message: 'a'),
        isNot(equals(const NoConnection(message: 'b'))),
      );
      expect(const ConnectionTimeout(), equals(const ConnectionTimeout()));
      expect(const SessionExpired(), equals(const SessionExpired()));
      expect(const DatabaseError(), equals(const DatabaseError()));
      expect(const ProtocolMismatch(), equals(const ProtocolMismatch()));
      expect(const DatabaseIdChanged(), equals(const DatabaseIdChanged()));
      expect(
        const UnknownFailure(errno: 1),
        equals(const UnknownFailure(errno: 1)),
      );
      expect(
        const UnknownFailure(errno: 1),
        isNot(equals(const UnknownFailure(errno: 2))),
      );
    });
  });
}
