import 'dart:convert';

import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:dio/dio.dart';

import 'fixtures.dart';

const _unauthorized = 401;
const _ok = 200;
const _badRequest = 400;
const _pupilErrno = 102;
const _mailFolders = ['inbox', 'sent', 'trash'];
const _sentMessageId = 777;

class _FakeAppApiFactory extends ApiClientFactory {
  _FakeAppApiFactory(this._client, this._pocztaClient, String school)
    : super(school: school);

  final Dio _client;
  final Dio _pocztaClient;

  @override
  Dio createAppApiClient() => _client;

  @override
  Dio createPocztaClient(String messagingUrl) => _pocztaClient;
}

class FakeAppServer {
  FakeAppServer.fromFixtures();

  final issuedToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e30.fake';
  final views = <String>[];
  final markTermIds = <String>[];
  final timetableRanges = <(String, String)>[];
  final _bodies = <String, Map<String, dynamic>>{};
  final users = loadMobiregFixture('users') as Map<String, dynamic>;
  final staleUsers = <Map<String, dynamic>>[];
  final rejectedPupilIds = <String>{};
  int logins = 0;
  bool rejectsPassword = false;
  int mailSignIns = 0;
  bool mailSignInFails = false;
  bool mailFoldersFail = false;
  bool mailExpiresOnce = false;
  final mailPaths = <String>[];
  final sentMessages = <Map<String, dynamic>>[];
  final uploads = <(String path, String filename)>[];
  final uploadStatuses = <String, List<int>>{};
  Object receivers = <Object>[
    {'id': 'user_201', 'name': 'Anna Nowak', 'role': 'Nauczyciel'},
  ];
  final inbox = <Map<String, dynamic>>[
    {
      'id': 20001,
      'subject': 'Zebranie',
      'date': '2026-10-01T10:00:00',
      'content': 'Tresc',
      'read_at': null,
      'stared': false,
      'author': {'name': 'Anna Nowak'},
    },
  ];

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
    final pocztaClient = Dio(BaseOptions(baseUrl: 'https://poczta.mobireg.pl'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) =>
              handler.resolve(_answerMail(options)),
        ),
      );
    return _FakeAppApiFactory(client, pocztaClient, school);
  }

  Response<dynamic> _answerMail(RequestOptions options) {
    mailPaths.add(options.path);
    if (options.path.startsWith('/sso/')) {
      mailSignIns++;
      return Response<dynamic>(
        requestOptions: options,
        statusCode: _ok,
        headers: Headers.fromMap({
          if (!mailSignInFails) 'set-cookie': ['laravel_session=fake; path=/'],
        }),
      );
    }
    if (mailExpiresOnce) {
      mailExpiresOnce = false;
      return Response<dynamic>(
        requestOptions: options,
        statusCode: _unauthorized,
      );
    }
    if (options.method == 'PUT' && options.path == '/api/messages') {
      sentMessages.add(Map<String, dynamic>.from(options.data as Map));
      return Response<dynamic>(
        requestOptions: options,
        statusCode: _ok,
        data: {'id': _sentMessageId},
      );
    }
    if (options.path.endsWith('/files') && options.data is FormData) {
      final filename = (options.data as FormData).files.single.value.filename!;
      uploads.add((options.path, filename));
      final statuses = uploadStatuses[filename];
      final status = statuses == null || statuses.isEmpty
          ? _ok
          : statuses.removeAt(0);
      return Response<dynamic>(requestOptions: options, statusCode: status);
    }
    final folder = _mailFolders
        .where((name) => options.path == '/api/messages/$name')
        .firstOrNull;
    if (folder != null) {
      if (mailFoldersFail) {
        return Response<dynamic>(
          requestOptions: options,
          statusCode: _badRequest,
        );
      }
      final items = folder == 'inbox' ? inbox : <Map<String, dynamic>>[];
      return Response<dynamic>(
        requestOptions: options,
        statusCode: _ok,
        data: {'items': items, 'total': items.length},
      );
    }
    if (options.path == '/api/messages/receivers/search') {
      return Response<dynamic>(
        requestOptions: options,
        statusCode: _ok,
        data: receivers,
      );
    }
    return Response<dynamic>(
      requestOptions: options,
      statusCode: _ok,
      data: <String, dynamic>{},
    );
  }

  Response<dynamic> _answer(RequestOptions options) {
    if (options.path == '/auth.php') {
      logins++;
      if (rejectsPassword) {
        return _respond(options, _ok, {
          'status': 'ERROR',
          'message': 'Nieprawidłowy login lub hasło',
        });
      }
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
    final data = view == 'users' && staleUsers.isNotEmpty
        ? staleUsers.removeAt(0)
        : _isPupilRejected(view, body)
        ? {'errno': _pupilErrno, 'message': 'Authorization error'}
        : _dataFor(view, body);
    return _respond(options, _ok, {
      'v': 1,
      'serverTime': '2026-10-04T21:06:32+02:00',
      'ttlFresh': 60,
      'ttlRetain': 1209600,
      'data': data,
    });
  }

  bool _isPupilRejected(String view, Map<String, dynamic> body) {
    const accountViews = {'users', 'register-fcm', 'notif-settings'};
    if (accountViews.contains(view)) {
      return false;
    }
    if (rejectedPupilIds.contains(body['pupilId'])) {
      return true;
    }
    final pupils = (users['pupils'] as List).cast<Map<String, dynamic>>();
    return !pupils.any((pupil) => '${pupil['id']}' == body['pupilId']);
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
