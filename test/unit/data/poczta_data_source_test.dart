import 'dart:io';
import 'dart:typed_data';

import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/poczta_data_source.dart';
import 'package:bsharp/domain/entities/outgoing_attachment.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _messagingUrl = 'https://poczta.mobireg.pl/sso';
const _unauthorized = 401;
const _ok = 200;
const _payloadTooLarge = 413;
const _uploadPath = '/api/messages/777/files';
const _storageHost = 's3.waw.io.cloud.ovh.net';

class _PocztaFake {
  bool expireOnce = false;
  bool expireAlways = false;
  bool exposeCookiesAsJar = false;
  Object folderBody = {'items': <Object>[], 'total': 0};
  Object searchBody = <Object>[];
  Object sendBody = {'id': 777};
  int uploadStatus = _ok;
  DioExceptionType? uploadError;

  Dio client(List<RequestOptions> seen) {
    final factory = ApiClientFactory(
      school: 'sp1',
    );
    return factory.createPocztaClient(_messagingUrl)
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seen.add(options);
            final error = uploadError;
            if (error != null && options.path == _uploadPath) {
              handler.reject(
                DioException(requestOptions: options, type: error),
              );
              return;
            }
            handler.resolve(_answer(options));
          },
        ),
      );
  }

  Response<dynamic> _answer(RequestOptions options) {
    if (options.path.startsWith('/sso/')) {
      if (exposeCookiesAsJar) {
        return _respond(options, _ok, '', {
          'x-cookie-jar': ['laravel_session=abc; XSRF-TOKEN=x'],
        });
      }
      return _respond(options, _ok, '', {
        'set-cookie': ['laravel_session=abc; path=/', 'XSRF-TOKEN=x; path=/'],
      });
    }
    if (expireOnce || expireAlways) {
      expireOnce = false;
      return _respond(options, _unauthorized, _body(options, ''));
    }
    if (options.path.startsWith('/files/') ||
        options.uri.host == _storageHost) {
      return _respond(options, _ok, _body(options, 'content'));
    }
    const folders = ['inbox', 'sent', 'trash'];
    if (folders.any((folder) => options.path == '/api/messages/$folder')) {
      return _respond(options, _ok, folderBody);
    }
    if (options.path == '/api/messages/receivers/search') {
      return _respond(options, _ok, searchBody);
    }
    if (options.method == 'PUT' && options.path == '/api/messages') {
      return _respond(options, _ok, sendBody);
    }
    if (options.path == _uploadPath) {
      return _respond(options, uploadStatus, <String, dynamic>{});
    }
    return _respond(options, _ok, <String, dynamic>{});
  }

  Object _body(RequestOptions options, String text) {
    return options.responseType == ResponseType.stream
        ? ResponseBody.fromString(text, _ok)
        : text;
  }

  Response<dynamic> _respond(
    RequestOptions options,
    int status,
    Object body, [
    Map<String, List<String>> headers = const {},
  ]) {
    return Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
      headers: Headers.fromMap(headers),
    );
  }
}

Dio _fakePoczta(List<RequestOptions> seen) => _PocztaFake().client(seen);

Future<(PocztaDataSource, List<RequestOptions>)> _signedIn() async {
  final seen = <RequestOptions>[];
  final source = PocztaDataSource(client: _fakePoczta(seen));
  await source.establishSession(school: 'sp1', messagesToken: 't');
  seen.clear();
  return (source, seen);
}

Future<(PocztaDataSource, List<RequestOptions>)> _signedInTo(
  _PocztaFake server, {
  bool isWeb = false,
}) async {
  final seen = <RequestOptions>[];
  final source = PocztaDataSource(client: server.client(seen), isWeb: isWeb);
  await source.establishSession(school: 'sp1', messagesToken: 't');
  seen.clear();
  return (source, seen);
}

OutgoingAttachment _fileAttachment(String name, List<int> content) {
  final file = File('${Directory.systemTemp.createTempSync().path}/$name')
    ..writeAsBytesSync(content);
  return OutgoingAttachment.file(
    name: name,
    sizeBytes: content.length,
    path: file.path,
  );
}

MapEntry<String, MultipartFile> _uploadedPart(RequestOptions options) {
  return (options.data as FormData).files.single;
}

String get savePath => '${Directory.systemTemp.createTempSync().path}/file';

void main() {
  test('signs in with one SSO request and sends its cookies', () async {
    final seen = <RequestOptions>[];
    final source = PocztaDataSource(client: _fakePoczta(seen));

    await source.establishSession(school: 'sp1', messagesToken: 'a+b/c=');
    await source.getInbox();

    final sso = seen.first;
    expect(sso.method, 'GET');
    expect(sso.path, '/sso/sp1/a%2Bb%2Fc%3D');
    expect(sso.followRedirects, isFalse);
    expect(sso.headers['Accept'], 'text/html');
    expect(seen.where((o) => o.path == '/'), isEmpty);
    final inbox = seen.last;
    expect(inbox.method, 'POST');
    expect(inbox.path, '/api/messages/inbox');
    expect(inbox.data, {'limit': 20, 'skip': 0});
    expect(inbox.headers['Cookie'], 'laravel_session=abc; XSRF-TOKEN=x');
    expect(inbox.headers['User-Agent'], AppConstants.appUserAgent);
    expect(inbox.headers.containsKey('X-CSRF-TOKEN'), isFalse);
    expect(inbox.headers.containsKey('X-Requested-With'), isFalse);
  });

  test('relays cookies through the proxy jar header on web', () async {
    final seen = <RequestOptions>[];
    final server = _PocztaFake()..exposeCookiesAsJar = true;
    final source = PocztaDataSource(
      client: server.client(seen),
      isWeb: true,
    );

    await source.establishSession(school: 'sp1', messagesToken: 't');
    await source.getInbox();

    final inbox = seen.last;
    expect(inbox.headers['X-Cookie-Jar'], 'laravel_session=abc; XSRF-TOKEN=x');
    expect(inbox.headers.containsKey('Cookie'), isFalse);
  });

  test('fails the web sign-in when the proxy exposes no jar', () async {
    final seen = <RequestOptions>[];
    final source = PocztaDataSource(client: _fakePoczta(seen), isWeb: true);

    final result = await source.establishSession(
      school: 'sp1',
      messagesToken: 't',
    );

    expect(result, isA<Failure<void>>());
    expect(source.hasSession, isFalse);
  });

  test('derives the base url from the messaging url', () {
    final client = ApiClientFactory(
      school: 'sp1',
    ).createPocztaClient(_messagingUrl);

    expect(client.options.baseUrl, 'https://poczta.mobireg.pl');
  });

  test('pages every folder by 20', () async {
    final (source, seen) = await _signedIn();

    await source.getSent(skip: 20);
    await source.getTrash();

    expect(seen.map((o) => o.data), [
      {'limit': 20, 'skip': 20},
      {'limit': 20, 'skip': 0},
    ]);
  });

  test('sends the query only when searching', () async {
    final (source, seen) = await _signedIn();

    await source.getInbox(query: 'abc');

    expect(seen.single.data, {'limit': 20, 'skip': 0, 'query': 'abc'});
  });

  test('signs in again once after a 401 and replays the call', () async {
    final seen = <RequestOptions>[];
    final server = _PocztaFake();
    final source = PocztaDataSource(client: server.client(seen));
    await source.establishSession(school: 'sp1', messagesToken: 't');
    server.expireOnce = true;

    final result = await source.getInbox();

    expect(result, isA<Success<List<dynamic>>>());
    expect(seen.where((o) => o.path.startsWith('/sso/')).length, 2);
    expect(seen.where((o) => o.path == '/api/messages/inbox').length, 2);
  });

  test('searches receivers with query and ids', () async {
    final (source, seen) = await _signedIn();

    await source.searchReceivers('Nowak');

    expect(seen.last.path, '/api/messages/receivers/search');
    expect(seen.last.data, {'query': 'Nowak', 'ids': <Object>[]});
  });

  test('sends a message with PUT', () async {
    final (source, seen) = await _signedIn();

    await source.sendMessage(
      title: 'T',
      content: '<p>C</p>',
      recipients: ['user_1'],
      previousMessageId: 7,
    );

    expect(seen.single.method, 'PUT');
    expect(seen.single.path, '/api/messages');
    expect(seen.single.data, {
      'title': 'T',
      'content': '<p>C</p>',
      'odbiorcy': ['user_1'],
      'kopiaDo': <String>[],
      'previousMessageId': 7,
    });
  });

  test('reads and deletes a message by id', () async {
    final (source, seen) = await _signedIn();

    await source.readMessage(5);
    await source.deleteMessage(5);

    expect(seen.map((o) => (o.method, o.path)), [
      ('GET', '/api/messages/read/5'),
      ('DELETE', '/api/messages/5'),
    ]);
  });

  test('stars and restores with an empty body', () async {
    final (source, seen) = await _signedIn();

    await source.toggleStar(5);
    await source.restoreMessage(5);

    expect(seen.map((o) => o.path), [
      '/api/messages/5/stared',
      '/api/messages/5/restore',
    ]);
    expect(seen.map((o) => o.method), ['POST', 'POST']);
    expect(seen.map((o) => o.data), [<String, dynamic>{}, <String, dynamic>{}]);
  });

  test('a folder without a total still yields its items', () async {
    final seen = <RequestOptions>[];
    final server = _PocztaFake()
      ..folderBody = {
        'items': [
          {'id': 1},
        ],
      };
    final source = PocztaDataSource(client: server.client(seen));
    await source.establishSession(school: 'sp1', messagesToken: 't');

    final result = await source.getInbox();

    expect(result.valueOrNull, hasLength(1));
  });

  test('a folder without items is a FormatException', () async {
    final seen = <RequestOptions>[];
    final server = _PocztaFake()
      ..folderBody = {
        'users': [
          {'id': 1},
        ],
      };
    final source = PocztaDataSource(client: server.client(seen));
    await source.establishSession(school: 'sp1', messagesToken: 't');

    await expectLater(
      source.getInbox(),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('/api/messages/inbox'),
        ),
      ),
    );
  });

  test('a folder answering a bare list is a FormatException', () async {
    final seen = <RequestOptions>[];
    final server = _PocztaFake()..folderBody = <Object>[];
    final source = PocztaDataSource(client: server.client(seen));
    await source.establishSession(school: 'sp1', messagesToken: 't');

    await expectLater(source.getTrash(), throwsFormatException);
  });

  test('a receiver search that is not a list is a FormatException', () async {
    final seen = <RequestOptions>[];
    final server = _PocztaFake()..searchBody = <String, dynamic>{};
    final source = PocztaDataSource(client: server.client(seen));
    await source.establishSession(school: 'sp1', messagesToken: 't');

    await expectLater(source.searchReceivers('Nowak'), throwsFormatException);
  });

  test('fails with SessionExpired after two consecutive 401s', () async {
    final seen = <RequestOptions>[];
    final server = _PocztaFake()..expireAlways = true;
    final source = PocztaDataSource(client: server.client(seen));
    await source.establishSession(school: 'sp1', messagesToken: 't');

    final result = await source.getInbox();

    expect(result.failureOrNull, isA<SessionExpired>());
    expect(seen.where((o) => o.path.startsWith('/sso/')).length, 2);
    expect(seen.where((o) => o.path == '/api/messages/inbox').length, 2);
  });

  test('downloads a file with the cookie', () async {
    final (source, seen) = await _signedIn();

    final result = await source.downloadFile('/files/1', savePath);

    expect(result, isA<Success<void>>());
    expect(seen.single.path, '/files/1');
    expect(seen.single.headers['Cookie'], 'laravel_session=abc; XSRF-TOKEN=x');
  });

  test('signs in again and replays a download after a 401', () async {
    final seen = <RequestOptions>[];
    final server = _PocztaFake();
    final source = PocztaDataSource(client: server.client(seen));
    await source.establishSession(school: 'sp1', messagesToken: 't');
    server.expireOnce = true;

    final result = await source.downloadFile('/files/1', savePath);

    expect(result, isA<Success<void>>());
    expect(seen.where((o) => o.path == '/files/1').length, 2);
    expect(seen.where((o) => o.path.startsWith('/sso/')).length, 2);
  });

  test('downloads a presigned file from storage without the cookie', () async {
    final (source, seen) = await _signedIn();

    final result = await source.downloadFile(
      'https://$_storageHost/poczta-2026/337/a.pdf?X-Amz-Signature=abc',
      savePath,
    );

    expect(result, isA<Success<void>>());
    final request = seen.last;
    expect(request.uri.host, _storageHost);
    expect(request.uri.queryParameters['X-Amz-Signature'], 'abc');
    expect(request.headers.containsKey('Cookie'), isFalse);
  });

  test('refuses a foreign file over plain http', () async {
    final (source, seen) = await _signedIn();
    final requestsBefore = seen.length;

    final result = await source.downloadFile(
      'http://$_storageHost/poczta-2026/337/a.pdf',
      savePath,
    );

    expect(result, isA<Failure<void>>());
    expect(seen.length, requestsBefore);
  });

  test('never sends the cookie over another scheme', () async {
    final (source, seen) = await _signedIn();

    final result = await source.downloadFile(
      'http://poczta.mobireg.pl/files/1',
      savePath,
    );

    expect(result, isA<Failure<void>>());
    expect(seen, isEmpty);
  });

  test('sending a message answers the new message id', () async {
    final (source, _) = await _signedIn();

    final result = await source.sendMessage(
      title: 'T',
      content: 'C',
      recipients: ['user_1'],
    );

    expect(result.valueOrNull, 777);
  });

  test('a numeric string message id is accepted', () async {
    final (source, _) = await _signedInTo(
      _PocztaFake()..sendBody = {'id': '778'},
    );

    final result = await source.sendMessage(
      title: 'T',
      content: 'C',
      recipients: ['user_1'],
    );

    expect(result.valueOrNull, 778);
  });

  for (final body in [
    <String, dynamic>{},
    {'id': 'abc'},
    <Object>[],
  ]) {
    test('a sent message answering $body is sent without an id', () async {
      final (source, _) = await _signedInTo(_PocztaFake()..sendBody = body);

      final result = await source.sendMessage(
        title: 'T',
        content: 'C',
        recipients: ['user_1'],
      );

      expect(result, isA<Success<int?>>());
      expect(result.valueOrNull, isNull);
    });
  }

  test('uploads a file as one multipart files part with the cookie', () async {
    final (source, seen) = await _signedIn();
    final attachment = _fileAttachment('zdjecie.jpg', [1, 2, 3]);

    final result = await source.uploadAttachment(777, attachment);

    expect(result, isA<Success<void>>());
    final upload = seen.single;
    expect(upload.method, 'POST');
    expect(upload.path, _uploadPath);
    expect(upload.headers['Cookie'], 'laravel_session=abc; XSRF-TOKEN=x');
    expect(upload.headers['User-Agent'], AppConstants.appUserAgent);
    expect(upload.headers.containsKey('X-Cookie-Jar'), isFalse);
    final part = _uploadedPart(upload);
    expect(part.key, 'files');
    expect(part.value.filename, 'zdjecie.jpg');
    expect(part.value.length, 3);
    expect(part.value.contentType.toString(), 'application/octet-stream');
    expect(upload.sendTimeout, const Duration(seconds: 900));
    expect(upload.receiveTimeout, const Duration(seconds: 900));
  });

  test('uploads each file in its own request', () async {
    final (source, seen) = await _signedIn();

    await source.uploadAttachment(777, _fileAttachment('a.pdf', [1]));
    await source.uploadAttachment(777, _fileAttachment('b.pdf', [2, 3]));

    expect(seen.map((o) => o.path), [_uploadPath, _uploadPath]);
    expect(seen.map((o) => _uploadedPart(o).value.filename), [
      'a.pdf',
      'b.pdf',
    ]);
  });

  test('uploads picked bytes through the proxy jar header on web', () async {
    final (source, seen) = await _signedInTo(
      _PocztaFake()..exposeCookiesAsJar = true,
      isWeb: true,
    );
    final attachment = OutgoingAttachment.memory(
      name: 'scan.pdf',
      bytes: Uint8List.fromList([4, 5]),
    );

    final result = await source.uploadAttachment(777, attachment);

    expect(result, isA<Success<void>>());
    final upload = seen.single;
    expect(upload.headers['X-Cookie-Jar'], 'laravel_session=abc; XSRF-TOKEN=x');
    expect(upload.headers.containsKey('Cookie'), isFalse);
    expect(_uploadedPart(upload).value.filename, 'scan.pdf');
    expect(_uploadedPart(upload).value.length, 2);
  });

  test('a 413 upload is a file too large failure', () async {
    final (source, _) = await _signedInTo(
      _PocztaFake()..uploadStatus = _payloadTooLarge,
    );

    final result = await source.uploadAttachment(
      777,
      _fileAttachment('big.mov', [1]),
    );

    expect(result.failureOrNull, isA<FileTooLarge>());
  });

  test('an upload after a 401 signs in again and replays it', () async {
    final server = _PocztaFake();
    final (source, seen) = await _signedInTo(server);
    server.expireOnce = true;

    final result = await source.uploadAttachment(
      777,
      _fileAttachment('a.pdf', [1, 2]),
    );

    expect(result, isA<Success<void>>());
    expect(seen.map((o) => o.path.startsWith('/sso/') ? '/sso' : o.path), [
      _uploadPath,
      '/sso',
      _uploadPath,
    ]);
    expect(_uploadedPart(seen.last).value.length, 2);
  });

  test('a file gone before its upload is an unreadable failure', () async {
    final (source, seen) = await _signedIn();
    final gone = OutgoingAttachment.file(
      name: 'gone.pdf',
      sizeBytes: 1,
      path: '${Directory.systemTemp.createTempSync().path}/gone.pdf',
    );

    final result = await source.uploadAttachment(777, gone);

    expect(result.failureOrNull, isA<FileUnreadable>());
    expect(seen, isEmpty);
  });

  test('an upload that times out is a timeout failure', () async {
    final (source, _) = await _signedInTo(
      _PocztaFake()..uploadError = DioExceptionType.sendTimeout,
    );

    final result = await source.uploadAttachment(
      777,
      _fileAttachment('a.pdf', [1]),
    );

    expect(result.failureOrNull, isA<ConnectionTimeout>());
  });

  test('an upload that loses the connection is a connection failure', () async {
    final (source, _) = await _signedInTo(
      _PocztaFake()..uploadError = DioExceptionType.connectionError,
    );

    final result = await source.uploadAttachment(
      777,
      _fileAttachment('a.pdf', [1]),
    );

    expect(result.failureOrNull, isA<NoConnection>());
  });

  test('a live session is confirmed without signing in again', () async {
    final (source, seen) = await _signedIn();

    final result = await source.ensureSession();

    expect(result, isA<Success<void>>());
    expect(seen.where((o) => o.path.startsWith('/sso/')), isEmpty);
  });

  test('an expired session is renewed before it is needed', () async {
    final server = _PocztaFake();
    final (source, seen) = await _signedInTo(server);
    server.expireOnce = true;

    final result = await source.ensureSession();

    expect(result, isA<Success<void>>());
    expect(seen.where((o) => o.path.startsWith('/sso/')).length, 1);
  });

  test('a session that cannot be renewed fails the check', () async {
    final (source, _) = await _signedInTo(
      _PocztaFake()..expireAlways = true,
    );

    final result = await source.ensureSession();

    expect(result.failureOrNull, isA<SessionExpired>());
  });

  test('a session lost at sign-in is signed in again first', () async {
    final seen = <RequestOptions>[];
    final server = _PocztaFake()..exposeCookiesAsJar = true;
    final source = PocztaDataSource(client: server.client(seen));
    await source.establishSession(school: 'sp1', messagesToken: 't');
    expect(source.hasSession, isFalse);
    server.exposeCookiesAsJar = false;

    final result = await source.ensureSession();

    expect(result, isA<Success<void>>());
    expect(source.hasSession, isTrue);
  });

  test('a session that was never established fails the check', () async {
    final source = PocztaDataSource(client: _fakePoczta([]));

    final result = await source.ensureSession();

    expect(result.failureOrNull, isA<SessionExpired>());
  });
}
