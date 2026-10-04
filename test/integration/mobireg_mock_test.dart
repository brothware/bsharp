@TestOn('vm')
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bsharp/data/providers/mobireg/mobireg_message_handler.dart';
import 'package:bsharp/data/providers/mobireg/parsers/account_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _mockPort = 8090;
const _mockBaseUrl = 'http://localhost:$_mockPort';
const _school = 'osm-wroclaw';
const _apiPath = '/$_school/modules/api';
const _mockLogin = 'user';
const _mockPassword = 'pass';
const _unauthorized = 401;
const _firstPupilId = 6339;
const _protocolVersion = 1;
const _unknownViewErrno = 103;
const _pageSize = 20;
const _firstMessageId = 20001;
const _connectTimeout = Duration(seconds: 1);
const _requestTimeout = Duration(seconds: 5);
const _formContentType = 'application/x-www-form-urlencoded';

Future<bool> _isMockRunning() async {
  try {
    final socket = await Socket.connect(
      'localhost',
      _mockPort,
      timeout: _connectTimeout,
    );
    await socket.close();
    return true;
  } on SocketException {
    return false;
  }
}

void main() {
  late Dio dio;

  setUpAll(() async {
    if (!await _isMockRunning()) {
      fail(
        'mobireg-mock not running on localhost:$_mockPort. '
        'Start with: cd lib/data/providers/mobireg/test-mock && npm start',
      );
    }
    dio = Dio(
      BaseOptions(
        baseUrl: _mockBaseUrl,
        connectTimeout: _requestTimeout,
        receiveTimeout: _requestTimeout,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  });

  tearDownAll(() => dio.close());

  Future<String> login() async {
    final response = await dio.post<Map<String, dynamic>>(
      '$_apiPath/auth.php',
      data: {'login': _mockLogin, 'password': _mockPassword},
    );
    return response.data!['token'] as String;
  }

  Future<Response<String>> appCall(Map<String, Object?> fields) {
    return dio.post<String>(
      '$_apiPath/app.php',
      data: fields.map((key, value) => MapEntry(key, '$value')),
      options: Options(
        contentType: _formContentType,
        responseType: ResponseType.plain,
      ),
    );
  }

  Map<String, dynamic> decoded(Response<String> response) =>
      jsonDecode(response.data!) as Map<String, dynamic>;

  group('auth.php', () {
    test('returns a token for valid credentials', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '$_apiPath/auth.php',
        data: {'login': _mockLogin, 'password': _mockPassword},
      );

      expect(response.data!['status'], 'OK');
      expect(response.data!['token'], isA<String>());
    });

    test('rejects wrong credentials with an error message', () async {
      final response = await dio.post<Map<String, dynamic>>(
        '$_apiPath/auth.php',
        data: {'login': _mockLogin, 'password': 'wrong'},
      );

      expect(response.data!['status'], 'ERROR');
      expect(response.data!['message'], isA<String>());
    });
  });

  group('app.php', () {
    test('terms answer in the envelope', () async {
      final token = await login();

      final response = await appCall({
        'view': 'terms',
        'format': 'json',
        'token': token,
        'JWTToken': token,
        'pupilId': _firstPupilId,
      });

      final body = decoded(response);
      expect(body['v'], _protocolVersion);
      expect(body['data'], isA<List<dynamic>>());
      expect(body['data'], isNotEmpty);
    });

    test('users view parses into an account', () async {
      final token = await login();

      final response = await appCall({
        'view': 'users',
        'format': 'json',
        'token': token,
        'JWTToken': token,
      });

      final account = parseAccount(
        decoded(response)['data'] as Map<String, dynamic>,
      );
      expect(account.students, isNotEmpty);
      expect(account.messagingUrl, isNotEmpty);
      expect(account.messagesToken, isNotEmpty);
    });

    test('answers 401 without a token', () async {
      final response = await appCall({
        'view': 'terms',
        'format': 'json',
        'pupilId': _firstPupilId,
      });

      expect(response.statusCode, _unauthorized);
    });

    test('answers errno 103 for an unknown view', () async {
      final token = await login();

      final response = await appCall({
        'view': 'no-such-view',
        'format': 'json',
        'token': token,
        'JWTToken': token,
        'pupilId': _firstPupilId,
      });

      final data = decoded(response)['data'] as Map<String, dynamic>;
      expect(data['errno'], _unknownViewErrno);
    });
  });

  group('poczta', () {
    Future<String> ssoCookie() async {
      final response = await dio.get<String>(
        '/sso/$_school/token',
        options: Options(followRedirects: false),
      );
      return (response.headers['set-cookie'] ?? const <String>[])
          .map((value) => value.split(';').first.trim())
          .join('; ');
    }

    Future<Response<Map<String, dynamic>>> postFolder(
      String folder,
      String cookie,
    ) {
      return dio.post<Map<String, dynamic>>(
        '/api/messages/$folder',
        data: jsonEncode({'limit': _pageSize, 'skip': 0}),
        options: Options(
          contentType: 'application/json',
          headers: {'Cookie': cookie},
        ),
      );
    }

    test('SSO sets a session cookie', () async {
      expect(await ssoCookie(), isNotEmpty);
    });

    test('inbox parses through the message parser', () async {
      final response = await postFolder('inbox', await ssoCookie());

      final items = response.data!['items'] as List<dynamic>;
      final messages = parsePocztaMessages(items, 'inbox');
      expect(messages, isNotEmpty);
      expect(messages.first.title, isNotEmpty);
      expect(messages.first.senderName, isNotEmpty);
    });

    test('sent parses through the message parser', () async {
      final response = await postFolder('sent', await ssoCookie());

      final items = response.data!['items'] as List<dynamic>;
      expect(parsePocztaMessages(items, 'sent'), isNotEmpty);
    });

    test('folder lists answer 401 without the cookie', () async {
      final response = await postFolder('inbox', '');

      expect(response.statusCode, _unauthorized);
    });

    test('read message returns full content', () async {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/messages/read/$_firstMessageId',
        options: Options(headers: {'Cookie': await ssoCookie()}),
      );

      final data = response.data!;
      expect(data['id'], isA<int>());
      expect(data['subject'], isA<String>());
      expect(data['content'], isA<String>());
      expect((data['author'] as Map<String, dynamic>)['name'], isA<String>());
    });

    test('unread count is plain integer text', () async {
      final response = await dio.post<String>(
        '/api/unreadMessages',
        data: jsonEncode({'school': _school, 'messagesToken': 'token'}),
        options: Options(
          contentType: 'application/json',
          responseType: ResponseType.plain,
        ),
      );

      expect(int.tryParse(response.data!.trim()), isNotNull);
    });

    test('receivers search returns results', () async {
      final response = await dio.post<List<dynamic>>(
        '/api/messages/receivers/search',
        data: jsonEncode({'query': 'Kowalska', 'ids': <Object>[]}),
        options: Options(
          contentType: 'application/json',
          headers: {'Cookie': await ssoCookie()},
        ),
      );

      final first = response.data!.first as Map<String, dynamic>;
      expect(first['id'], isA<String>());
      expect(first['name'], isA<String>());
    });
  });
}
