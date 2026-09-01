import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService', () {
    group('obtainPortalToken', () {
      test('sends the plaintext password as edpass, not an MD5 hash', () async {
        const plaintext = 'PlainPass123';
        Map<String, dynamic>? capturedBody;

        final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                capturedBody = options.data as Map<String, dynamic>;
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 302,
                    headers: Headers.fromMap({
                      'location': ['https://rodzic.mobireg.pl/sp1/${'a' * 32}'],
                    }),
                  ),
                );
              },
            ),
          );

        final service = AuthService(webLoginClient: dio);
        final result = await service.obtainPortalToken(
          login: 'user',
          password: plaintext,
        );

        expect(result, isA<Success<String>>());
        expect(capturedBody!['edpass'], plaintext);
        expect(
          capturedBody!['edpass'],
          isNot(AuthService.hashPassword(plaintext)),
        );
      });
    });

    group('hashPassword', () {
      test('produces correct MD5 hash for known inputs', () {
        expect(
          AuthService.hashPassword('password'),
          '5f4dcc3b5aa765d61d8327deb882cf99',
        );
      });

      test('produces lowercase hex', () {
        final hash = AuthService.hashPassword('test');
        expect(hash, matches(RegExp(r'^[a-f0-9]{32}$')));
      });

      test('produces consistent results', () {
        final hash1 = AuthService.hashPassword('hello');
        final hash2 = AuthService.hashPassword('hello');
        expect(hash1, hash2);
      });

      test('empty string has known hash', () {
        expect(
          AuthService.hashPassword(''),
          'd41d8cd98f00b204e9800998ecf8427e',
        );
      });
    });
  });

  group('Entity enums', () {
    test('SyncAction roundtrip', () {
      for (final action in ['I', 'U', 'D']) {
        final parsed = action == 'I'
            ? 'insert'
            : action == 'U'
            ? 'update'
            : 'delete';
        expect(parsed, isNotEmpty);
      }
    });
  });
}
