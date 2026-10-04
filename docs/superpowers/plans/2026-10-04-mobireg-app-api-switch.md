# Mobireg App API Switch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the Mobireg provider completely onto the API the official
MobiReg 3.x app uses (`auth.php` + `app.php` + poczta as the app calls it),
delete every legacy endpoint and the code that only served it, and put the
new data the API offers to use.

**Architecture:** One `AppApiDataSource` speaks `auth.php` and `app.php` and
unwraps the `{v, serverTime, ttlFresh, ttlRetain, data}` envelope. One
`AppApiSession` per account holds the 30-day JWT in memory, logs in lazily,
and logs in again only after HTTP 401. Pure parser functions turn each view
into the domain state the UI already reads (`resolvedEventsProvider`,
`resolvedGradesProvider`, `attendancesProvider`, ...), so no screen changes
for the switch itself. After the switch, a cleanup phase deletes `njson.php`,
the portal `api.php`, the `index.php` web login, the 40 Drift tables that
mirrored njson, and every type only they used.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2, dio 5.11.0, flutter_riverpod
3.4.2, freezed, drift 2.34.3, slang 4.19.0, very_good_analysis 10.3.0,
Cloudflare Worker (TypeScript) for the web proxy, Express mock server.

**Spec:** `docs/providers/mobireg/app-api.md` (the API contract, captured
2026-10-04 from the official app 3.1.3 and probed live). Captured raw
payloads are quoted in the tasks below as test fixtures.

## Global Constraints

- Only endpoints the official 3.x app calls may be used: `POST
  /<school>/modules/api/auth.php`, `POST /<school>/modules/api/app.php`, and
  the poczta calls listed in Task 7. Nothing else on mobireg.pl,
  rodzic.mobireg.pl or poczta.mobireg.pl.
- Requests must look like the official app's (memory: keep BSharp
  indistinguishable from the official client): user agent
  `MobiReg/3.1.3 (296c220)` on app.php and poczta, no explicit user agent on
  auth.php (dio's default is fine), app.php form fields exactly
  `view`, `format=json`, `token`, `JWTToken`, then `pupilId` and extras. No
  constant or value may name BSharp on the wire, and constant names must not
  describe the mimicry (`officialUserAgent` is wrong, `appUserAgent` is fine).
- One login per account per app process; never log in per request (mobireg's
  standing request). Re-login only after HTTP 401, at most once per request.
- Password is sent in plaintext (it already is stored that way); no MD5
  anywhere.
- No comments in code. Braces on every control statement. No magic numbers:
  `constexpr`-style `const` with a purpose name, local to the function when
  used once, file-level otherwise.
- Never swallow errors: no empty catch, no `on Object { continue; }`. A
  malformed payload is a `FormatException` that fails the sync and is logged
  with the view name.
- All UI strings through slang (`t.section.key`), keys added to every locale
  file that `test/unit/core/i18n_completeness_test.dart` checks.
- Every commit: `flutter analyze --fatal-warnings` clean, `flutter test`
  green, Conventional Commit, subject at most 50 chars, every line at most 72,
  body says why. No AI attribution lines.
- Run `dart run build_runner build --delete-conflicting-outputs` after
  touching freezed/riverpod/drift sources; if it fails on the first run
  because slang output exists, run it again (memory note).

## Review Focus

1. **Accounts saved before this change** (a `legacyPasswordHash` and an empty
   password) must land on the existing re-enter-password dialog on first
   sync, not on a silent "sync failed". Pinned in Task 6.
2. **First sync after upgrading** compares new ids against a snapshot taken
   from njson ids; attendance ids change meaning (record id becomes lesson
   id). Without a reset this fires a burst of "attendance update"
   notifications. Pinned in Task 6 (snapshot version bump).
3. **Token expiry in the middle of a sync**: the first 401 must re-login
   once and replay the request; a second 401 must fail the sync with
   `SessionExpired`, not loop. Pinned in Task 2.
4. **A school year with no marks / an empty term** (`grades: []`,
   `subjects` with empty `value`): grades screen must show empty, not crash.
   Pinned in Task 3.
5. **A pupilId that is no longer valid** (new school year re-numbers pupils,
   as happened 6541 to 6339): errno 102 must surface as a failure the user
   can act on (re-pick the student), not as an expired session. Pinned in
   Task 2 and Task 6.

---

## File Structure

New:
- `lib/data/data_sources/remote/app_api_data_source.dart`: HTTP for
  auth.php and app.php, envelope unwrap, error mapping.
- `lib/data/data_sources/remote/app_api_session.dart`: JWT lifetime, lazy
  login, single re-login on 401, serial queue, cached `users` payload.
- `lib/data/providers/mobireg/parsers/account_parser.dart`: `users` view to
  students, school name, mail credentials, enabled modules.
- `lib/data/providers/mobireg/parsers/term_parser.dart`: `terms`.
- `lib/data/providers/mobireg/parsers/grade_parser.dart`: `marks`.
- `lib/data/providers/mobireg/parsers/timetable_parser.dart`:
  `timetable-events`.
- `lib/data/providers/mobireg/parsers/attendance_parser.dart`: attendance
  from `timetable-events` + types from `attendance-stats`.
- `lib/data/providers/mobireg/parsers/school_item_parser.dart`: `tests`,
  `reprimands`, `announcements`.
- `lib/data/providers/mobireg/mobireg_view_cache.dart`: per-view raw payload
  cache replacing the njson/portal split in `SyncCache`.
- `test/fixtures/mobireg/*.json`: trimmed, anonymised captured payloads.

Rewritten: `mobireg_data_provider.dart`, `poczta_data_source.dart`,
`api_client_factory.dart`, `school_data_provider.dart` (credential methods),
`proxy/src/index.ts`, `test-mock/server.js` + `data.js`.

Deleted in Phase 3 (cleanup): see Tasks 10 to 12.

---

## Phase 1: The new transport

### Task 1: App API data source and envelope

**Files:**
- Create: `lib/data/data_sources/remote/app_api_data_source.dart`
- Modify: `lib/core/network/api_client_factory.dart`
- Modify: `lib/core/constants/app_constants.dart`
- Test: `test/unit/data/app_api_data_source_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class AppApiDataSource {
    AppApiDataSource({required Dio client});
    Future<Result<String>> login({required String login, required String password});
    Future<Result<ViewPayload>> getView({
      required String jwt,
      required String view,
      Map<String, String> params = const {},
    });
  }

  @immutable
  class ViewPayload {
    const ViewPayload({required this.data, required this.serverTime, required this.freshFor});
    final Object data;
    final DateTime serverTime;
    final Duration freshFor;
  }
  ```
  `login` returns the JWT. `getView` fails with `SessionExpired` on HTTP 401,
  `ProtocolMismatch` when `v != 1`, `AppFailure.fromErrno` when `data` holds
  `errno`, `InvalidCredentials` when auth.php answers `status != "OK"`.
- `ApiClientFactory.createAppApiClient()` returns a `Dio` with base URL
  `https://mobireg.pl/<school>/modules/api` (web: `$_proxy/sync/<school>`,
  `MOBIREG_BASE_URL` override: `<override>/<school>/modules/api`), timeout
  15 s, `validateStatus` accepting 401 so the data source maps it itself.
- `AppConstants.appUserAgent = 'MobiReg/3.1.3 (296c220)'`,
  `AppConstants.appApiProtocolVersion = 1`,
  `AppConstants.appApiTimeoutMs = 15000`.

- [ ] **Step 1: Write the failing tests**

Use the `InterceptorsWrapper` fake-server pattern from
`test/unit/data/portal_session_test.dart`: an interceptor that resolves each
request with a canned `Response`, recording `options.path`, `options.data`
and headers.

```dart
import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/remote/app_api_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _jwt = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e30.sig';

Dio _client(Response<dynamic> Function(RequestOptions options) answer,
    List<RequestOptions> seen) {
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
          (o) => _json(o, 200, {'status': 'OK', 'token': _jwt, 'user': {'id': 1}}),
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
        client: _client((o) => _json(o, 200, _envelope([{'id': 1}])), seen),
      );

      final result = await source.getView(
        jwt: _jwt,
        view: 'terms',
        params: {'pupilId': '6339'},
      );

      final payload = result.valueOrNull!;
      expect(payload.data, [{'id': 1}]);
      expect(payload.freshFor, const Duration(seconds: 60));
      expect(payload.serverTime, DateTime.parse('2026-10-04T21:06:32+02:00'));
      expect(seen.single.path, '/app.php');
      expect((seen.single.data as Map).keys.toList(),
          ['view', 'format', 'token', 'JWTToken', 'pupilId']);
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

    test('maps errno 102 inside the envelope to an errno failure', () async {
      final source = AppApiDataSource(
        client: _client(
          (o) => _json(o, 200,
              _envelope({'errno': 102, 'message': 'Authorization error'})),
          [],
        ),
      );

      final result = await source.getView(jwt: _jwt, view: 'terms');

      expect(result.failureOrNull,
          isA<AppFailure>().having((f) => f, 'failure',
              AppFailure.fromErrno(102, 'Authorization error')));
    });

    test('maps errno 103 to ViewNotFound', () async {
      final source = AppApiDataSource(
        client: _client(
          (o) => _json(o, 200, _envelope({'errno': 103, 'message': 'No view exist'})),
          [],
        ),
      );

      final result = await source.getView(jwt: _jwt, view: 'nope');

      expect(result.failureOrNull, isA<ViewNotFound>());
    });

    test('refuses an envelope of another protocol version', () async {
      final source = AppApiDataSource(
        client: _client((o) => _json(o, 200, _envelope([], version: 2)), []),
      );

      final result = await source.getView(jwt: _jwt, view: 'terms');

      expect(result.failureOrNull, isA<ProtocolMismatch>());
    });

    test('rejects a body without the envelope as a FormatException', () async {
      final source = AppApiDataSource(
        client: _client((o) => _json(o, 200, {'items': []}), []),
      );

      expect(
        () => source.getView(jwt: _jwt, view: 'terms'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
```

Check `AppFailure.fromErrno(102, ...)` in `lib/core/error/result.dart:92`
first: if it compares by type only, replace the `having` matcher with the
concrete subtype it returns for 102.

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/unit/data/app_api_data_source_test.dart`
Expected: FAIL, `app_api_data_source.dart` does not exist.

- [ ] **Step 3: Implement**

```dart
import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

@immutable
class ViewPayload {
  const ViewPayload({
    required this.data,
    required this.serverTime,
    required this.freshFor,
  });

  final Object data;
  final DateTime serverTime;
  final Duration freshFor;
}

class AppApiDataSource {
  AppApiDataSource({required this._client});

  final Dio _client;

  Future<Result<String>> login({
    required String login,
    required String password,
  }) async {
    final response = await _send(
      () => _client.post<Map<String, dynamic>>(
        '/auth.php',
        data: {'login': login, 'password': password},
        options: Options(
          contentType: 'application/json; charset=UTF-8',
          headers: {'Accept': 'application/json'},
        ),
      ),
    );
    return switch (response) {
      Failure(:final failure) => Result.failure(failure),
      Success(:final value) => _tokenFrom(value),
    };
  }

  Future<Result<ViewPayload>> getView({
    required String jwt,
    required String view,
    Map<String, String> params = const {},
  }) async {
    final response = await _send(
      () => _client.post<Map<String, dynamic>>(
        '/app.php',
        data: {
          'view': view,
          'format': 'json',
          'token': jwt,
          'JWTToken': jwt,
          ...params,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'User-Agent': AppConstants.appUserAgent},
        ),
      ),
    );
    return switch (response) {
      Failure(:final failure) => Result.failure(failure),
      Success(:final value) => _unwrap(view, value),
    };
  }

  Future<Result<Map<String, dynamic>>> _send(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    const unauthorized = 401;
    try {
      final response = await request();
      final body = response.data;
      if (response.statusCode == unauthorized) {
        return Result.failure(
          SessionExpired(message: body?['message'] as String?),
        );
      }
      if (body == null) {
        return const Result.failure(NoData(message: 'Empty response'));
      }
      return Result.success(body);
    } on DioException catch (e) {
      final failure = e.error;
      if (failure is AppFailure) {
        return Result.failure(failure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  Result<String> _tokenFrom(Map<String, dynamic> body) {
    final token = body['token'];
    if (body['status'] != 'OK' || token is! String || token.isEmpty) {
      return Result.failure(
        InvalidCredentials(message: body['message'] as String?),
      );
    }
    return Result.success(token);
  }

  Result<ViewPayload> _unwrap(String view, Map<String, dynamic> body) {
    final version = body['v'];
    final data = body['data'];
    final serverTime = body['serverTime'];
    final ttlFresh = body['ttlFresh'];
    if (version is! int ||
        data == null ||
        serverTime is! String ||
        ttlFresh is! int) {
      throw FormatException('View $view answered without an envelope', body);
    }
    if (version != AppConstants.appApiProtocolVersion) {
      return Result.failure(
        ProtocolMismatch(message: 'View $view answered protocol v$version'),
      );
    }
    if (data is Map<String, dynamic> && data['errno'] is int) {
      return Result.failure(
        AppFailure.fromErrno(data['errno'] as int, data['message'] as String?),
      );
    }
    return Result.success(
      ViewPayload(
        data: data,
        serverTime: DateTime.parse(serverTime),
        freshFor: Duration(seconds: ttlFresh),
      ),
    );
  }
}
```

Match each failure constructor to its real signature in
`lib/core/error/result.dart` (`SessionExpired`, `InvalidCredentials`,
`ProtocolMismatch`, `NoData`, `UnknownFailure`); if one has no `message`
parameter, pass nothing rather than adding one.

In `api_client_factory.dart` add:

```dart
  Dio createAppApiClient() {
    final baseUrl = AppConstants.hasMobiregBaseUrlOverride
        ? '${AppConstants.mobiregBaseUrl}/$_school/modules/api'
        : kIsWeb
        ? '$_proxy/sync/$_school'
        : 'https://mobireg.pl/$_school/modules/api';
    const unauthorized = 401;
    const timeout = Duration(milliseconds: AppConstants.appApiTimeoutMs);
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        validateStatus: (status) =>
            status != null &&
            ((status >= 200 && status < 300) || status == unauthorized),
        extra: _webExtra,
      ),
    )..interceptors.add(ErrorMappingInterceptor());
  }
```

`ErrorMappingInterceptor.onResponse` rejects any map holding `errno` at the
top level; app.php nests `errno` under `data`, so it passes through and
`_unwrap` maps it. Keep the interceptor for its `onError` network mapping.

Add the three constants to `AppConstants`. Do not touch the njson constants
yet; Task 11 deletes them.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/unit/data/app_api_data_source_test.dart`
Expected: PASS (all 9).

- [ ] **Step 5: Commit**

```bash
git add lib/data/data_sources/remote/app_api_data_source.dart \
  lib/core/network/api_client_factory.dart \
  lib/core/constants/app_constants.dart \
  test/unit/data/app_api_data_source_test.dart
git commit -m "feat(mobireg): add the app.php API data source" -m "The official app 3.x reads everything through auth.php and
app.php; njson.php now answers HTTP 500. This adds the transport:
JWT login, the form fields the official app sends, and mapping of
the envelope, errno and HTTP 401 onto AppFailure."
```

### Task 2: App API session

**Files:**
- Create: `lib/data/data_sources/remote/app_api_session.dart`
- Test: `test/unit/data/app_api_session_test.dart`

**Interfaces:**
- Consumes: `AppApiDataSource.login`, `AppApiDataSource.getView`,
  `ViewPayload` (Task 1); `SerialQueue` (`lib/core/network/serial_queue.dart`).
- Produces:
  ```dart
  class AppApiSession {
    AppApiSession({
      required AppApiDataSource api,
      required String login,
      required String password,
    });
    Future<Result<ViewPayload>> getView(String view, {Map<String, String> params = const {}});
    Future<Result<Map<String, dynamic>>> account();
  }
  ```
  `account()` returns the `users` view's `data` map, fetched once per
  session and refetched after a re-login.

- [ ] **Step 1: Write the failing tests**

```dart
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
        onRequest: (options, handler) => handler.resolve(server.handle(options)),
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

    test('gives up with SessionExpired when the fresh token is refused too',
        () async {
      final server = _FakeAppServer()..alwaysUnauthorized = true;
      final session = _sessionFor(server);

      final result = await session.getView('terms');

      expect(result.failureOrNull, isA<SessionExpired>());
      expect(server.logins, 2);
    });

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

    test('passes an errno failure through without logging in again',
        () async {
      final server = _FakeAppServer();
      final session = _sessionFor(server);
      await session.getView('terms');

      final result = await session.getView('nope-errno');

      expect(result, isA<Success<ViewPayload>>());
      expect(server.logins, 1);
    });
  });
}
```

The last test only proves a non-401 answer never triggers a login; errno
mapping itself is covered in Task 1.

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/unit/data/app_api_session_test.dart`
Expected: FAIL, `app_api_session.dart` does not exist.

- [ ] **Step 3: Implement**

```dart
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/core/network/serial_queue.dart';
import 'package:bsharp/data/data_sources/remote/app_api_data_source.dart';

class AppApiSession {
  AppApiSession({
    required this._api,
    required this._login,
    required this._password,
  });

  final AppApiDataSource _api;
  final String _login;
  final String _password;
  final _queue = SerialQueue();

  String? _jwt;
  Map<String, dynamic>? _account;

  Future<Result<ViewPayload>> getView(
    String view, {
    Map<String, String> params = const {},
  }) {
    return _queue.add(() => _getViewWithRelogin(view, params));
  }

  Future<Result<Map<String, dynamic>>> account() {
    return _queue.add(() async {
      final cached = _account;
      if (cached != null) {
        return Result.success(cached);
      }
      final result = await _getViewWithRelogin('users', const {});
      if (result case Failure(:final failure)) {
        return Result<Map<String, dynamic>>.failure(failure);
      }
      final data = (result as Success<ViewPayload>).value.data;
      if (data is! Map<String, dynamic>) {
        throw FormatException('View users answered a non-object', data);
      }
      _account = data;
      return Result.success(data);
    });
  }

  Future<Result<ViewPayload>> _getViewWithRelogin(
    String view,
    Map<String, String> params,
  ) async {
    final first = await _getViewOnce(view, params);
    if (first case Failure(failure: SessionExpired())) {
      _jwt = null;
      _account = null;
      return _getViewOnce(view, params);
    }
    return first;
  }

  Future<Result<ViewPayload>> _getViewOnce(
    String view,
    Map<String, String> params,
  ) async {
    final jwt = await _ensureJwt();
    if (jwt case Failure(:final failure)) {
      return Result<ViewPayload>.failure(failure);
    }
    return _api.getView(
      jwt: (jwt as Success<String>).value,
      view: view,
      params: params,
    );
  }

  Future<Result<String>> _ensureJwt() async {
    final current = _jwt;
    if (current != null) {
      return Result.success(current);
    }
    final result = await _api.login(login: _login, password: _password);
    if (result case Success(:final value)) {
      _jwt = value;
    }
    return result;
  }
}
```

`SerialQueue.add` is not re-entrant: `account()` must call
`_getViewWithRelogin` directly, never `getView`, or it deadlocks. The tests
above would hang if that is broken.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/unit/data/app_api_session_test.dart`
Expected: PASS (all 6).

- [ ] **Step 5: Commit**

```bash
git add lib/data/data_sources/remote/app_api_session.dart \
  test/unit/data/app_api_session_test.dart
git commit -m "feat(mobireg): hold one app API session per account" -m "mobireg asked us to stop logging in per fetch. The JWT lives 30
days, so the session logs in lazily, reuses the token for every view
and logs in again only once after the server answers HTTP 401."
```

---

## Phase 2: Parsers and the provider switch

All parser tests load fixtures from `test/fixtures/mobireg/`. Create that
directory in Task 3 with a loader:

```dart
// test/fixtures/mobireg/fixtures.dart
import 'dart:convert';
import 'dart:io';

Object loadMobiregFixture(String name) => jsonDecode(
  File('test/fixtures/mobireg/$name.json').readAsStringSync(),
) as Object;
```

Each fixture holds only the envelope's `data` value. Values are copied from
the 2026-10-04 capture; personal names are replaced (pupil Maria Kowalska,
id 6339; parent Jan Kowalski; teachers keep their first names and a
placeholder surname).

### Task 3: Terms, subjects and grades

**Files:**
- Create: `lib/data/providers/mobireg/parsers/term_parser.dart`
- Create: `lib/data/providers/mobireg/parsers/grade_parser.dart`
- Create: `test/fixtures/mobireg/fixtures.dart`, `terms.json`,
  `subjects.json`, `marks_term4.json`, `marks_empty.json`
- Test: `test/unit/data/mobireg/grade_parser_test.dart`,
  `test/unit/data/mobireg/term_parser_test.dart`

**Interfaces:**
- Consumes: domain `Term`, `TermType`, `Subject`, `Teacher`,
  `ResolvedGrade`; `normalizeMobiregTermName`,
  `normalizeMobiregSubjectName`, `normalizeMobiregGradeCategory`
  (`lib/data/services/mobireg_translations.dart`).
- Produces:
  ```dart
  List<Term> parseTerms(Object data);
  List<Subject> parseSubjects(Object data);
  @immutable
  class ParsedMarks {
    const ParsedMarks({required this.grades, required this.teachers});
    final List<ResolvedGrade> grades;
    final List<Teacher> teachers;
  }
  ParsedMarks parseMarks(Object data, {required int termId});
  GradeValue gradeValueOf(String raw);
  @immutable
  class GradeValue {
    const GradeValue({required this.display, this.numeric});
    final String display;
    final double? numeric;
  }
  ```

Fixtures:

`terms.json`:
```json
[
  {"id": 1, "isYear": 1, "label": "Rok szkolny 2026/2027", "parentId": 0, "dateFrom": "2026-09-01", "dateTo": "2027-08-31"},
  {"id": 4, "isYear": 0, "label": "Semestr I", "parentId": 1, "dateFrom": "2026-09-01", "dateTo": "2027-01-31"},
  {"id": 7, "isYear": 0, "label": "Semestr II", "parentId": 1, "dateFrom": "2027-02-01", "dateTo": "2027-08-31"}
]
```

Before writing `terms.json`, read the real labels and ids for terms 4 and 7
with one probe (reuse a captured JWT, no new login):
`curl -s --compressed -A 'MobiReg/3.1.3 (296c220)' https://mobireg.pl/osm-wroclaw/modules/api/app.php -d view=terms -d format=json -d token=$JWT -d pupilId=6339`
and copy them verbatim. If the JWT has expired, keep the values above.

`subjects.json`:
```json
[{"id": 123, "label": "chór"}, {"id": 54, "label": "przyroda"}, {"id": 384, "label": "edukacja zdrowotna"}]
```

`marks_term4.json`:
```json
{
  "markDescriptives": {"zachowanie": "", "obowiazkowe": "", "zalecenia": ""},
  "subjects": [
    {"id": 54, "label": "przyroda", "teachers": [{"id": 4977, "name": "Joanna Nowak"}], "suggestView": 0, "value": "", "isFinal": 0, "mtTeacherId": 0},
    {"id": 384, "label": "edukacja zdrowotna", "teachers": [{"id": 4938, "name": "Anna Nowak"}], "suggestView": 0, "value": "5", "isFinal": 1, "mtTeacherId": 4938}
  ],
  "markGroups": [
    {"id": 2200, "subjectId": 54, "kindLabel": "karty pracy", "markGroupId": 2200, "parentMarkGroupId": 0, "bgColor": "color: #0000FF;", "description": "kodeks przyrodnika"}
  ],
  "grades": [
    {"id": 13414, "subjectId": 54, "kindLabel": "karty pracy", "value": "+", "markGroupId": 2200, "parentMarkGroupId": 0, "date": "2026-10-01", "teacherId": 4977, "bgColor": "color: #0000FF;", "description": "kodeks przyrodnika", "comments": ""},
    {"id": 13415, "subjectId": 54, "kindLabel": "sprawdzian", "value": "4+", "markGroupId": 2201, "parentMarkGroupId": 0, "date": "2026-10-02", "teacherId": 4977, "bgColor": "color: #000000;", "description": "dział 1", "comments": "poprawa"},
    {"id": 4430, "subjectId": 384, "kindLabel": "Aktywność", "value": "5", "markGroupId": 1073, "parentMarkGroupId": 0, "date": "2026-09-19", "teacherId": 4938, "bgColor": "color: #0000FF;", "description": "Aktywność i zaangażowanie na lekcji", "comments": ""}
  ],
  "teachers": {
    "4938": {"first_name": "Anna", "surname": "Nowak", "id": 4938},
    "4977": {"first_name": "Joanna", "surname": "Nowak", "id": 4977}
  }
}
```

`marks_empty.json`:
```json
{"markDescriptives": {"zachowanie": "", "obowiazkowe": "", "zalecenia": ""}, "subjects": [], "markGroups": [], "grades": [], "teachers": {}}
```

Grade value rule (no scale table on this API; the Polish 1 to 6 scale is the
default the school configures): a value whose first character is a digit
`1`..`6` counts, `+` after it adds `0.5`, `-` subtracts `0.25`; anything else
(`+`, `-`, `nb`, `np`, `zw`, empty) has no numeric value and does not count
to the average. Weight is `1` unless the grade carries `weight` (the official
app parses `weight` and `count_to_avg`; both were absent in the capture, so
honour them when present).

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:bsharp/data/providers/mobireg/parsers/grade_parser.dart';
import 'package:bsharp/data/providers/mobireg/parsers/term_parser.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

void main() {
  group('parseTerms', () {
    test('marks the school year and keeps the semester parents', () {
      final terms = parseTerms(loadMobiregFixture('terms'));

      expect(terms.first.type, TermType.year);
      expect(terms.first.startDate, DateTime(2026, 9, 1));
      expect(terms[1].type, TermType.semester);
      expect(terms[1].parentId, 1);
    });

    test('maps parentId 0 to no parent', () {
      expect(parseTerms(loadMobiregFixture('terms')).first.parentId, isNull);
    });
  });

  group('gradeValueOf', () {
    final cases = <String, double?>{
      '5': 5,
      '4+': 4.5,
      '3-': 2.75,
      '6': 6,
      '+': null,
      '-': null,
      'nb': null,
      '': null,
    };
    cases.forEach((raw, numeric) {
      test('reads "$raw" as $numeric', () {
        final value = gradeValueOf(raw);
        expect(value.display, raw);
        expect(value.numeric, numeric);
      });
    });
  });

  group('parseMarks', () {
    test('resolves subject, category, teacher and term for every grade', () {
      final parsed = parseMarks(loadMobiregFixture('marks_term4'), termId: 4);

      final grade = parsed.grades.firstWhere((g) => g.id == 13415);
      expect(grade.subjectName, 'nature');
      expect(grade.subjectId, 54);
      expect(grade.displayValue, '4+');
      expect(grade.effectiveValue, 4.5);
      expect(grade.countsToAverage, isTrue);
      expect(grade.teacherName, 'Joanna Nowak');
      expect(grade.comment, 'poprawa');
      expect(grade.description, 'dział 1');
      expect(grade.termId, 4);
      expect(grade.date, DateTime(2026, 10, 2));
    });

    test('keeps a plus mark visible but out of the average', () {
      final parsed = parseMarks(loadMobiregFixture('marks_term4'), termId: 4);

      final plus = parsed.grades.firstWhere((g) => g.id == 13414);
      expect(plus.displayValue, '+');
      expect(plus.effectiveValue, isNull);
      expect(plus.countsToAverage, isFalse);
    });

    test('collects the teachers the view names', () {
      final parsed = parseMarks(loadMobiregFixture('marks_term4'), termId: 4);

      expect(parsed.teachers.map((t) => t.id), unorderedEquals([4938, 4977]));
      expect(parsed.teachers.firstWhere((t) => t.id == 4938).surname, 'Nowak');
    });

    test('an empty term yields no grades', () {
      final parsed = parseMarks(loadMobiregFixture('marks_empty'), termId: 7);

      expect(parsed.grades, isEmpty);
      expect(parsed.teachers, isEmpty);
    });

    test('a grade without an id is a FormatException', () {
      expect(
        () => parseMarks({
          'subjects': [],
          'grades': [
            {'subjectId': 1, 'value': '5', 'date': '2026-10-01'},
          ],
          'teachers': {},
        }, termId: 4),
        throwsFormatException,
      );
    });
  });
}
```

Before asserting `'nature'`, check that `normalizeMobiregSubjectName('przyroda')`
returns `'nature'` (it does per `test/unit/data/mobireg_sync_applier_test.dart`).

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/unit/data/mobireg/`
Expected: FAIL, parser files do not exist.

- [ ] **Step 3: Implement**

`term_parser.dart`:

```dart
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/subject.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/domain/entities/term.dart';

List<Term> parseTerms(Object data) {
  return _objects(data, 'terms').map((json) {
    final parentId = _int(json, 'parentId', 'terms');
    return Term(
      id: _int(json, 'id', 'terms'),
      name: normalizeMobiregTermName(_string(json, 'label', 'terms')),
      type: _int(json, 'isYear', 'terms') == 1 ? TermType.year : TermType.semester,
      startDate: DateTime.parse(_string(json, 'dateFrom', 'terms')),
      endDate: DateTime.parse(_string(json, 'dateTo', 'terms')),
      parentId: parentId == 0 ? null : parentId,
    );
  }).toList();
}

List<Subject> parseSubjects(Object data) {
  return _objects(data, 'subjects').map((json) {
    final name = normalizeMobiregSubjectName(_string(json, 'label', 'subjects'));
    return Subject(id: _int(json, 'id', 'subjects'), name: name, abbr: name);
  }).toList();
}
```

The `_objects`, `_int`, `_string`, `_optionalString` helpers are shared by
every parser. Put them in
`lib/data/providers/mobireg/parsers/json_fields.dart` (public names
`objectsOf`, `intField`, `stringField`, `optionalStringField`) and import
them from each parser instead of the private names above:

```dart
List<Map<String, dynamic>> objectsOf(Object? data, String view) {
  if (data is! List) {
    throw FormatException('View $view: expected a list', data);
  }
  return data.map((item) {
    if (item is! Map<String, dynamic>) {
      throw FormatException('View $view: expected objects', item);
    }
    return item;
  }).toList();
}

int intField(Map<String, dynamic> json, String key, String view) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('View $view: "$key" is not an int', json);
  }
  return value;
}

String stringField(Map<String, dynamic> json, String key, String view) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('View $view: "$key" is not a string', json);
  }
  return value;
}

String? optionalStringField(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : null;
}
```

`grade_parser.dart`:

```dart
import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/resolved_grade.dart';
import 'package:bsharp/domain/entities/teacher.dart';
import 'package:flutter/foundation.dart';

const _view = 'marks';
const _lowestGrade = 1;
const _highestGrade = 6;
const _plusBonus = 0.5;
const _minusPenalty = 0.25;
const _defaultWeight = 1;

@immutable
class GradeValue {
  const GradeValue({required this.display, this.numeric});

  final String display;
  final double? numeric;
}

@immutable
class ParsedMarks {
  const ParsedMarks({required this.grades, required this.teachers});

  final List<ResolvedGrade> grades;
  final List<Teacher> teachers;
}

GradeValue gradeValueOf(String raw) {
  final match = RegExp(r'^([1-6])([+-]?)$').firstMatch(raw.trim());
  if (match == null) {
    return GradeValue(display: raw);
  }
  final base = int.parse(match.group(1)!);
  if (base < _lowestGrade || base > _highestGrade) {
    return GradeValue(display: raw);
  }
  final modifier = switch (match.group(2)) {
    '+' => _plusBonus,
    '-' => -_minusPenalty,
    _ => 0.0,
  };
  return GradeValue(display: raw, numeric: base + modifier);
}

ParsedMarks parseMarks(Object data, {required int termId}) {
  if (data is! Map<String, dynamic>) {
    throw FormatException('View $_view: expected an object', data);
  }
  final teachers = _teachersOf(data['teachers']);
  final teacherNames = {
    for (final teacher in teachers)
      teacher.id: '${teacher.name} ${teacher.surname}',
  };
  final subjectNames = {
    for (final subject in objectsOf(data['subjects'], _view))
      intField(subject, 'id', _view): normalizeMobiregSubjectName(
        stringField(subject, 'label', _view),
      ),
  };
  final grades = objectsOf(data['grades'], _view).map((json) {
    final value = gradeValueOf(stringField(json, 'value', _view));
    final subjectId = intField(json, 'subjectId', _view);
    final countsToAverage =
        value.numeric != null && json['count_to_avg'] != 0;
    return ResolvedGrade(
      id: intField(json, 'id', _view),
      subjectName: subjectNames[subjectId] ?? '',
      subjectId: subjectId,
      categoryName: normalizeMobiregGradeCategory(
        optionalStringField(json, 'kindLabel') ?? '',
      ),
      displayValue: value.display,
      effectiveValue: value.numeric,
      countsToAverage: countsToAverage,
      weight: json['weight'] is int ? json['weight'] as int : _defaultWeight,
      date: DateTime.parse(stringField(json, 'date', _view)),
      description: optionalStringField(json, 'description'),
      comment: optionalStringField(json, 'comments'),
      teacherName: teacherNames[json['teacherId']],
      termId: termId,
    );
  }).toList();
  return ParsedMarks(grades: grades, teachers: teachers);
}

List<Teacher> _teachersOf(Object? data) {
  if (data is List && data.isEmpty) {
    return const [];
  }
  if (data is! Map<String, dynamic>) {
    throw FormatException('View $_view: "teachers" is not a map', data);
  }
  return data.values.map((value) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('View $_view: teacher is not an object', value);
    }
    return Teacher(
      id: intField(value, 'id', _view),
      login: '',
      name: stringField(value, 'first_name', _view),
      surname: stringField(value, 'surname', _view),
      userType: 0,
    );
  }).toList();
}
```

PHP serialises an empty map as `[]`; `_teachersOf` accepts that. The `1`..`6`
bounds are already enforced by the regex; drop the redundant bound check if
`very_good_analysis` flags it. `Teacher.login` and `userType` lose meaning
here; Task 12 removes them from the entity.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/unit/data/mobireg/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/providers/mobireg/parsers test/fixtures/mobireg \
  test/unit/data/mobireg
git commit -m "feat(mobireg): parse terms, subjects and marks views" -m "The app API hands grades out already joined to subject, category
and teacher, with values as text. Turn them into the ResolvedGrade
state the grades screen reads, deriving the numeric value from the
Polish 1-6 notation since this API sends no scale table."
```

### Task 4: Timetable and attendance

**Files:**
- Create: `lib/data/providers/mobireg/parsers/timetable_parser.dart`
- Create: `lib/data/providers/mobireg/parsers/attendance_parser.dart`
- Create: `test/fixtures/mobireg/timetable_events.json`,
  `attendance_stats.json`
- Test: `test/unit/data/mobireg/timetable_parser_test.dart`,
  `test/unit/data/mobireg/attendance_parser_test.dart`

**Interfaces:**
- Consumes: `objectsOf`, `intField`, `stringField`, `optionalStringField`
  (Task 3); `ResolvedEvent`, `Attendance`, `AttendanceType`,
  `AttendanceCountAs`, `AttendanceExcuseStatus`;
  `normalizeMobiregSubjectName`, `normalizeMobiregAttendanceName`,
  `normalizeMobiregAttendanceAbbr`.
- Produces:
  ```dart
  List<ResolvedEvent> parseTimetableEvents(Object data, {required Map<String, int> subjectIdsByName});
  @immutable
  class ParsedAttendance {
    const ParsedAttendance({required this.attendances, required this.types});
    final List<Attendance> attendances;
    final List<AttendanceType> types;
  }
  ParsedAttendance parseAttendance({required Object timetableEvents, required Object attendanceStats, required int pupilId});
  ```

Fixture `timetable_events.json` (copied from the capture, trimmed to the
cases that matter):
```json
[
  {"id": 173, "dateTimeFrom": "2026-09-28 14:25:00", "dateTimeTo": "2026-09-28 15:55:00", "subjectName": "chór", "bgColor": "background-color: #006600;", "attendanceLabel": "Obecność", "isLocked": 1, "isCyclic": 1, "isCanceled": 0, "substitution": 0, "room": "Aula", "attendanceUnchecked": 0, "title": "Swing Song", "teachers": ["Beata Nowak"], "hasTest": 0, "tests": [], "relatedEventId": null, "relatedEventsId": []},
  {"id": 10994, "dateTimeFrom": "2026-09-28 11:30:00", "dateTimeTo": "2026-09-28 12:15:00", "subjectName": "język polski", "bgColor": "", "attendanceLabel": null, "isLocked": 0, "isCyclic": 1, "isCanceled": 1, "substitution": 0, "room": "5.12", "attendanceUnchecked": 1, "title": "", "teachers": ["Teresa Nowak"], "hasTest": 1, "tests": [{"testId": 727, "testType": "Badanie wyników nauczania", "testLabel": "Dyktando"}], "relatedEventId": 150190, "relatedEventsId": [150190]},
  {"id": 150190, "dateTimeFrom": "2026-09-28 11:30:00", "dateTimeTo": "2026-09-28 12:15:00", "subjectName": "zajęcia op. wych.", "bgColor": "", "attendanceLabel": "Nieobecność", "isLocked": 0, "isCyclic": 0, "isCanceled": 0, "substitution": 1, "room": "5.12", "attendanceUnchecked": 0, "title": "", "teachers": ["Anna Nowak"], "oldSubjectName": "język polski", "oldTeachers": ["Teresa Nowak"], "hasTest": 0, "tests": [], "relatedEventId": 10994, "relatedEventsId": [10994]}
]
```

Fixture `attendance_stats.json`:
```json
{
  "records": [
    {"d": "2026-09-02", "sid": 69, "ab": "O", "ca": "P", "tn": "Obecność"},
    {"d": "2026-09-03", "sid": 69, "ab": "NU", "ca": "A", "tn": "Nieobecność usprawiedliwiona"},
    {"d": "2026-09-04", "sid": 69, "ab": "N", "ca": "A", "tn": "Nieobecność"},
    {"d": "2026-09-05", "sid": 123, "ab": "ph", "ca": "A", "tn": "Próba chóru"}
  ],
  "subjects": {"69": "język polski", "123": "chór"},
  "terms": []
}
```

Rules:
- `ResolvedEvent.number` is `0` (this API has no lesson numbers;
  `ScheduleEntry.hasLessonNumber` then sorts by start time, see
  `lib/domain/schedule_utils.dart:125`). `startTime`/`endTime` are
  `HH:MM` cut from `dateTimeFrom`/`dateTimeTo`.
- A cancelled event (`isCanceled == 1`) with a `relatedEventId` is replaced:
  `isReplaced = true`, `replacedByEventId = relatedEventId`.
- A substitution (`substitution != 0`) carries `originalSubjectName` from
  `oldSubjectName` (normalised) and `originalTeacherName` from
  `oldTeachers` joined with `, `.
- `topic` is `title` when not empty. `subjectId` comes from the `subjects`
  view by normalised name; null when unknown.
- Attendance: one `Attendance` per event whose `attendanceLabel` is not
  null, `id = eventsId = event id`. Types come from the distinct `tn`
  values in `attendance-stats.records` (plus any label only the timetable
  uses), ids assigned by sorted label order starting at 1.
- Excuse status from the Polish type name, lower-cased: contains
  `nieusprawiedliwion` → unexcused; contains `usprawiedliwion` → excused;
  `ca == 'A'` or `'L'` and name starts with `nieobecność` or `spóźnienie` →
  unexcused; otherwise unset (a choir rehearsal absence is not something to
  excuse).

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:bsharp/data/providers/mobireg/parsers/attendance_parser.dart';
import 'package:bsharp/data/providers/mobireg/parsers/timetable_parser.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

void main() {
  group('parseTimetableEvents', () {
    final events = parseTimetableEvents(
      loadMobiregFixture('timetable_events'),
      subjectIdsByName: {'choir': 123},
    );

    test('reads date, times, room, teacher and topic', () {
      final choir = events.firstWhere((e) => e.id == 173);
      expect(choir.date, DateTime(2026, 9, 28));
      expect(choir.startTime, '14:25');
      expect(choir.endTime, '15:55');
      expect(choir.roomName, 'Aula');
      expect(choir.teacherName, 'Beata Nowak');
      expect(choir.topic, 'Swing Song');
      expect(choir.subjectId, 123);
      expect(choir.isLocked, isTrue);
      expect(choir.number, 0);
    });

    test('links a cancelled lesson to the lesson that replaced it', () {
      final cancelled = events.firstWhere((e) => e.id == 10994);
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isReplaced, isTrue);
      expect(cancelled.replacedByEventId, 150190);
    });

    test('keeps what a substitution replaced', () {
      final substitute = events.firstWhere((e) => e.id == 150190);
      expect(substitute.isSubstitution, isTrue);
      expect(substitute.originalTeacherName, 'Teresa Nowak');
      expect(substitute.originalSubjectName, isNotEmpty);
    });

    test('a missing dateTimeFrom is a FormatException', () {
      expect(
        () => parseTimetableEvents([
          {'id': 1, 'subjectName': 'x', 'teachers': []},
        ], subjectIdsByName: {}),
        throwsFormatException,
      );
    });
  });

  group('parseAttendance', () {
    final parsed = parseAttendance(
      timetableEvents: loadMobiregFixture('timetable_events'),
      attendanceStats: loadMobiregFixture('attendance_stats'),
      pupilId: 6339,
    );

    test('records attendance only for checked lessons', () {
      expect(parsed.attendances.map((a) => a.eventsId),
          unorderedEquals([173, 150190]));
      expect(parsed.attendances.every((a) => a.id == a.eventsId), isTrue);
      expect(parsed.attendances.every((a) => a.studentsId == 6339), isTrue);
    });

    test('joins each attendance to the type with its label', () {
      final byId = {for (final t in parsed.types) t.id: t};
      final absent = parsed.attendances.firstWhere((a) => a.eventsId == 150190);
      expect(byId[absent.typesId]!.countAs, AttendanceCountAs.absent);
      expect(byId[absent.typesId]!.excuseStatus,
          AttendanceExcuseStatus.unexcused);
    });

    test('derives excuse status from the type name', () {
      AttendanceExcuseStatus statusOf(String abbr) =>
          parsed.types.firstWhere((t) => t.abbr == abbr).excuseStatus;

      expect(statusOf(normalizedAbbr('NU')), AttendanceExcuseStatus.excused);
      expect(statusOf(normalizedAbbr('N')), AttendanceExcuseStatus.unexcused);
      expect(statusOf(normalizedAbbr('ph')), AttendanceExcuseStatus.unset);
      expect(statusOf(normalizedAbbr('O')), AttendanceExcuseStatus.unset);
    });

    test('assigns the same type ids on every parse', () {
      final again = parseAttendance(
        timetableEvents: loadMobiregFixture('timetable_events'),
        attendanceStats: loadMobiregFixture('attendance_stats'),
        pupilId: 6339,
      );
      expect(again.types, parsed.types);
    });
  });
}
```

`normalizedAbbr` is `normalizeMobiregAttendanceAbbr` from
`mobireg_translations.dart`; import it.

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/unit/data/mobireg/timetable_parser_test.dart test/unit/data/mobireg/attendance_parser_test.dart`
Expected: FAIL, files do not exist.

- [ ] **Step 3: Implement**

`timetable_parser.dart`:

```dart
import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/resolved_event.dart';

const _view = 'timetable-events';
const _dateLength = 10;
const _timeStart = 11;
const _timeEnd = 16;

List<ResolvedEvent> parseTimetableEvents(
  Object data, {
  required Map<String, int> subjectIdsByName,
}) {
  return objectsOf(data, _view).map((json) {
    final from = stringField(json, 'dateTimeFrom', _view);
    final to = stringField(json, 'dateTimeTo', _view);
    final subjectName = normalizeMobiregSubjectName(
      stringField(json, 'subjectName', _view),
    );
    final relatedEventId = json['relatedEventId'];
    final isCancelled = json['isCanceled'] == 1;
    final isReplaced = isCancelled && relatedEventId is int;
    final oldSubjectName = optionalStringField(json, 'oldSubjectName');
    return ResolvedEvent(
      id: intField(json, 'id', _view),
      date: DateTime.parse(from.substring(0, _dateLength)),
      number: 0,
      startTime: from.substring(_timeStart, _timeEnd),
      endTime: to.substring(_timeStart, _timeEnd),
      subjectName: subjectName,
      subjectId: subjectIdsByName[subjectName],
      teacherName: _names(json['teachers']),
      roomName: optionalStringField(json, 'room'),
      topic: optionalStringField(json, 'title'),
      isCancelled: isCancelled,
      isSubstitution: json['substitution'] != 0,
      isLocked: json['isLocked'] == 1,
      originalSubjectName: oldSubjectName == null
          ? null
          : normalizeMobiregSubjectName(oldSubjectName),
      originalTeacherName: _names(json['oldTeachers']),
      isReplaced: isReplaced,
      replacedByEventId: isReplaced ? relatedEventId : null,
    );
  }).toList();
}

String? _names(Object? value) {
  if (value is! List || value.isEmpty) {
    return null;
  }
  return value.whereType<String>().join(', ');
}
```

`stringField` throws on a missing `dateTimeFrom`, which is what the
FormatException test pins.

`attendance_parser.dart`:

```dart
import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/attendance.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter/foundation.dart';

const _statsView = 'attendance-stats';
const _timetableView = 'timetable-events';

@immutable
class ParsedAttendance {
  const ParsedAttendance({required this.attendances, required this.types});

  final List<Attendance> attendances;
  final List<AttendanceType> types;
}

@immutable
class _RawType {
  const _RawType({required this.label, required this.abbr, required this.countAs});

  final String label;
  final String abbr;
  final String countAs;
}

ParsedAttendance parseAttendance({
  required Object timetableEvents,
  required Object attendanceStats,
  required int pupilId,
}) {
  if (attendanceStats is! Map<String, dynamic>) {
    throw FormatException('View $_statsView: expected an object', attendanceStats);
  }
  final rawTypes = <String, _RawType>{};
  for (final record in objectsOf(attendanceStats['records'], _statsView)) {
    final label = stringField(record, 'tn', _statsView);
    rawTypes[label] = _RawType(
      label: label,
      abbr: stringField(record, 'ab', _statsView),
      countAs: stringField(record, 'ca', _statsView),
    );
  }
  final events = objectsOf(timetableEvents, _timetableView);
  for (final event in events) {
    final label = optionalStringField(event, 'attendanceLabel');
    if (label != null) {
      rawTypes.putIfAbsent(
        label,
        () => _RawType(label: label, abbr: label, countAs: ''),
      );
    }
  }
  final labels = rawTypes.keys.toList()..sort();
  final typeIds = {for (final (index, label) in labels.indexed) label: index + 1};
  final types = [
    for (final label in labels) _typeOf(typeIds[label]!, rawTypes[label]!),
  ];
  final attendances = [
    for (final event in events)
      if (optionalStringField(event, 'attendanceLabel') case final label?)
        Attendance(
          id: intField(event, 'id', _timetableView),
          eventsId: intField(event, 'id', _timetableView),
          studentsId: pupilId,
          typesId: typeIds[label]!,
        ),
  ];
  return ParsedAttendance(attendances: attendances, types: types);
}

AttendanceType _typeOf(int id, _RawType raw) {
  final countAs = AttendanceCountAs.fromString(raw.countAs);
  return AttendanceType(
    id: id,
    name: normalizeMobiregAttendanceName(raw.label),
    abbr: normalizeMobiregAttendanceAbbr(raw.abbr),
    countAs: countAs,
    excuseStatus: _excuseStatusOf(raw.label, countAs),
  );
}

AttendanceExcuseStatus _excuseStatusOf(String label, AttendanceCountAs countAs) {
  final name = label.toLowerCase();
  if (name.contains('nieusprawiedliwion')) {
    return AttendanceExcuseStatus.unexcused;
  }
  if (name.contains('usprawiedliwion')) {
    return AttendanceExcuseStatus.excused;
  }
  final isMissed =
      countAs == AttendanceCountAs.absent || countAs == AttendanceCountAs.late;
  if (isMissed &&
      (name.startsWith('nieobecność') || name.startsWith('spóźnienie'))) {
    return AttendanceExcuseStatus.unexcused;
  }
  return AttendanceExcuseStatus.unset;
}
```

Label `tn` and `attendanceLabel` are the same Polish text in the capture
(`Obecność` in both). If a school sends a label in the timetable that the
stats never mention, `countAs` falls to `other`; that is correct (unknown
means not counted).

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/unit/data/mobireg/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/providers/mobireg/parsers test/fixtures/mobireg \
  test/unit/data/mobireg
git commit -m "feat(mobireg): parse timetable and attendance views" -m "timetable-events arrives already resolved: subject, room, teacher
names, cancellation and substitution. Map it onto ResolvedEvent and
build attendance from each lesson's label, typed by the codes
attendance-stats reports, since this API has no attendance records."
```

### Task 5: Account, tests, reprimands, announcements

**Files:**
- Create: `lib/data/providers/mobireg/parsers/account_parser.dart`
- Create: `lib/data/providers/mobireg/parsers/school_item_parser.dart`
- Create: `test/fixtures/mobireg/users.json`, `tests.json`,
  `reprimands.json`, `announcements.json`
- Test: `test/unit/data/mobireg/account_parser_test.dart`,
  `test/unit/data/mobireg/school_item_parser_test.dart`

**Interfaces:**
- Consumes: `json_fields.dart` (Task 3); `Student`, `PortalTest`,
  `PortalReprimand`, `PortalBulletin`.
- Produces:
  ```dart
  @immutable
  class MobiregAccount {
    const MobiregAccount({
      required this.students,
      required this.schoolName,
      required this.messagingUrl,
      required this.messagesToken,
      required this.enabledModules,
    });
    final List<Student> students;
    final String? schoolName;
    final String? messagingUrl;
    final String? messagesToken;
    final Set<String> enabledModules;
  }
  MobiregAccount parseAccount(Map<String, dynamic> data);
  List<PortalTest> parseTestItems(Object data);
  List<PortalReprimand> parseReprimandItems(Object data);
  List<PortalBulletin> parseAnnouncements(Object data);
  ```
  `Student` loses `usersEduId` and `sex` in Task 12; until then pass
  `usersEduId: 0, sex: Sex.female` from `parseAccount` and note that Task 12
  removes them. (Both are read nowhere outside parsing.)

Fixtures:

`users.json` (envelope `data` of `users`, email removed):
```json
{
  "id": 8256, "eduId": 959517, "firstname": "Jan", "lastname": "Kowalski", "role": 2,
  "schoolName": ["Ogólnokształcąca Szkoła Muzyczna I i II stopnia", "ul. Przykładowa 1 50-044 Wrocław", "https://example.test"],
  "pupils": [{"id": 6339, "firstname": "Maria", "lastname": "Kowalska"}],
  "messagingUrl": "https://poczta.mobireg.pl/sso",
  "messagesToken": "bW9jay1tZXNzYWdlcy10b2tlbg==",
  "appConfig": {
    "modules": {"attendances": 1, "reprimands": 1, "timetable": 1, "announcements": 1, "notifications": 1, "schedule": 1, "sms": 1},
    "marks": {"parentSuggestionMode": 0, "showAverage": 0, "showDescriptive": 1}
  }
}
```

`tests.json`:
```json
{"count": 2, "items": [
  {"id": 709, "subjectName": "kształcenie słuchu", "dateTime": "2026-10-12 09:45:00", "addedTime": "2026-09-30 09:30:31", "title": "Interwały budowanie", "description": "", "teacherId": 5331},
  {"id": 769, "subjectName": "przyroda", "dateTime": "2026-10-08 08:00:00", "addedTime": "2026-09-29 12:00:00", "title": "dział 1", "description": "rozdziały 1-3", "teacherId": 4977}
], "teachers": {"5331": {"first_name": "Agnieszka", "surname": "Nowak", "id": 5331}}}
```

`reprimands.json` (no reprimands were captured; keys from the official
app's `Reprimand.fromJson`):
```json
{"count": 1, "items": [
  {"id": 31, "pupilId": 6339, "teacherId": 5331, "teacherName": "Agnieszka Nowak", "kind": 2, "getDate": "2026-10-01", "content": "Wzorowe zachowanie na koncercie", "status": 1}
]}
```

`announcements.json`:
```json
{"success": true, "data": [
  {"id": 12, "title": "Nowa aplikacja na urządzenia mobilne", "content": "<p>Szanowni Państwo</p>", "author": "mobireg", "login": "mobireg", "dateTime": "2026-09-30T15:09:03+02:00", "read": "2026-09-30 15:21:22", "type": 1, "kind": 1, "valid": "2026-10-30T23:59:59+01:00", "pollOpen": false, "answers": [], "userAnswer": null, "declined": false, "pending": false}
], "count": 1, "unreadCount": 0, "pendingCount": 0}
```

Check `PortalReprimand.type` semantics in `lib/domain/entities/portal.dart`
before mapping `kind`: the official app documents `kind` 1/2 as
reprimand/praise. Map it to whatever `type` value the notes screen treats as
praise today (read `lib/presentation/notes/`), and pin that in the test.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:bsharp/data/providers/mobireg/parsers/account_parser.dart';
import 'package:bsharp/data/providers/mobireg/parsers/school_item_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/mobireg/fixtures.dart';

void main() {
  group('parseAccount', () {
    final account = parseAccount(
      loadMobiregFixture('users')! as Map<String, dynamic>,
    );

    test('lists the pupils as students', () {
      expect(account.students.single.id, 6339);
      expect(account.students.single.name, 'Maria');
      expect(account.students.single.surname, 'Kowalska');
    });

    test('takes the first schoolName line as the school name', () {
      expect(account.schoolName,
          'Ogólnokształcąca Szkoła Muzyczna I i II stopnia');
    });

    test('keeps the mail sign-in data', () {
      expect(account.messagingUrl, 'https://poczta.mobireg.pl/sso');
      expect(account.messagesToken, 'bW9jay1tZXNzYWdlcy10b2tlbg==');
    });

    test('lists the modules the school enabled', () {
      expect(account.enabledModules,
          containsAll(['attendances', 'reprimands', 'timetable', 'announcements']));
    });

    test('an account without pupils is a FormatException', () {
      expect(() => parseAccount({'id': 1}), throwsFormatException);
    });
  });

  group('school items', () {
    test('tests keep the date part of dateTime and normalise subjects', () {
      final tests = parseTestItems(loadMobiregFixture('tests')!);
      expect(tests.first.date, '2026-10-12');
      expect(tests.first.subjectName, 'ear training');
      expect(tests.first.description, isNull);
      expect(tests.last.description, 'rozdziały 1-3');
    });

    test('reprimands read the app API field names', () {
      final reprimands = parseReprimandItems(loadMobiregFixture('reprimands')!);
      expect(reprimands.single.date, '2026-10-01');
      expect(reprimands.single.teacherName, 'Agnieszka Nowak');
      expect(reprimands.single.content, 'Wzorowe zachowanie na koncercie');
    });

    test('announcements become bulletins with their read state', () {
      final bulletins = parseAnnouncements(loadMobiregFixture('announcements')!);
      expect(bulletins.single.id, 12);
      expect(bulletins.single.isRead, isTrue);
      expect(bulletins.single.content, '<p>Szanowni Państwo</p>');
    });
  });
}
```

Add the `type` assertion for reprimands once you have read what the notes
screen expects (see the check above).

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/unit/data/mobireg/account_parser_test.dart test/unit/data/mobireg/school_item_parser_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

`account_parser.dart`:

```dart
import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter/foundation.dart';

const _view = 'users';

@immutable
class MobiregAccount {
  const MobiregAccount({
    required this.students,
    required this.schoolName,
    required this.messagingUrl,
    required this.messagesToken,
    required this.enabledModules,
  });

  final List<Student> students;
  final String? schoolName;
  final String? messagingUrl;
  final String? messagesToken;
  final Set<String> enabledModules;
}

MobiregAccount parseAccount(Map<String, dynamic> data) {
  final students = objectsOf(data['pupils'], _view).map((pupil) {
    return Student(
      id: intField(pupil, 'id', _view),
      usersEduId: 0,
      name: stringField(pupil, 'firstname', _view),
      surname: stringField(pupil, 'lastname', _view),
      sex: Sex.female,
    );
  }).toList();
  final schoolName = data['schoolName'];
  return MobiregAccount(
    students: students,
    schoolName: schoolName is List && schoolName.isNotEmpty
        ? schoolName.first as String
        : null,
    messagingUrl: optionalStringField(data, 'messagingUrl'),
    messagesToken: optionalStringField(data, 'messagesToken'),
    enabledModules: _enabledModules(data['appConfig']),
  );
}

Set<String> _enabledModules(Object? appConfig) {
  if (appConfig is! Map<String, dynamic>) {
    return const {};
  }
  final modules = appConfig['modules'];
  if (modules is! Map<String, dynamic>) {
    return const {};
  }
  return {
    for (final entry in modules.entries)
      if (entry.value == 1) entry.key,
  };
}
```

`school_item_parser.dart` (replace `_praiseType`'s value after the check
on `PortalReprimand.type` above):

```dart
import 'package:bsharp/data/providers/mobireg/parsers/json_fields.dart';
import 'package:bsharp/data/services/mobireg_translations.dart';
import 'package:bsharp/domain/entities/portal.dart';

const _dateLength = 10;
const _praiseKind = 2;
const _praiseType = 1;
const _reprimandType = 0;

List<PortalTest> parseTestItems(Object data) {
  const view = 'tests';
  return objectsOf(_field(data, 'items', view), view).map((json) {
    return PortalTest(
      id: intField(json, 'id', view),
      subjectName: normalizeMobiregSubjectName(
        stringField(json, 'subjectName', view),
      ),
      date: stringField(json, 'dateTime', view).substring(0, _dateLength),
      title: optionalStringField(json, 'title'),
      description: optionalStringField(json, 'description'),
    );
  }).toList();
}

List<PortalReprimand> parseReprimandItems(Object data) {
  const view = 'reprimands';
  return objectsOf(_field(data, 'items', view), view).map((json) {
    return PortalReprimand(
      id: intField(json, 'id', view),
      date: stringField(json, 'getDate', view).substring(0, _dateLength),
      teacherName: optionalStringField(json, 'teacherName') ?? '',
      content: stringField(json, 'content', view),
      type: intField(json, 'kind', view) == _praiseKind
          ? _praiseType
          : _reprimandType,
    );
  }).toList();
}

List<PortalBulletin> parseAnnouncements(Object data) {
  const view = 'announcements';
  return objectsOf(_field(data, 'data', view), view).map((json) {
    return PortalBulletin(
      id: intField(json, 'id', view),
      title: stringField(json, 'title', view),
      content: optionalStringField(json, 'content') ?? '',
      date: stringField(json, 'dateTime', view),
      author: optionalStringField(json, 'author') ??
          optionalStringField(json, 'login') ??
          '',
      isRead: json['read'] != null,
    );
  }).toList();
}

Object? _field(Object data, String key, String view) {
  if (data is! Map<String, dynamic>) {
    throw FormatException('View $view: expected an object', data);
  }
  return data[key];
}
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/unit/data/mobireg/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/providers/mobireg/parsers test/fixtures/mobireg \
  test/unit/data/mobireg
git commit -m "feat(mobireg): parse account, tests and notes views" -m "The users view replaces the njson ParentStudents call and also
carries the mail sign-in data and the modules the school enabled.
tests, reprimands and announcements replace the portal views of the
same purpose, with the app API's field names."
```

### Task 6: Switch MobiregDataProvider onto the app API

**Files:**
- Modify: `lib/domain/school_data_provider.dart`
- Modify: `lib/data/providers/mobireg/mobireg_data_provider.dart`
- Create: `lib/data/providers/mobireg/mobireg_view_cache.dart`
- Modify: `lib/data/providers/demo/demo_data_provider.dart`
- Modify: `lib/presentation/auth/widgets/add_account_form.dart`
- Modify: `lib/wear/screens/wear_setup_screen.dart`
- Modify: `lib/data/services/fcm_token_manager.dart`
- Modify: `lib/app/sync_provider.dart`
- Modify: `lib/data/services/sync_snapshot.dart`
- Test: `test/unit/data/mobireg_app_api_provider_test.dart` (new),
  `test/unit/data/provider_hydration_test.dart` (rewrite Mobireg group),
  `test/unit/data/mobireg_reauthentication_test.dart` (rewrite),
  `test/integration/notification/fcm_token_registration_test.dart`,
  `test/unit/wear/wear_student_picker_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1 to 5.
- Produces (provider interface, replacing the hash-based methods):
  ```dart
  @immutable
  class AccountProbe {
    const AccountProbe({required this.schoolName, required this.students});
    final String? schoolName;
    final List<Student> students;
  }

  abstract class SchoolDataProvider {
    Future<void> authenticate({required String school, required String login, required String password});
    Future<Result<AccountProbe>> probeAccount({required String school, required String login, required String password});
    Future<bool> registerPushToken({required String school, required String login, required String password, required String token});
  }
  ```
  `hashPassword`, `validateCredentials`, `fetchStudents` and the
  `legacyPasswordHash` parameter are removed. `probeAccount` makes one login
  and one `users` call (add-account used to make two logins).
- `MobiregViewCache(SyncCache cache)`: `void save(String key, Object data)`,
  `Object? load(String key)`. Keys: `terms`, `subjects`, `marks_<termId>`,
  `timetable`, `attendance-stats`, `tests`, `reprimands`, `announcements`.
  Backed by two new `SyncCache` methods `saveView`/`loadView` storing JSON
  under `mobireg_view_<key>`.

Provider behaviour:
- Sessions live in `Map<String, AppApiSession>` keyed by `'$school/$login'`;
  a password change for the same key replaces the session. `authenticate`,
  `probeAccount` and `registerPushToken` all go through it, so the active
  account logs in once per process.
- `authenticate` with an empty password sets `reauthRequiredProvider` (Task
  6 renames `portalReauthRequiredProvider`; see Step 3) and every load
  returns early. That is how pre-switch accounts reach the password dialog.
- `loadSchoolData(ref, studentId)`, in this order, each through the session:
  1. `account()`; if `studentId` is not among `pupils`, throw
     `StateError('Pupil $studentId is not on this account')` so the sync
     fails visibly (Review Focus 5).
  2. `terms`, `subjects`.
  3. `marks` with `termId` for every non-year term (`TermType.semester`).
  4. `timetable-events` from the year term's `dateFrom` to `dateTo`.
  5. `attendance-stats`, `tests`, `reprimands` (`limit=100`),
     `announcements`.
  Parse every payload; on success write the providers
  (`termsProvider`, `subjectsProvider`, `teachersProvider` from marks,
  `resolvedGradesProvider`, `resolvedEventsProvider`, `attendancesProvider`,
  `attendanceTypesProvider`, `testsProvider`, `reprimandsProvider`,
  `bulletinsProvider`, `studentsProvider`) and the view cache. Any
  `Failure` throws `Exception('Mobireg view <name> failed: <failure>')`.
  A parser `FormatException` propagates.
- `hydrateFromCache` re-parses the cached views through the same apply
  function; returns true when `timetable` was cached.
- `capabilities` drops `homework` and `changelog` (the official app reads
  neither view; homework shows up as entries of `tests`). Task 9 adds the
  per-school module switches on top.
- `registerPushToken` sends view `register-fcm` with params
  `{'token': fcmToken}` and no `pupilId`. The official app builds the form
  as `view, format, token=<jwt>, JWTToken=<jwt>` and then adds the extra
  params, so the FCM token **replaces** the JWT under `token` (same key
  position) and the server authenticates through `JWTToken`. The map
  literal in `AppApiDataSource.getView` (`...params` last) already does
  exactly this; the test below pins it.
- `parseFcmMessage`: drop the `noSync` read (`triggersSync` is always
  true); v3 payloads no longer carry it.
- `SyncSnapshot`: add a `version` field (2) saved with the snapshot; a
  stored snapshot with another version loads as null, so the first sync
  after the switch takes a baseline and notifies nothing (Review Focus 2).
  Delete `SyncSnapshot.fromSyncData` (its only caller is gone).

- [ ] **Step 1: Write the failing tests**

`test/unit/data/mobireg_app_api_provider_test.dart` drives the real
provider against a fake app API (same `InterceptorsWrapper` pattern, base
URL injected through a new optional constructor parameter
`MobiregDataProvider({ApiClientFactory Function(String school)? clientFactory})`
whose default builds the production factory). The fake answers each view
from the fixtures of Tasks 3 to 5 and counts logins.

```dart
void main() {
  late ProviderContainer container;
  late _FakeAppServer server;
  late MobiregDataProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    server = _FakeAppServer.fromFixtures();
    provider = MobiregDataProvider(clientFactory: server.factoryFor);
  });

  Ref ref() => container.read(Provider((ref) => ref));

  test('a full load logs in once and fills every provider', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(server.logins, 1);
    expect(server.views, containsAll(<String>[
      'users', 'terms', 'subjects', 'marks', 'timetable-events',
      'attendance-stats', 'tests', 'reprimands', 'announcements',
    ]));
    expect(container.read(resolvedEventsProvider), isNotEmpty);
    expect(container.read(resolvedGradesProvider), isNotEmpty);
    expect(container.read(attendancesProvider), isNotEmpty);
    expect(container.read(testsProvider), isNotEmpty);
  });

  test('asks marks once per semester, not for the school year', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(server.markTermIds, unorderedEquals(['4', '7']));
  });

  test('asks the whole school year of timetable in one call', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(server.timetableRanges, [('2026-09-01', '2027-08-31')]);
  });

  test('a second sync reuses the session', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(server.logins, 1);
  });

  test('a pupil missing from the account fails the sync', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');

    expect(
      () => provider.loadSchoolData(ref(), studentId: 6541),
      throwsStateError,
    );
  });

  test('an account saved before the switch asks for the password', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: '');
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(server.logins, 0);
    expect(container.read(reauthRequiredProvider), isTrue);
  });

  test('probeAccount makes one login and one users call', () async {
    final probe = await provider.probeAccount(
      school: 'sp1', login: 'p', password: 's');

    expect(probe.valueOrNull!.students.single.id, 6339);
    expect(server.logins, 1);
    expect(server.views, ['users']);
  });

  test('hydrateFromCache restores the last load without the network',
      () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);
    final fresh = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(
        container.read(sharedPreferencesProvider)),
    ]);
    addTearDown(fresh.dispose);

    final restored = MobiregDataProvider(clientFactory: server.factoryFor)
        .hydrateFromCache(
          fresh.read(Provider((ref) => ref)),
          fresh.read(syncCacheProvider),
        );

    expect(restored, isTrue);
    expect(fresh.read(resolvedEventsProvider), isNotEmpty);
  });

  test('registerPushToken sends register-fcm without a pupil', () async {
    final ok = await provider.registerPushToken(
      school: 'sp1', login: 'p', password: 's', token: 'fcm-123');

    expect(ok, isTrue);
    final body = server.lastBodyFor('register-fcm');
    expect(body.containsKey('pupilId'), isFalse);
    expect(body['token'], 'fcm-123');
    expect(body['JWTToken'], server.issuedToken);
    expect(body.keys.toList(), ['view', 'format', 'token', 'JWTToken']);
  });
}
```

Write `_FakeAppServer` in the test file: it answers `/auth.php` with a
token, `/app.php` by `view` from `loadMobiregFixture` (`terms`, `subjects`,
`marks_term4` for `termId=4`, `marks_empty` otherwise, `timetable_events`,
`attendance_stats`, `tests`, `reprimands`, `announcements`, `users`,
`{"success": true}` for `register-fcm`), records `views`, `markTermIds`,
`timetableRanges`, bodies and `issuedToken`, accepts a request whose
`token` or `JWTToken` equals `issuedToken`, and exposes
`ApiClientFactory factoryFor(String school)` that returns a factory whose
`createAppApiClient()` is the faked `Dio`. Give `ApiClientFactory` a
`@visibleForTesting` constructor taking the `Dio` to return, or make
`createAppApiClient` overridable in a test subclass; pick whichever needs
fewer changes and state it in the commit.

Snapshot test (append to the existing sync-provider tests, or create
`test/unit/data/sync_snapshot_test.dart`):

```dart
test('a snapshot from before the switch is ignored', () async {
  SharedPreferences.setMockInitialValues({
    'sync_snapshot': jsonEncode({'markIds': [1], 'attendanceIds': [2]}),
  });
  final prefs = await SharedPreferences.getInstance();

  expect(await SyncSnapshot.load(prefs), isNull);
});
```

Update `mobireg_reauthentication_test.dart`, `provider_hydration_test.dart`,
`fcm_token_registration_test.dart` and `wear_student_picker_test.dart` to
the new interface (no hash, `probeAccount`).

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/unit/data test/integration/notification test/unit/wear`
Expected: FAIL to compile (new interface not there yet).

- [ ] **Step 3: Implement**

1. `school_data_provider.dart`: replace `hashPassword`,
   `validateCredentials`, `fetchStudents` with `probeAccount`; drop
   `legacyPasswordHash` from `authenticate`; `registerPushToken` takes
   `password`. Add `AccountProbe` next to the interface.
2. Rename `PortalReauthRequired` to `ReauthRequired` in
   `lib/app/reauth_provider.dart` (provider `reauthRequiredProvider`); fix
   `portal_reauth_dialog.dart` and every reader. Rename the dialog file and
   widget to `reauth_dialog.dart` / `ReauthDialog` in the same step.
3. `DemoDataProvider`: implement `probeAccount` returning its demo student
   and `null` school name; drop the removed methods.
4. `add_account_form.dart` and `wear_setup_screen.dart`: one
   `probeAccount` call replaces validate + fetchStudents; delete the
   `_passwordHash` field in the wear screen.
5. `fcm_token_manager.dart`: pass `account.password`; skip (and log with
   `debugPrint`) accounts whose password is empty instead of sending a
   hash.
6. `sync_provider.dart`: stop passing `legacyPasswordHash`; `_Credentials`
   loses the field.
7. `MobiregDataProvider`: rewrite per the behaviour list above. Keep
   `loadMessages` and the poczta methods untouched in this task; they move
   in Task 7. Delete the `_PortalViewRequest` class, `_syncPortalData`,
   `_portalSessionManager`, `_openPortalSession`, `_njsonPassHash`,
   `hashPassword` and the `MobileSyncDataSource` imports from this file.
8. `SyncCache`: add `saveView(String key, Object data)` and
   `Object? loadView(String key)` (JSON under `mobireg_view_<key>`). Leave
   the old methods for Task 10 to delete.
9. `SyncSnapshot`: version field, version check in `load`, delete
   `fromSyncData`.

- [ ] **Step 4: Run to verify pass**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-warnings && flutter test`
Expected: analyze clean, all tests PASS. `test/unit/core/njson_wire_format_test.dart`,
`portal_session_test.dart` and `auth_service_test.dart` still pass because
their code still exists; Task 10 deletes them with it.

- [ ] **Step 5: Verify against the live server**

Run the app on the phone emulator (`bsharp_phone`) with the test account,
pull to refresh, and check grades, schedule (today and next week),
attendance, tests and notes populate. Dump the UI hierarchy before tapping
(memory note). Then check the request count:
`adb logcat -d | grep -c 'auth.php'` should be 1 for the whole session.

- [ ] **Step 6: Commit**

```bash
git add -A lib test
git commit -m "feat(mobireg): sync through the app API" -m "njson.php answers HTTP 500 to every data request, so sync was
dead. Load the account, terms, marks, timetable, attendance, tests,
notes and announcements through app.php with one login per account,
and replace the hash-based credential calls with one probeAccount.
Accounts saved with only a password hash now ask for the password,
and the change snapshot restarts so the switch notifies nothing."
```

### Task 7: Mail through the official flow

**Files:**
- Modify: `lib/data/data_sources/remote/poczta_data_source.dart`
- Modify: `lib/core/network/api_client_factory.dart` (`createPocztaClient`)
- Modify: `lib/data/providers/mobireg/mobireg_data_provider.dart`
  (`loadMessages`, `refreshMessages`)
- Test: `test/unit/data/poczta_data_source_test.dart` (new)

**Interfaces:**
- Consumes: `MobiregAccount.messagingUrl`, `MobiregAccount.messagesToken`
  (Task 5) via `AppApiSession.account()`.
- Produces: `PocztaDataSource` with the same public method names it has
  today, so `MobiregDataProvider`'s mail methods keep their shape:
  `establishSession({required String school, required String messagesToken})`,
  `getInbox`, `getSent`, `getTrash`, `getImportant`, `readMessage`,
  `sendMessage`, `deleteMessage`, `toggleStar`, `restoreMessage`,
  `searchReceivers`, `getReceiverTypes`, `getReceiversByType`,
  `downloadFile`, plus new `Future<Result<int>> unreadCount({required String school, required String messagesToken})`.

The request shapes are the "Mail" section of `app-api.md` (decompiled from
the official app's `mail_api.dart` / `mail_session.dart`). What changes
against today's `PocztaDataSource`:

| Today | Official app |
|---|---|
| SSO follows the redirect, then `GET /`, scrapes `csrfToken` | one `GET <messagingUrl>/<school>/<encodeComponent(token)>`, redirects off, nothing after |
| `X-CSRF-TOKEN`, `X-Requested-With` headers | neither; `Content-Type`/`Accept: application/json`, user agent, `Cookie` |
| folder page size 25, important/trash without paging | `{limit: 20, skip}` on all four folders, `query` only when non-empty |
| receivers search `{query}` | `{query, ids: []}` |
| session lost on 401/403 means failure | re-run the SSO once and replay the call |
| no unread count | `POST /api/unreadMessages {school, messagesToken}`, no cookie, plain-integer body |
| base URL fixed to poczta.mobireg.pl | `messagingUrl` from `users` minus its trailing `/sso` |

Unchanged (already matches): `PUT /api/messages` to send with
`{title, content, odbiorcy, previousMessageId}`, `GET /api/messages/read/<id>`,
`DELETE /api/messages/<id>`, `POST .../stared` and `.../restore` with `{}`,
`POST /api/messages/receivers` with `{}` or `{type}`, multipart upload to
`/api/messages/<id>/files`.

- [ ] **Step 1: Write the failing tests** (`test/unit/data/poczta_data_source_test.dart`)

The fake answers the SSO with `Set-Cookie: laravel_session=abc; path=/` and
`XSRF-TOKEN=x; path=/`, `/api/unreadMessages` with the text `3`, folders
with `{"items": [], "total": 0}`, everything else with `{}`. A switch
`expireOnce` makes the next API call answer 401.

```dart
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

test('pages every folder by 20', () async {
  final seen = <RequestOptions>[];
  final source = PocztaDataSource(client: _fakePoczta(seen));
  await source.establishSession(school: 'sp1', messagesToken: 't');

  await source.getSent(skip: 20);
  await source.getImportant();
  await source.getTrash();

  expect(seen.skip(1).map((o) => o.data), [
    {'limit': 20, 'skip': 20},
    {'limit': 20, 'skip': 0},
    {'limit': 20, 'skip': 0},
  ]);
});

test('signs in again once after a 401 and replays the call', () async {
  final seen = <RequestOptions>[];
  final server = _PocztaFake()..expireOnce = true;
  final source = PocztaDataSource(client: server.client(seen));
  await source.establishSession(school: 'sp1', messagesToken: 't');

  final result = await source.getInbox();

  expect(result, isA<Success<List<dynamic>>>());
  expect(seen.where((o) => o.path.startsWith('/sso/')).length, 2);
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
  final seen = <RequestOptions>[];
  final source = PocztaDataSource(client: _fakePoczta(seen));
  await source.establishSession(school: 'sp1', messagesToken: 't');

  await source.searchReceivers('Nowak');

  expect(seen.last.path, '/api/messages/receivers/search');
  expect(seen.last.data, {'query': 'Nowak', 'ids': <Object>[]});
});
```

Add one test each for send (`PUT /api/messages`, body keys), read, delete,
star, restore and receivers, asserting verb, path and body from the table.
`_fakePoczta(seen)` is `_PocztaFake().client(seen)`.

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/unit/data/poczta_data_source_test.dart`
Expected: FAIL on the `/` request, the CSRF header, the page size and the
missing `unreadCount`.

- [ ] **Step 3: Implement**

- `PocztaDataSource`: hold `String? _cookie` and the SSO inputs
  (`_school`, `_messagesToken`) so it can re-run the SSO.
  `establishSession` sends one `GET` with
  `Options(followRedirects: false, validateStatus: (s) => s != null && s < 500, headers: {'Accept': 'text/html'})`,
  collects `response.headers['set-cookie']`, cuts each at `;`, trims, drops
  empties, joins with `'; '`; empty means
  `Result.failure(SessionExpired(message: 'Poczta SSO returned no cookie'))`.
  Every API call goes through one `_call` helper that adds the headers,
  maps 401/403 to a single re-SSO + replay, and a second 401/403 to
  `SessionExpired`. `hasSession` is `_cookie != null`.
- Delete `_csrfToken`, the `/` request, the redirect-following code and
  the `x-redirect-location` handling.
- `createPocztaClient(String messagingUrl)`: base URL is `messagingUrl`
  without its trailing `/sso` (web: `$_proxy/poczta`; `MOBIREG_BASE_URL`
  override unchanged), user agent `AppConstants.appUserAgent`, no
  `X-Requested-With`, no `CookieManager` (the data source sends the cookie
  itself, so web and native behave the same and `WebCookieInterceptor`
  becomes dead; Task 10 deletes it, `X-Cookie-Jar` in the proxy too).
- `MobiregDataProvider.loadMessages`: take `messagingUrl` and
  `messagesToken` from `parseAccount(await session.account())`; skip mail
  with a `debugPrint` when either is missing.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test && flutter analyze --fatal-warnings`
Expected: PASS. Live check only if poczta is back up (it answered 500 for
the official app on 2026-10-04); if still down, say so in the commit body.

- [ ] **Step 5: Commit**

```bash
git add lib/data/data_sources/remote/poczta_data_source.dart \
  lib/core/network/api_client_factory.dart \
  lib/data/providers/mobireg/mobireg_data_provider.dart \
  test/unit/data/poczta_data_source_test.dart
git commit -m "feat(mobireg): talk to poczta like the official app" -m "Mail now signs in with the users view's messagesToken in a single
SSO request and sends its cookie, as the official 3.x client does.
The CSRF page scrape and the extra page load are calls the official
app never makes, so poczta can drop them at any time."
```

### Task 8: Web proxy and mock server

**Files:**
- Modify: `proxy/src/index.ts`
- Modify: `lib/data/providers/mobireg/test-mock/server.js`, `data.js`,
  `README.md`, `TESTING.md`, `openapi.yaml`
- Modify: `test/integration/mobireg_mock_test.dart`

**Interfaces:**
- Consumes: the request shapes of Tasks 1 and 7.
- Produces: proxy routes `/sync/<school>/(auth|app).php` (existing
  pattern, tightened) and `/poczta/...`; mock routes
  `POST /:school/modules/api/auth.php`, `POST /:school/modules/api/app.php`,
  poczta as in Task 7.

- [ ] **Step 1: Write the failing test.** Rewrite
  `test/integration/mobireg_mock_test.dart` to hit the mock's `auth.php`
  (expects `{"status":"OK","token":...}`), then `app.php` with
  `view=terms` and the token (expects the envelope with `v == 1`), then
  `app.php` without a token (expects HTTP 401), then the poczta SSO + inbox
  `POST` with the cookie. Delete its njson and `api.php` cases.

- [ ] **Step 2: Run to verify failure**

Run: `cd lib/data/providers/mobireg/test-mock && npm start &` then
`flutter test --tags integration test/integration/mobireg_mock_test.dart`
Expected: FAIL (mock has no auth.php route).

- [ ] **Step 3: Implement**

`server.js`: replace the `njson.php`, `index.php` and `/api.php` routes
with:
```js
app.post('/:school/modules/api/auth.php', express.json(), (req, res) => {
  const { login, password } = req.body;
  if (login !== data.credentials.login || password !== data.credentials.password) {
    return res.json({ status: 'ERROR', message: 'Nieprawidłowy login lub hasło' });
  }
  res.json({ status: 'OK', token: data.jwt, user: { id: 1, login, role: 2 } });
});

app.post('/:school/modules/api/app.php', express.urlencoded({ extended: false }), (req, res) => {
  const token = req.body.token || req.body.JWTToken;
  if (token !== data.jwt) {
    return res.status(401).json({ status: 'ERROR', message: 'Brak tokenu autoryzacji' });
  }
  const view = data.appViews[req.body.view];
  const payload = view === undefined ? { errno: 103, message: 'No view exist' } : view(req.body);
  res.json({ v: 1, serverTime: new Date().toISOString(), ttlFresh: 60, ttlRetain: 1209600, data: payload });
});
```
`data.js`: replace `njson` and `portalViews` with `credentials`, `jwt`,
and `appViews` (functions of the request body returning the Task 3 to 5
fixture shapes, with the mock's own fake names). Change the poczta routes
to the Task 7 verbs. Update the mock's README, TESTING and `openapi.yaml`
to describe only these endpoints.

`proxy/src/index.ts`: delete the `/portal/` and `/login/` routes and the
`rodzic.mobireg.pl` rewrite; restrict `/sync/` to
`^\/sync\/([^/]+)\/(auth|app)\.php$`; set `USER_AGENT` to
`'MobiReg/3.1.3 (296c220)'` for `app.php` and leave auth.php without one
(the browser's own); keep `/poczta/` routes but set the same user agent.
Run `cd proxy && npx tsc --noEmit` to typecheck.

- [ ] **Step 4: Run to verify pass**

Run the mock, then `flutter test --tags integration test/integration/mobireg_mock_test.dart`
and `cd proxy && npx tsc --noEmit`.
Expected: PASS, no type errors. Also run the web build against the mock:
`flutter run -d chrome --dart-define=MOBIREG_BASE_URL=http://localhost:8090`
and confirm one sync completes.

- [ ] **Step 5: Commit** (two commits: proxy, then mock + test)

```bash
git add proxy/src/index.ts
git commit -m "fix(proxy): forward only the app API endpoints" -m "The web build now reaches mobireg through auth.php and app.php
only. Drop the portal and web-login routes the client no longer
uses, and send the user agent the official app sends."
git add lib/data/providers/mobireg/test-mock test/integration/mobireg_mock_test.dart
git commit -m "test(mock): serve the app API instead of njson" -m "The mock server answered the legacy endpoints BSharp no longer
calls. Serve auth.php, app.php and poczta as the provider now uses
them, so integration tests exercise the real code path."
```

### Task 9: Respect the modules a school enabled

The `users` view's `appConfig.modules` says which modules the school
switched on. Intersect the capability set with it (`attendances` gates
`attendance`, `reprimands` gates `notes`, `timetable` gates `schedule`,
`announcements` gates `bulletins`; before the account loads, report the
static set) and skip the requests for disabled modules.

**Files:**
- Modify: `lib/data/providers/mobireg/mobireg_data_provider.dart`
- Test: `test/unit/data/mobireg_app_api_provider_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
test('hides the modules the school switched off', () async {
  server.users['appConfig'] = {
    'modules': {'attendances': 0, 'reprimands': 1, 'timetable': 1, 'announcements': 0},
  };
  await provider.authenticate(school: 'sp1', login: 'p', password: 's');
  await provider.loadSchoolData(ref(), studentId: 6339);

  expect(provider.supports(DataProviderCapability.attendance), isFalse);
  expect(provider.supports(DataProviderCapability.bulletins), isFalse);
  expect(provider.supports(DataProviderCapability.schedule), isTrue);
  expect(server.views, isNot(contains('attendance-stats')));
  expect(server.views, isNot(contains('announcements')));
});

test('never offers homework or changelog', () {
  expect(provider.supports(DataProviderCapability.homework), isFalse);
  expect(provider.supports(DataProviderCapability.changelog), isFalse);
});
```

- [ ] **Step 2: Run to verify failure**, **Step 3: implement** (skip the
  view fetches for disabled modules; the capability set is read by
  `main_shell.dart`, which already hides tabs), **Step 4: run to verify
  pass** with `flutter test test/unit/data/mobireg_app_api_provider_test.dart`.

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(mobireg): respect the modules a school enabled" -m "The users view says which modules the school switched on. Hide
the tabs and skip the requests for the ones it switched off, as the
official app does, instead of showing empty screens."
```

---

## Phase 3: Cleanup (no dead code left)

Each cleanup task ends with the same proof: a grep showing zero references
and `flutter analyze --fatal-warnings && flutter test` green.

### Task 10: Delete the legacy transport

**Files (delete):**
- `lib/data/data_sources/remote/mobile_sync_data_source.dart`
- `lib/data/data_sources/remote/portal_data_source.dart`
- `lib/data/data_sources/remote/portal_session.dart`
- `lib/data/data_sources/remote/auth_service.dart`
- `lib/core/network/interceptors/mobile_auth_interceptor.dart`
- `lib/core/network/interceptors/web_cookie_interceptor.dart` (and the
  `X-Cookie-Jar` handling in `proxy/src/index.ts`)
- `test/unit/core/njson_wire_format_test.dart`
- `test/unit/core/mobile_auth_interceptor_test.dart`
- `test/unit/data/portal_session_test.dart`
- `test/unit/data/auth_service_test.dart`

**Files (modify):**
- `lib/core/network/api_client_factory.dart`: delete
  `createMobileSyncClient`, `createTokenUploadClient`, `_createNjsonClient`,
  `createPortalClient`, `createWebLoginClient`, the
  `_parentLogin`/`_parentPassHash` fields and constructor parameters.
- `lib/core/constants/app_constants.dart`: delete `protocolVersion`,
  `fixedLogin`, `fixedPassword`, `deviceId`, `userAgent`, `appVersionCode`,
  `syncAcceptEncoding`, `syncContentType`, `tokenUploadUserAgent`,
  `tokenUploadAcceptEncoding`, `tokenUploadContentType`, `syncWindowDays`,
  `maxRetryCount` (check each has no reader first), and
  `connectTimeoutMs`/`receiveTimeoutMs` if poczta now uses
  `appApiTimeoutMs`.
- `lib/core/network/interceptors/error_mapping_interceptor.dart`: delete
  `onResponse` (only njson and the portal put `errno` at the top level) and
  its test cases.
- `lib/data/services/sync_cache.dart`: delete `saveSyncData`,
  `loadSyncData`, `savePortalView`, `loadPortalView`; on construction remove
  their stored keys once (`prefs.remove`) so upgraded installs do not carry
  dead JSON.

- [ ] **Step 1:** delete and edit as listed.
- [ ] **Step 2:** prove nothing refers to them:
  ```bash
  grep -rnE "njson|MobileSync|PortalDataSource|PortalSession|AuthService|MobileAuthInterceptor|createWebLoginClient|createPortalClient|createMobileSyncClient|createTokenUploadClient|rodzic\.mobireg|index\.php|api\.php|Andreg|eparent|okhttp" lib test integration_test proxy/src
  ```
  Expected: no output (the only allowed mention is in `docs/`).
- [ ] **Step 3:** `flutter analyze --fatal-warnings && flutter test`. PASS.
- [ ] **Step 4: Commit**

```bash
git add -A lib test
git commit -m "refactor(mobireg): remove the legacy endpoints" -m "njson.php, the portal api.php and the index.php web login are
no longer called. Delete their data sources, interceptor, client
builders, constants and tests, and drop their cached payloads."
```

### Task 11: Delete the njson data model

**Files (delete):**
- `lib/data/services/sync_data_parser.dart`
- `lib/data/providers/mobireg/mobireg_schedule_resolver.dart`
- `lib/data/providers/mobireg/mobireg_grade_resolver.dart`
- From `lib/data/providers/mobireg/mobireg_sync_applier.dart`:
  `applySyncData`, `applyPortalHomeworks`, `applyPortalChangelog`,
  `parseBulletins`, `parseChangelog`, `parseReprimands`, `parseTests`,
  `parseHomeworks` (replaced by Task 5). If nothing is left but
  `applyMessages`, move it into `mobireg_message_handler.dart` and delete
  the file.
- `test/unit/data/mobireg_sync_applier_test.dart` (its normalisation cases
  move to the Task 5 parser tests; copy the `'leaves an unknown subject
  name alone'` and `'leaves a missing subject name empty'` cases over first).
- Domain entities used only by the njson parser. Candidates:
  `event.dart`, `lesson.dart`, `mark.dart`, `group.dart`,
  `organization.dart`, `permission.dart`, `room.dart`, `message.dart`,
  `user_reprimand.dart`, `settings.dart`, and the njson-only enums in
  `sync_action.dart` (`Sex` once Task 12 lands, `ReprimandKind` if unused).
- `lib/domain/repositories/` (seven interfaces with no implementation).

- [ ] **Step 1:** for each candidate, confirm it is dead before deleting:
  ```bash
  for f in event lesson mark group organization permission room message user_reprimand settings; do
    cls=$(grep -oE "abstract class [A-Za-z]+" lib/domain/entities/$f.dart | awk '{print $3}' | paste -sd'|')
    echo "$f: $(grep -rlE "\b($cls)\b" lib test --include=*.dart | grep -v "lib/domain/entities/$f\.\|sync_data_parser\|\.g\.dart\|\.freezed\.dart" | tr '\n' ' ')"
  done
  ```
  Delete every entity whose line lists no file. Keep the others and note
  why in the commit body.
- [ ] **Step 2:** delete the files and their generated `.freezed.dart`;
  run `dart run build_runner build --delete-conflicting-outputs`.
- [ ] **Step 3:** `flutter analyze --fatal-warnings && flutter test`. PASS.
- [ ] **Step 4: Commit**

```bash
git commit -am "refactor(mobireg): remove the njson data model" -m "The app API delivers resolved data, so the relational njson
parser, the schedule and grade resolvers, the entities only they
used and the never-implemented repository interfaces are dead."
```

### Task 12: Drop the njson Drift tables and legacy account fields

**Files:**
- Modify: `lib/data/data_sources/local/database.dart`: remove every njson
  mirror table from `@DriftDatabase(tables: [...])` and their classes,
  keeping `Accounts` only if a DAO reads it (check), `SyncMetadata` only if
  read, `TranslationCacheEntries`, `CustomEvents`, `CustomEventOccurrences`,
  `IgnoredAttendances`; bump `schemaVersion` to 5 with a migration step
  that drops each removed table (`m.deleteTable('<sql name>')`).
- Modify: `lib/domain/entities/student.dart`: remove `usersEduId` and
  `sex`; fix `child_provider.dart`, demo provider, account parser,
  `wear_student_picker_test.dart`, `entities_test.dart`.
- Modify: `lib/domain/entities/teacher.dart`: remove `login`,
  `usersEduId`, `userType`, `phone`, `pin` if nothing reads them (grep).
- Modify: `lib/domain/entities/provider_account.dart`: remove
  `legacyPasswordHash`; `migrateLegacyJson` keeps turning an old
  `passwordHash` into `password: ''` (and drops the hash), so
  `needsReauth` becomes `password.isEmpty`. Update
  `provider_account_test.dart`.
- Modify: `lib/domain/entities/sync_action.dart`: remove `Sex` if unused.
- Test: `test/unit/data/database_migration_test.dart` (new).

- [ ] **Step 1: Write the failing migration test**

```dart
test('migrating from v4 drops the njson tables and keeps custom events',
    () async {
  final verifier = SchemaVerifier(GeneratedHelper());
  final connection = await verifier.startAt(4);
  final db = AppDatabase(connection);
  await verifier.migrateAndValidate(db, 5);
  await db.close();
});
```

This needs the drift schema snapshots. Generate them first:
`dart run drift_dev make-migrations` (configure `databases:` in
`build.yaml` if it is not there). If the project has no schema history,
dump v4 from the current code before changing it, then v5 after.

- [ ] **Step 2:** run, expect FAIL (no v5).
- [ ] **Step 3:** implement as listed; regenerate code.
- [ ] **Step 4:** `flutter analyze --fatal-warnings && flutter test`. PASS.
  Install the build over the existing app on the emulator and confirm
  custom events and ignored attendances survive the upgrade.
- [ ] **Step 5: Commit**

```bash
git commit -am "refactor(db): drop the njson mirror tables" -m "These 36 tables mirrored njson.php and were never written. Drop
them in schema v5, and remove the account and student fields only
njson filled: the password hash, sex and the edu ids."
```

### Task 13: Docs and memory

**Files:**
- Modify: `docs/providers/mobireg/README.md`: replace the five-API table
  with app API + poczta; remove njson curl examples and the sync-parser
  rows.
- Delete: `docs/providers/mobireg/data-model.md` (36 njson tables).
- Modify: `docs/providers/mobireg/error-codes.md`: errno now arrives inside
  the envelope; 401 means expired session; 102 means a wrong pupil.
- Modify: `docs/providers.md` interface table (`probeAccount`, no
  `hashPassword`).
- Memory: update `MEMORY.md` API Details (drop the njson/portal lines and
  the portal curl cheatsheet, point at `app-api.md`).

- [ ] **Step 1:** edit; **Step 2:** `grep -rn "njson\|api.php\|hashPassword" docs README.md` shows only historical notes in `app-api.md`; **Step 3: Commit** `docs(mobireg): describe the app API provider`.

---

## Follow-up plans (new data, new features)

The switch above already uses the new data that fits today's screens
(lesson substitutions and replacements, attendance types, school module
switches, announcement read state, one-call yearly timetable). The API
offers more that needs new UI, each worth its own brainstorm and plan once
this one lands:

1. **Proposed and final grades**: `marks.subjects[].value` with `isFinal`
   and `mtTeacherId` (term grade per subject, proposal vs final), plus
   `marks.subjects[].suggestView` and `appConfig.marks.parentSuggestionMode`.
2. **Descriptive assessment**: `marks.markDescriptives` (`zachowanie`,
   `obowiazkowe`, `zalecenia`) and `appConfig.marks.showDescriptive`.
3. **Tests on the lesson**: `timetable-events[].tests[]` (`testType`,
   `testLabel`) to badge a lesson in the schedule and link to the test.
4. **Excusing absences in the app**: `justification-events` lists the
   lessons that can be excused; REST `/api/justifications` lists, creates,
   edits and deletes excuse notes (`{pupil_id, message, event_ids}`). Pairs
   with BSharp's existing unexcused-absence alert.
5. **Announcement polls**: `announcements[].pollOpen`, `answers`,
   `userAnswer`, `declined`, `pending`, answered through view
   `announcement-answer` (`id`, `answer` or `decline=1`);
   `announcements-pending` drives a "needs your answer" badge.
6. **Server-side push preferences**: view `notif-settings` read and write
   (`marks`, `attendance`, `exams`, `reprimands`, `messages`,
   `announcements`, `substitutions`, `cancellations`, `planChanges`). The
   last three default to off, which is why BSharp never sees those pushes.
7. **Targeted refresh from pushes**: apply the official app's
   push-kind-to-view table (app-api.md, "Caching and push") to refetch only
   the affected views instead of a full sync.
8. **Mail unread badge**: `PocztaDataSource.unreadCount` (added in Task 7)
   on the mail tab, no SSO needed.
