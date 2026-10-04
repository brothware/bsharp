import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/remote/app_api_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _jwt = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e30.sig';

Dio _client(
  Response<dynamic> Function(RequestOptions options) answer,
  List<RequestOptions> seen,
) {
  return Dio(BaseOptions(baseUrl: 'https://mobireg.pl/sp1/modules/api'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          seen.add(options);
          handler.resolve(answer(options));
        },
      ),
    );
}

Response<dynamic> _json(RequestOptions options, int status, Object body) =>
    Response<dynamic>(requestOptions: options, statusCode: status, data: body);

Map<String, dynamic> _envelope(Object data, {int version = 1}) => {
  'v': version,
  'serverTime': '2026-10-04T21:06:32+02:00',
  'ttlFresh': 60,
  'ttlRetain': 1209600,
  'data': data,
};

void main() {
  group('AppApiDataSource.login', () {
    test('posts plaintext JSON credentials and returns the token', () async {
      final seen = <RequestOptions>[];
      final source = AppApiDataSource(
        client: _client(
          (o) => _json(o, 200, {
            'status': 'OK',
            'token': _jwt,
            'user': {'id': 1},
          }),
          seen,
        ),
      );

      final result = await source.login(login: 'parent', password: 'p@ss');

      expect(result.valueOrNull, _jwt);
      expect(seen.single.path, '/auth.php');
      expect(seen.single.data, {'login': 'parent', 'password': 'p@ss'});
      expect(seen.single.contentType, 'application/json; charset=UTF-8');
      expect(seen.single.headers['Accept'], 'application/json');
    });

    test('maps a refused login to InvalidCredentials', () async {
      final source = AppApiDataSource(
        client: _client(
          (o) => _json(o, 200, {'status': 'ERROR', 'message': 'Błędny login'}),
          [],
        ),
      );

      final result = await source.login(login: 'parent', password: 'bad');

      expect(result.failureOrNull, isA<InvalidCredentials>());
    });
  });

  group('AppApiDataSource.getView', () {
    test('sends the official form fields in order and unwraps data', () async {
      final seen = <RequestOptions>[];
      final source = AppApiDataSource(
        client: _client(
          (o) => _json(
            o,
            200,
            _envelope([
              {'id': 1},
            ]),
          ),
          seen,
        ),
      );

      final result = await source.getView(
        jwt: _jwt,
        view: 'terms',
        params: {'pupilId': '6339'},
      );

      final payload = result.valueOrNull!;
      expect(payload.data, [
        {'id': 1},
      ]);
      expect(payload.freshFor, const Duration(seconds: 60));
      expect(payload.serverTime, DateTime.parse('2026-10-04T21:06:32+02:00'));
      expect(seen.single.path, '/app.php');
      expect((seen.single.data as Map).keys.toList(), [
        'view',
        'format',
        'token',
        'JWTToken',
        'pupilId',
      ]);
      expect(seen.single.data, {
        'view': 'terms',
        'format': 'json',
        'token': _jwt,
        'JWTToken': _jwt,
        'pupilId': '6339',
      });
      expect(seen.single.headers['User-Agent'], AppConstants.appUserAgent);
      expect(seen.single.contentType, Headers.formUrlEncodedContentType);
    });

    test('maps HTTP 401 to SessionExpired', () async {
      final source = AppApiDataSource(
        client: _client(
          (o) => _json(o, 401, {
            'status': 'ERROR',
            'message': 'Nieprawidłowy podpis tokenu (fałszerstwo)',
          }),
          [],
        ),
      );

      final result = await source.getView(jwt: _jwt, view: 'terms');

      expect(result.failureOrNull, isA<SessionExpired>());
    });

    test('maps errno 102 inside the envelope to ExpiredSession', () async {
      final source = AppApiDataSource(
        client: _client(
          (o) => _json(
            o,
            200,
            _envelope({'errno': 102, 'message': 'Authorization error'}),
          ),
          [],
        ),
      );

      final result = await source.getView(jwt: _jwt, view: 'terms');

      expect(result.failureOrNull, isA<ExpiredSession>());
    });

    test('maps errno 103 to ViewNotFound', () async {
      final source = AppApiDataSource(
        client: _client(
          (o) => _json(
            o,
            200,
            _envelope({'errno': 103, 'message': 'No view exist'}),
          ),
          [],
        ),
      );

      final result = await source.getView(jwt: _jwt, view: 'nope');

      expect(result.failureOrNull, isA<ViewNotFound>());
    });

    test('refuses an envelope of another protocol version', () async {
      final source = AppApiDataSource(
        client: _client(
          (o) => _json(o, 200, _envelope(<Object>[], version: 2)),
          [],
        ),
      );

      final result = await source.getView(jwt: _jwt, view: 'terms');

      expect(result.failureOrNull, isA<ProtocolMismatch>());
    });

    test('rejects a body without the envelope as a FormatException', () async {
      final source = AppApiDataSource(
        client: _client((o) => _json(o, 200, {'items': <Object>[]}), []),
      );

      expect(
        () => source.getView(jwt: _jwt, view: 'terms'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
