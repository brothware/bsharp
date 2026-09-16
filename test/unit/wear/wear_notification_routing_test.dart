import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_attendance_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_grades_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_home.dart';
import 'package:bsharp/wear/screens/wear_homework_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_message_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_messages_list_screen.dart';
import 'package:bsharp/wear/screens/wear_notes_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_schedule_detail_screen.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/wear_notification_router.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

class _FakeAuthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState.authenticated;

  @override
  Future<void> completeSetup() async {}

  @override
  Future<void> logout() async {}
}

class _FakeSyncStatusNotifier extends SyncStatusNotifier {
  _FakeSyncStatusNotifier([this.result = const ChangeSet()]);

  final ChangeSet result;

  @override
  SyncStatus build() => SyncStatus.completed;

  @override
  Future<ChangeSet> sync() async => result;
}

class _FakeNotificationService extends NotificationService {
  void Function(NotificationPayload)? capturedOnTap;
  NotificationPayload? launchPayload;

  @override
  Future<void> initialize({void Function(NotificationPayload)? onTap}) async {
    capturedOnTap = onTap;
  }

  @override
  Future<NotificationPayload?> getLaunchPayload() async => launchPayload;

  @override
  Future<bool> requestPermission() async => true;
}

Future<AccountStorage> _accountStorageWithOneStudent() async {
  final storage = AccountStorage(store: FakeKeyValueStore());
  await storage.saveAccounts([
    const ProviderAccount(
      id: 'a1',
      providerType: 'mobireg',
      slug: 'osm-wroclaw',
      login: 'login',
      students: [AccountStudent(id: 1, name: 'Jan', surname: 'Kowalski')],
    ),
  ]);
  await storage.saveActiveSelection(
    const ActiveSelection(accountId: 'a1', studentId: 1),
  );
  return storage;
}

PocztaMessage _wearMessage(int id) => PocztaMessage(
  id: id,
  title: 'Temat $id',
  senderName: 'Jan Kowalski',
  sendTime: DateTime(2026, 9, 16),
  isRead: false,
  isStarred: false,
);

ChangeSet _wearMessageChanges(List<int> ids) => ChangeSet(
  changes: [
    for (final id in ids)
      ChangeItem(
        category: ChangeCategory.messages,
        title: 'Nowa wiadomosc',
        entityId: id,
      ),
  ],
);

Future<Widget> _buildApp(
  _FakeNotificationService service, {
  List<PocztaMessage> inbox = const [],
  ChangeSet syncResult = const ChangeSet(),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final credentialStorage = CredentialStorage(store: FakeKeyValueStore());
  final accountStorage = await _accountStorageWithOneStudent();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authStateProvider.overrideWith(_FakeAuthNotifier.new),
      credentialStorageProvider.overrideWithValue(credentialStorage),
      accountStorageProvider.overrideWithValue(accountStorage),
      notificationServiceProvider.overrideWithValue(service),
      syncStatusProvider.overrideWith(
        () => _FakeSyncStatusNotifier(syncResult),
      ),
      inboxProvider.overrideWithBuild((ref, _) => inbox),
      wearScreenShapeProvider.overrideWith(
        (_) => WearScreenShape.rectangular,
      ),
    ],
    child: TranslationProvider(child: const BSharpWearApp()),
  );
}

void main() {
  group('wearScreenBuilderForCategory', () {
    test('maps every known notification kind to its screen', () {
      expect(
        wearScreenBuilderForCategory(ChangeCategory.grades)!(_ctx),
        isA<WearGradesDetailScreen>(),
      );
      expect(
        wearScreenBuilderForCategory(ChangeCategory.messages)!(_ctx),
        isA<WearMessagesListScreen>(),
      );
      expect(
        wearScreenBuilderForCategory(ChangeCategory.schedule)!(_ctx),
        isA<WearScheduleDetailScreen>(),
      );
      expect(
        wearScreenBuilderForCategory(ChangeCategory.attendance)!(_ctx),
        isA<WearAttendanceDetailScreen>(),
      );
      expect(
        wearScreenBuilderForCategory(ChangeCategory.homework)!(_ctx),
        isA<WearHomeworkDetailScreen>(),
      );
      expect(
        wearScreenBuilderForCategory(ChangeCategory.notes)!(_ctx),
        isA<WearNotesDetailScreen>(),
      );
    });

    test('an unknown kind falls back to the top level', () {
      expect(wearScreenBuilderForCategory(null), isNull);
    });
  });

  group('BSharpWearApp notification routing', () {
    testWidgets('a warm tap on a grades push opens grades', (tester) async {
      final service = _FakeNotificationService();
      await tester.pumpWidget(await _buildApp(service));
      await tester.pump();
      await tester.pump();

      service.capturedOnTap!(
        const NotificationPayload(category: ChangeCategory.grades),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(WearGradesDetailScreen), findsOneWidget);
    });

    testWidgets('a cold start launch payload opens messages', (tester) async {
      final service = _FakeNotificationService()
        ..launchPayload = const NotificationPayload(
          category: ChangeCategory.messages,
        );
      await tester.pumpWidget(await _buildApp(service));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(WearMessagesListScreen), findsOneWidget);
    });

    testWidgets('a tap naming a message opens that message', (tester) async {
      final service = _FakeNotificationService();
      await tester.pumpWidget(
        await _buildApp(service, inbox: [_wearMessage(7), _wearMessage(8)]),
      );
      await tester.pump();
      await tester.pump();

      service.capturedOnTap!(
        const NotificationPayload(
          category: ChangeCategory.messages,
          itemId: 8,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(WearMessageDetailScreen), findsOneWidget);
    });

    testWidgets('a named message not yet fetched opens after the sync', (
      tester,
    ) async {
      final service = _FakeNotificationService()
        ..launchPayload = const NotificationPayload(
          category: ChangeCategory.messages,
          itemId: 9,
        );
      await tester.pumpWidget(
        await _buildApp(
          service,
          inbox: [_wearMessage(9)],
          syncResult: _wearMessageChanges([9]),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(WearMessageDetailScreen), findsOneWidget);
    });

    testWidgets('an unknown kind opens the app at the top level', (
      tester,
    ) async {
      final service = _FakeNotificationService();
      await tester.pumpWidget(await _buildApp(service));
      await tester.pump();
      await tester.pump();

      service.capturedOnTap!(
        const NotificationPayload(),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(WearHome), findsOneWidget);
    });
  });
}

const BuildContext _ctx = _FakeContext();

class _FakeContext implements BuildContext {
  const _FakeContext();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
