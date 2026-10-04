import 'dart:convert';

import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:dio/dio.dart';

import 'fixtures.dart';

const _unauthorized = 401;
const _ok = 200;

class _FakeAppApiFactory extends ApiClientFactory {
  _FakeAppApiFactory(this._client, String school)
    : super(school: school, parentLogin: '', parentPassHash: '');

  final Dio _client;

  @override
  Dio createAppApiClient() => _client;
}

class FakeAppServer {
  FakeAppServer.fromFixtures();

  final issuedToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e30.fake';
  final views = <String>[];
  final markTermIds = <String>[];
  final timetableRanges = <(String, String)>[];
  final _bodies = <String, Map<String, dynamic>>{};
  final users = loadMobiregFixture('users') as Map<String, dynamic>;
  int logins = 0;

  Map<String, dynamic> lastBodyFor(String view) => _bodies[view]!;

  ApiClientFactory factoryFor(String school) {
    final client =
        Dio(BaseOptions(baseUrl: 'https://mobireg.pl/$school/modules/api'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) =>
                  handler.resolve(_answer(options)),
            ),
          );
    return _FakeAppApiFactory(client, school);
  }

  Response<dynamic> _answer(RequestOptions options) {
    if (options.path == '/auth.php') {
      logins++;
      return _respond(options, _ok, {'status': 'OK', 'token': issuedToken});
    }
    final body = Map<String, dynamic>.from(options.data as Map);
    final authorized =
        body['token'] == issuedToken || body['JWTToken'] == issuedToken;
    if (!authorized) {
      return _respond(options, _unauthorized, {'message': 'Unauthorized'});
    }
    final view = body['view'] as String;
    views.add(view);
    _bodies[view] = body;
    return _respond(options, _ok, {
      'v': 1,
      'serverTime': '2026-10-04T21:06:32+02:00',
      'ttlFresh': 60,
      'ttlRetain': 1209600,
      'data': _dataFor(view, body),
    });
  }

  Object _dataFor(String view, Map<String, dynamic> body) {
    switch (view) {
      case 'marks':
        final termId = body['termId'] as String;
        markTermIds.add(termId);
        return loadMobiregFixture(
          termId == '4' ? 'marks_term4' : 'marks_empty',
        );
      case 'timetable-events':
        timetableRanges.add((
          body['dateFrom'] as String,
          body['dateTo'] as String,
        ));
        return loadMobiregFixture('timetable_events');
      case 'attendance-stats':
        return loadMobiregFixture('attendance_stats');
      case 'users':
        return users;
      case 'register-fcm':
        return {'success': true};
      default:
        return loadMobiregFixture(view);
    }
  }

  Response<dynamic> _respond(RequestOptions options, int status, Object body) =>
      Response<dynamic>(
        requestOptions: options,
        statusCode: status,
        data: jsonEncode(body),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html; charset=UTF-8'],
        }),
      );
}
