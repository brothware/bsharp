import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/poczta_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _messagingUrl = 'https://poczta.mobireg.pl/sso';
const _unauthorized = 401;
const _ok = 200;
const _unreadCount = 3;

class _PocztaFake {
  bool expireOnce = false;

  Dio client(List<RequestOptions> seen) {
    final factory = ApiClientFactory(
      school: 'sp1',
      parentLogin: '',
      parentPassHash: '',
    );
    return factory.createPocztaClient(_messagingUrl)
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seen.add(options);
            handler.resolve(_answer(options));
          },
        ),
      );
  }

  Response<dynamic> _answer(RequestOptions options) {
    if (options.path.startsWith('/sso/')) {
      return _respond(options, _ok, '', {
        'set-cookie': ['laravel_session=abc; path=/', 'XSRF-TOKEN=x; path=/'],
      });
    }
    if (expireOnce) {
      expireOnce = false;
      return _respond(options, _unauthorized, '');
    }
    if (options.path == '/api/unreadMessages') {
      return _respond(options, _ok, '$_unreadCount');
    }
    const folders = ['inbox', 'sent', 'important', 'trash'];
    if (folders.any((folder) => options.path == '/api/messages/$folder')) {
      return _respond(options, _ok, {'items': <Object>[], 'total': 0});
    }
    return _respond(options, _ok, <String, dynamic>{});
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

  test('derives the base url from the messaging url', () {
    final client = ApiClientFactory(
      school: 'sp1',
      parentLogin: '',
      parentPassHash: '',
    ).createPocztaClient(_messagingUrl);

    expect(client.options.baseUrl, 'https://poczta.mobireg.pl');
  });

  test('pages every folder by 20', () async {
    final (source, seen) = await _signedIn();

    await source.getSent(skip: 20);
    await source.getImportant();
    await source.getTrash();

    expect(seen.map((o) => o.data), [
      {'limit': 20, 'skip': 20},
      {'limit': 20, 'skip': 0},
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

  test('reads the unread count without a cookie', () async {
    final seen = <RequestOptions>[];
    final source = PocztaDataSource(client: _fakePoczta(seen));

    final count = await source.unreadCount(school: 'sp1', messagesToken: 't');

    expect(count.valueOrNull, 3);
    expect(seen.single.data, {'school': 'sp1', 'messagesToken': 't'});
    expect(seen.single.headers.containsKey('Cookie'), isFalse);
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

  test('lists receiver types and receivers of a type', () async {
    final (source, seen) = await _signedIn();

    await source.getReceiverTypes();
    await source.getReceiversByType('teachers');

    expect(seen.map((o) => o.path), [
      '/api/messages/receivers',
      '/api/messages/receivers',
    ]);
    expect(seen.map((o) => o.data), [
      <String, dynamic>{},
      {'type': 'teachers'},
    ]);
  });
}
