import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/providers/custom_event_providers.dart';
import 'package:bsharp/app/providers/grades_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/data_sources/remote/app_api_session_registry.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/data/services/sync_cache.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fixtures/mobireg/fake_app_server.dart';
import '../../fixtures/mobireg/fixtures.dart';
import '../data/credential_storage_test.dart';

class _SilentNotificationService extends NotificationService {
  @override
  Future<void> initialize({void Function(NotificationPayload)? onTap}) async {}

  @override
  Future<void> showUnexcusedAbsenceAlert(int count) async {}
}

const _pupilId = 6339;

const _account = ProviderAccount(
  id: 'a1',
  providerType: 'mobireg',
  slug: 'sp1',
  login: 'p',
  password: 's',
);

Future<ProviderContainer> _mobiregContainer({
  required FakeAppServer server,
  required ProviderAccount account,
  int pupilId = _pupilId,
}) {
  return _containerWith(
    provider: MobiregDataProvider(
      clientFactory: server.factoryFor,
      sessions: AppApiSessionRegistry(),
    ),
    account: account,
    pupilId: pupilId,
  );
}

Future<ProviderContainer> _containerWith({
  required SchoolDataProvider provider,
  required ProviderAccount account,
  int pupilId = _pupilId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final accountStorage = AccountStorage(store: FakeKeyValueStore());
  await accountStorage.saveAccounts([account]);
  await accountStorage.saveActiveSelection(
    ActiveSelection(accountId: account.id, studentId: pupilId),
  );
  final container = ProviderContainer(
    overrides: [
      credentialStorageProvider.overrideWithValue(_emptyStorage()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      accountStorageProvider.overrideWithValue(accountStorage),
      activeDataProviderProvider.overrideWithBuild((ref, _) => provider),
      notificationServiceProvider.overrideWithValue(
        _SilentNotificationService(),
      ),
      customEventDaoProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _SlowSchoolFailureProvider extends DemoDataProvider {
  _SlowSchoolFailureProvider(this.schoolFailure);

  final Exception schoolFailure;

  @override
  String get id => 'mobireg';

  @override
  bool get requiresCredentials => true;

  @override
  Future<void> authenticate({
    required String school,
    required String login,
    required String password,
  }) async {}

  @override
  Future<void> loadSchoolData(
    Ref ref, {
    required int studentId,
    DateTime? now,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (schoolFailure is ReauthRequiredException) {
      ref.read(reauthRequiredProvider.notifier).value = true;
    }
    throw schoolFailure;
  }

  @override
  Future<void> loadMessages(Ref ref, {DateTime? now}) async =>
      throw const MessagingException(SessionExpired());
}

class _MalformedMailDataProvider extends DemoDataProvider {
  @override
  Future<void> refreshMessages(Ref ref) async =>
      throw const FormatException('View poczta inbox: expected objects');
}

class _MailRejectedDataProvider extends DemoDataProvider {
  @override
  Future<void> refreshMessages(Ref ref) async =>
      throw const MessagingException(SessionExpired());
}

CredentialStorage _emptyStorage() =>
    CredentialStorage(store: FakeKeyValueStore());

void main() {
  group('SyncStatusNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          credentialStorageProvider.overrideWithValue(_emptyStorage()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          accountStorageProvider.overrideWithValue(
            AccountStorage(store: FakeKeyValueStore()),
          ),
        ],
      );
    });

    test('initial state is idle', () {
      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test(
      'sync transitions to syncing then failed without credentials',
      () async {
        final notifier = container.read(syncStatusProvider.notifier);
        final future = notifier.sync();
        expect(container.read(syncStatusProvider), SyncStatus.syncing);
        await future;
        expect(container.read(syncStatusProvider), SyncStatus.failed);
      },
    );

    test('a malformed mail payload during refresh fails the status', () async {
      final failing = ProviderContainer(
        overrides: [
          credentialStorageProvider.overrideWithValue(_emptyStorage()),
          sharedPreferencesProvider.overrideWithValue(
            container.read(sharedPreferencesProvider),
          ),
          accountStorageProvider.overrideWithValue(
            AccountStorage(store: FakeKeyValueStore()),
          ),
          activeDataProviderProvider.overrideWithBuild(
            (ref, _) => _MalformedMailDataProvider(),
          ),
        ],
      );
      addTearDown(failing.dispose);

      await failing.read(syncStatusProvider.notifier).syncMessages();

      expect(failing.read(syncStatusProvider), SyncStatus.failed);
    });

    test('a rejected mail refresh fails the status', () async {
      final failing = ProviderContainer(
        overrides: [
          credentialStorageProvider.overrideWithValue(_emptyStorage()),
          sharedPreferencesProvider.overrideWithValue(
            container.read(sharedPreferencesProvider),
          ),
          accountStorageProvider.overrideWithValue(
            AccountStorage(store: FakeKeyValueStore()),
          ),
          activeDataProviderProvider.overrideWithBuild(
            (ref, _) => _MailRejectedDataProvider(),
          ),
        ],
      );
      addTearDown(failing.dispose);

      await failing.read(syncStatusProvider.notifier).syncMessages();

      expect(failing.read(syncStatusProvider), SyncStatus.failed);
    });

    test('reset sets state to idle', () async {
      final notifier = container.read(syncStatusProvider.notifier);
      await notifier.sync();
      notifier.reset();
      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test('concurrent sync calls are ignored', () async {
      final notifier = container.read(syncStatusProvider.notifier);
      final future1 = notifier.sync();
      final future2 = notifier.sync();
      await Future.wait([future1, future2]);
      expect(container.read(syncStatusProvider), SyncStatus.failed);
    });
  });

  group('SyncStatusNotifier against the app API', () {
    late FakeAppServer server;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      server = FakeAppServer.fromFixtures();
    });

    test('a password-less account fails without saving a snapshot', () async {
      final container = await _mobiregContainer(
        server: server,
        account: _account.copyWith(password: ''),
      );

      await container.read(syncStatusProvider.notifier).sync();

      expect(container.read(syncStatusProvider), SyncStatus.failed);
      expect(container.read(reauthRequiredProvider), isTrue);
      expect(
        container.read(sharedPreferencesProvider).getString('sync_snapshot'),
        isNull,
      );
      expect(server.logins, 0);
    });

    test('a changed password fails without saving a snapshot', () async {
      server.rejectsPassword = true;
      final container = await _mobiregContainer(
        server: server,
        account: _account,
      );

      await container.read(syncStatusProvider.notifier).sync();

      expect(container.read(syncStatusProvider), SyncStatus.failed);
      expect(container.read(reauthRequiredProvider), isTrue);
      expect(
        container.read(sharedPreferencesProvider).getString('sync_snapshot'),
        isNull,
      );
    });

    test(
      're-entering the password notifies nothing on the next sync',
      () async {
        final container = await _mobiregContainer(
          server: server,
          account: _account.copyWith(password: ''),
        );
        final notifier = container.read(syncStatusProvider.notifier);
        await notifier.sync();

        await container.read(accountStorageProvider).updateAccount(_account);
        container.invalidate(providerAccountsProvider);
        final changes = await notifier.sync();

        expect(container.read(syncStatusProvider), SyncStatus.completed);
        expect(changes.isEmpty, isTrue);
      },
    );

    test('a pupil gone from the account asks to pick again', () async {
      final container = await _mobiregContainer(
        server: server,
        account: _account.copyWith(
          students: const [
            AccountStudent(id: 6541, name: 'Maria', surname: 'Kowalska'),
          ],
        ),
        pupilId: 6541,
      );

      await container.read(syncStatusProvider.notifier).sync();

      expect(container.read(syncStatusProvider), SyncStatus.failed);
      expect(container.read(missingPupilProvider), isTrue);
      final stored = await container.read(accountStorageProvider).getAccounts();
      expect(stored.single.students.map((student) => student.id), [6339]);
      expect(
        container
            .read(providerAccountsProvider)
            .value!
            .single
            .students
            .single
            .id,
        6339,
      );
    });

    test('a mail failure does not mask a missing pupil', () async {
      final container = await _containerWith(
        provider: _SlowSchoolFailureProvider(
          const PupilNotOnAccountException(
            pupilId: _pupilId,
            students: [Student(id: 6541, name: 'Maria', surname: 'Kowalska')],
          ),
        ),
        account: _account,
      );

      await container.read(syncStatusProvider.notifier).sync();

      expect(container.read(syncStatusProvider), SyncStatus.failed);
      expect(container.read(missingPupilProvider), isTrue);
    });

    test('a mail failure does not mask a reauth request', () async {
      final container = await _containerWith(
        provider: _SlowSchoolFailureProvider(const ReauthRequiredException()),
        account: _account,
      );

      await container.read(syncStatusProvider.notifier).sync();

      expect(container.read(syncStatusProvider), SyncStatus.failed);
      expect(container.read(reauthRequiredProvider), isTrue);
    });

    test('a completed sync clears the missing pupil state', () async {
      final container = await _mobiregContainer(
        server: server,
        account: _account,
      );
      container.read(missingPupilProvider.notifier).value = true;

      await container.read(syncStatusProvider.notifier).sync();

      expect(container.read(syncStatusProvider), SyncStatus.completed);
      expect(container.read(missingPupilProvider), isFalse);
    });

    test('a cache from another pupil is not shown', () async {
      final first = await _mobiregContainer(server: server, account: _account);
      await first.read(syncStatusProvider.notifier).sync();
      expect(first.read(resolvedGradesProvider), isNotEmpty);

      final second = await _mobiregContainer(
        server: server,
        account: _account,
        pupilId: 6541,
      );
      await second.read(syncStatusProvider.notifier).sync();

      expect(second.read(resolvedGradesProvider), isEmpty);
    });

    test('a mail failure fails the sync', () async {
      server.mailSignInFails = true;
      final container = await _mobiregContainer(
        server: server,
        account: _account,
      );

      await container.read(syncStatusProvider.notifier).sync();

      expect(container.read(syncStatusProvider), SyncStatus.failed);
    });

    test('an account with no mailbox syncs without mail', () async {
      server.users.remove('messagingUrl');
      server.users.remove('messagesToken');
      final container = await _mobiregContainer(
        server: server,
        account: _account,
      );

      await container.read(syncStatusProvider.notifier).sync();

      final provider = container.read(activeDataProviderProvider);
      expect(container.read(syncStatusProvider), SyncStatus.completed);
      expect(provider.supports(DataProviderCapability.messages), isFalse);
      expect(provider.supports(DataProviderCapability.sendMessages), isFalse);
    });

    test('an unreadable cache is cleared and the sync carries on', () async {
      final container = await _mobiregContainer(
        server: server,
        account: _account,
      );
      SyncCache(
        container.read(sharedPreferencesProvider),
      ).saveView('timetable', loadMobiregFixture('timetable_events'));
      final notifier = container.read(syncStatusProvider.notifier);

      await notifier.sync();
      final viewsAfterFirst = server.views.length;
      await notifier.sync();

      expect(container.read(syncStatusProvider), SyncStatus.completed);
      expect(viewsAfterFirst, greaterThan(0));
      expect(server.views.length, greaterThan(viewsAfterFirst));
    });
  });

  group('lastSyncTimeProvider', () {
    test('initial value is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(lastSyncTimeProvider), isNull);
    });

    test('can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final now = DateTime.now();
      container.read(lastSyncTimeProvider.notifier).value = now;
      expect(container.read(lastSyncTimeProvider), now);
    });
  });
}
