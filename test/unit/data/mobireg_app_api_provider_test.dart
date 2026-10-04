import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/providers/more_providers.dart';
import 'package:bsharp/app/providers/schedule_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/remote/app_api_session_registry.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/mobireg/fake_app_server.dart';

void main() {
  late ProviderContainer container;
  late FakeAppServer server;
  late MobiregDataProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    server = FakeAppServer.fromFixtures();
    provider = MobiregDataProvider(
      clientFactory: server.factoryFor,
      sessions: AppApiSessionRegistry(),
    );
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

  test('two providers share one login per account', () async {
    final sessions = AppApiSessionRegistry();
    final first = MobiregDataProvider(
      clientFactory: server.factoryFor,
      sessions: sessions,
    );
    final second = MobiregDataProvider(
      clientFactory: server.factoryFor,
      sessions: sessions,
    );

    await first.probeAccount(school: 'sp1', login: 'p', password: 's');
    await second.registerPushToken(
      school: 'sp1',
      login: 'p',
      password: 's',
      token: 'fcm-123',
    );

    expect(server.logins, 1);
  });

  test('providers share the process-wide registry by default', () async {
    const school = 'registry-default';
    await MobiregDataProvider(
      clientFactory: server.factoryFor,
    ).probeAccount(school: school, login: 'p', password: 's');
    await MobiregDataProvider(
      clientFactory: server.factoryFor,
    ).probeAccount(school: school, login: 'p', password: 's');

    expect(server.logins, 1);
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

    await expectLater(
      () => provider.loadSchoolData(ref(), studentId: 6339),
      throwsA(isA<ReauthRequiredException>()),
    );
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
          sessions: AppApiSessionRegistry(),
        ).hydrateFromCache(
          fresh.read(Provider((ref) => ref)),
          fresh.read(syncCacheProvider),
        );

    expect(restored, isTrue);
    expect(fresh.read(resolvedEventsProvider), isNotEmpty);
    expect(fresh.read(resolvedGradesProvider), isNotEmpty);
    expect(fresh.read(attendancesProvider), isNotEmpty);
  });

  test('hides the modules the school switched off', () async {
    server.users['appConfig'] = {
      'modules': {
        'attendances': 0,
        'reprimands': 1,
        'timetable': 1,
        'announcements': 0,
      },
    };
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(provider.supports(DataProviderCapability.attendance), isFalse);
    expect(provider.supports(DataProviderCapability.bulletins), isFalse);
    expect(provider.supports(DataProviderCapability.schedule), isTrue);
    expect(provider.supports(DataProviderCapability.notes), isTrue);
    expect(server.views, isNot(contains('attendance-stats')));
    expect(server.views, isNot(contains('announcements')));
    expect(container.read(attendancesProvider), isEmpty);
    expect(container.read(bulletinsProvider), isEmpty);
    expect(container.read(resolvedEventsProvider), isNotEmpty);
  });

  test('skips timetable and reprimands when both are off', () async {
    server.users['appConfig'] = {
      'modules': {
        'attendances': 0,
        'reprimands': 0,
        'timetable': 0,
        'announcements': 1,
      },
    };
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(provider.supports(DataProviderCapability.schedule), isFalse);
    expect(provider.supports(DataProviderCapability.notes), isFalse);
    expect(server.views, isNot(contains('timetable-events')));
    expect(server.views, isNot(contains('reprimands')));
    expect(container.read(resolvedEventsProvider), isEmpty);
    expect(container.read(reprimandsProvider), isEmpty);
  });

  test('a later load clears the data of a module switched off', () async {
    await provider.authenticate(school: 'sp1', login: 'p', password: 's');
    await provider.loadSchoolData(ref(), studentId: 6339);
    expect(container.read(attendancesProvider), isNotEmpty);

    server.users['appConfig'] = {
      'modules': {'attendances': 0, 'reprimands': 1, 'timetable': 1},
    };
    await provider.loadSchoolData(ref(), studentId: 6339);

    expect(container.read(attendancesProvider), isEmpty);
    expect(container.read(bulletinsProvider), isEmpty);
  });

  test('reports every module before the account has loaded', () {
    expect(provider.supports(DataProviderCapability.attendance), isTrue);
    expect(provider.supports(DataProviderCapability.bulletins), isTrue);
  });

  test('hydrateFromCache restores which modules were off', () async {
    server.users['appConfig'] = {
      'modules': {'attendances': 0, 'reprimands': 1, 'timetable': 1},
    };
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
    final restoredProvider = MobiregDataProvider(
      clientFactory: server.factoryFor,
      sessions: AppApiSessionRegistry(),
    );

    final restored = restoredProvider.hydrateFromCache(
      fresh.read(Provider((ref) => ref)),
      fresh.read(syncCacheProvider),
    );

    expect(restored, isTrue);
    expect(
      restoredProvider.supports(DataProviderCapability.attendance),
      isFalse,
    );
    expect(
      restoredProvider.supports(DataProviderCapability.bulletins),
      isFalse,
    );
    expect(fresh.read(resolvedEventsProvider), isNotEmpty);
    expect(fresh.read(attendancesProvider), isEmpty);
  });

  test('never offers homework or changelog', () {
    expect(provider.supports(DataProviderCapability.homework), isFalse);
    expect(provider.supports(DataProviderCapability.changelog), isFalse);
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
