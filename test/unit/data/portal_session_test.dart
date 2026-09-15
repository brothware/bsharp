import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/data/data_sources/remote/portal_data_source.dart';
import 'package:bsharp/data/data_sources/remote/portal_session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the live portal, which behaves like this:
/// the login token authenticates exactly one call, the `users` view trades it
/// for a `sid` that authenticates every later call, and a second login throws
/// away the session the first one opened.
class _FakePortalServer {
  int loginCount = 0;
  int issued = 0;
  String? _liveToken;
  String? _liveSid;
  final List<Map<String, dynamic>> apiRequests = [];

  String? get liveSid => _liveSid;

  String _nextId() => (++issued).toRadixString(16).padLeft(32, 'a');

  String logIn() {
    loginCount++;
    _liveToken = _nextId();
    _liveSid = null;
    return _liveToken!;
  }

  void expireSession() => _liveSid = null;

  Map<String, dynamic> handle(Map<String, dynamic> body) {
    apiRequests.add(body);
    final token = body['token'] as String? ?? '';
    final sid = body['sid'] as String? ?? '';
    final view = body['view'] as String? ?? '';

    if (sid.isNotEmpty && sid == _liveSid) {
      return _viewPayload(view);
    }

    if (view == 'users' && token.isNotEmpty && token == _liveToken) {
      _liveToken = null;
      _liveSid = _nextId();
      return {'sid': _liveSid, 'messagesToken': 'messages-token'};
    }

    return {'errno': 102, 'message': 'Login failed, incorrect session id'};
  }

  Map<String, dynamic> _viewPayload(String view) => {
    'count': 1,
    'items': [
      {'view': view},
    ],
  };
}

Dio _loginClient(_FakePortalServer server) {
  return Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = server.logIn();
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 302,
              headers: Headers.fromMap({
                'location': ['https://rodzic.mobireg.pl/sp1/$token'],
              }),
            ),
          );
        },
      ),
    );
}

Dio _portalClient(_FakePortalServer server) {
  return Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final body = Map<String, dynamic>.from(
            options.data as Map<dynamic, dynamic>,
          );
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: server.handle(body),
            ),
            true,
          );
        },
      ),
      ErrorMappingInterceptor(),
    ]);
}

PortalSessionManager _managerFor(_FakePortalServer server) {
  return PortalSessionManager(
    auth: AuthService(webLoginClient: _loginClient(server)),
    portal: PortalDataSource(client: _portalClient(server)),
    school: 'sp1',
    login: 'user',
    password: 'pass',
  );
}

void main() {
  group('PortalSessionManager', () {
    test('logs in once no matter how many views are fetched', () async {
      final server = _FakePortalServer();
      final manager = _managerFor(server);

      for (final view in ['tests', 'homeworks', 'reprimands', 'bulletins']) {
        final result = await manager.getView(view: view, params: {});
        expect(result, isA<Success<Map<String, dynamic>>>());
      }

      expect(server.loginCount, 1);
    });

    test('carries the sid the users view handed out', () async {
      final server = _FakePortalServer();
      final manager = _managerFor(server);

      await manager.getView(view: 'tests', params: {});

      final viewRequest = server.apiRequests.last;
      expect(viewRequest['view'], 'tests');
      expect(viewRequest['sid'], server.liveSid);
    });

    test('logs in again once the server reports the session gone', () async {
      final server = _FakePortalServer();
      final manager = _managerFor(server);

      await manager.getView(view: 'tests', params: {});
      expect(server.loginCount, 1);

      server.expireSession();
      final result = await manager.getView(view: 'homeworks', params: {});

      expect(result, isA<Success<Map<String, dynamic>>>());
      expect(server.loginCount, 2);
    });

    test(
      'keeps the session it recovered instead of logging in again',
      () async {
        final server = _FakePortalServer();
        final manager = _managerFor(server);

        await manager.getView(view: 'tests', params: {});
        server.expireSession();
        await manager.getView(view: 'homeworks', params: {});
        await manager.getView(view: 'reprimands', params: {});

        expect(server.loginCount, 2);
      },
    );

    test(
      'does not log in again when a view fails for another reason',
      () async {
        final server = _FakePortalServer();
        final manager = _managerFor(server);
        await manager.getView(view: 'tests', params: {});

        final portal = PortalDataSource(
          client: Dio(BaseOptions(baseUrl: 'https://example.test'))
            ..interceptors.addAll([
              InterceptorsWrapper(
                onRequest: (options, handler) => handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: {'errno': 108, 'message': 'Missing parameter'},
                  ),
                  true,
                ),
              ),
              ErrorMappingInterceptor(),
            ]),
        );
        final failing = PortalSessionManager(
          auth: AuthService(webLoginClient: _loginClient(server)),
          portal: portal,
          school: 'sp1',
          login: 'user',
          password: 'pass',
        );

        final result = await failing.getView(view: 'tests', params: {});

        expect(result, isA<Failure<Map<String, dynamic>>>());
        expect(server.loginCount, 2);
      },
    );

    test('exposes the messages token from the session it opened', () async {
      final server = _FakePortalServer();
      final manager = _managerFor(server);

      final result = await manager.ensureSession();

      expect(result.valueOrNull?.messagesToken, 'messages-token');
      expect(server.loginCount, 1);
    });
  });
}
