import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/mobireg/fixtures.dart';

const _unauthorized = 401;
const _ok = 200;

class _FakeAppApiFactory extends ApiClientFactory {
  _FakeAppApiFactory(this._client, String school)
    : super(school: school, parentLogin: '', parentPassHash: '');

  final Dio _client;

  @override
  Dio createAppApiClient() => _client;
}

class _FakeAppServer {
  _FakeAppServer.fromFixtures();

  final issuedToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e30.fake';
  final views = <String>[];
  final markTermIds = <String>[];
  final timetableRanges = <(String, String)>[];
  final _bodies = <String, Map<String, dynamic>>{};
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
        data: body,
      );
}

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
    expect(
      server.views,
      containsAll(<String>[
        'users',
        'terms',
        'subjects',
        'marks',
        'timetable-events',
        'attendance-stats',
        'tests',
        'reprimands',
        'announcements',
      ]),
    );
    expect(container.read(resolvedEventsProvider), isNotEmpty);
    expect(container.read(resolvedGradesProvider), isNotEmpty);
    expect(container.read(attendancesProvider), isNotEmpty);
    expect(container.read(testsProvider), isNotEmpty);
  });

  test('every view but users names the pupil', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(server.lastBodyFor('users').containsKey('pupilId'), isFalse);
    for (final view in server.views.where((view) => view != 'users')) {
      expect(server.lastBodyFor(view)['pupilId'], '6339', reason: view);
    }
    expect(server.lastBodyFor('reprimands')['limit'], '100');
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

  test('a changed password starts a new session', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);
    await provider.authenticate(school: 'sp1', login: 'p', password: 'new');
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(server.logins, 2);
  });

  test('a pupil missing from the account fails the sync', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');

    await expectLater(
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
      school: 'sp1',
      login: 'p',
      password: 's',
    );

    expect(probe.valueOrNull!.students.single.id, 6339);
    expect(server.logins, 1);
    expect(server.views, ['users']);
  });

  test('hydrateFromCache restores the last load without the network', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);
    final fresh = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          container.read(sharedPreferencesProvider),
        ),
      ],
    );
    addTearDown(fresh.dispose);

    final restored =
        MobiregDataProvider(
          clientFactory: server.factoryFor,
        ).hydrateFromCache(
          fresh.read(Provider((ref) => ref)),
          fresh.read(syncCacheProvider),
        );

    expect(restored, isTrue);
    expect(fresh.read(resolvedEventsProvider), isNotEmpty);
    expect(fresh.read(resolvedGradesProvider), isNotEmpty);
    expect(fresh.read(attendancesProvider), isNotEmpty);
  });

  test('registerPushToken sends register-fcm without a pupil', () async {
    final ok = await provider.registerPushToken(
      school: 'sp1',
      login: 'p',
      password: 's',
      token: 'fcm-123',
    );

    expect(ok, isTrue);
    final body = server.lastBodyFor('register-fcm');
    expect(body.containsKey('pupilId'), isFalse);
    expect(body['token'], 'fcm-123');
    expect(body['JWTToken'], server.issuedToken);
    expect(body.keys.toList(), ['view', 'format', 'token', 'JWTToken']);
  });
}
