import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/remote/app_api_data_source.dart';
import 'package:bsharp/data/data_sources/remote/app_api_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppServer {
  int logins = 0;
  int usersCalls = 0;
  final List<String> views = [];
  String? _liveToken;
  bool alwaysUnauthorized = false;

  void expireToken() => _liveToken = null;

  Response<dynamic> handle(RequestOptions options) {
    if (options.path == '/auth.php') {
      logins++;
      _liveToken = 'jwt-$logins';
      return Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'OK', 'token': _liveToken},
      );
    }
    final body = Map<String, dynamic>.from(options.data as Map);
    final view = body['view'] as String;
    views.add(view);
    if (alwaysUnauthorized || body['token'] != _liveToken) {
      return Response<dynamic>(
        requestOptions: options,
        statusCode: 401,
        data: {'status': 'ERROR', 'message': 'Sesja wygasła'},
      );
    }
    if (view == 'users') {
      usersCalls++;
    }
    return Response<dynamic>(
      requestOptions: options,
      statusCode: 200,
      data: {
        'v': 1,
        'serverTime': '2026-10-04T21:06:32+02:00',
        'ttlFresh': 60,
        'ttlRetain': 1209600,
        'data': {'view': view},
      },
    );
  }
}

AppApiSession _sessionFor(_FakeAppServer server) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) =>
            handler.resolve(server.handle(options)),
      ),
    );
  return AppApiSession(
    api: AppApiDataSource(client: dio),
    login: 'parent',
    password: 'secret',
  );
}

void main() {
  group('AppApiSession', () {
    test('logs in once for any number of views', () async {
      final server = _FakeAppServer();
      final session = _sessionFor(server);

      for (final view in ['terms', 'marks', 'tests', 'reprimands']) {
        expect(await session.getView(view), isA<Success<ViewPayload>>());
      }

      expect(server.logins, 1);
    });

    test('logs in again once after a 401 and replays the view', () async {
      final server = _FakeAppServer();
      final session = _sessionFor(server);
      await session.getView('terms');
      server.expireToken();

      final result = await session.getView('marks');

      expect(result, isA<Success<ViewPayload>>());
      expect(server.logins, 2);
      expect(server.views, ['terms', 'marks', 'marks']);
    });

    test(
      'gives up with SessionExpired when the fresh token is refused too',
      () async {
        final server = _FakeAppServer()..alwaysUnauthorized = true;
        final session = _sessionFor(server);

        final result = await session.getView('terms');

        expect(result.failureOrNull, isA<SessionExpired>());
        expect(server.logins, 2);
      },
    );

    test('serialises concurrent calls behind one login', () async {
      final server = _FakeAppServer();
      final session = _sessionFor(server);

      await Future.wait([
        session.getView('terms'),
        session.getView('marks'),
        session.getView('tests'),
      ]);

      expect(server.logins, 1);
    });

    test('fetches the account once and again after a re-login', () async {
      final server = _FakeAppServer();
      final session = _sessionFor(server);

      await session.account();
      await session.account();
      server.expireToken();
      await session.getView('terms');
      await session.account();

      expect(server.usersCalls, 2);
    });

    test('passes an errno failure through without logging in again', () async {
      final server = _FakeAppServer();
      final session = _sessionFor(server);
      await session.getView('terms');

      final result = await session.getView('nope-errno');

      expect(result, isA<Success<ViewPayload>>());
      expect(server.logins, 1);
    });
  });
}
