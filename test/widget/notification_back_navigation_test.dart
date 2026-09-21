import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/notification_router.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/change_detection.dart';
import 'package:bsharp/domain/entities/poczta.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:bsharp/presentation/grades/screens/grades_screen.dart';
import 'package:bsharp/presentation/messages/screens/messages_screen.dart';
import 'package:bsharp/presentation/messages/widgets/message_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/data/credential_storage_test.dart';

final _message = PocztaMessage(
  id: 8,
  title: 'Zebranie',
  senderName: 'Jan Kowalski',
  sendTime: DateTime(2026, 9, 16),
  isRead: false,
  isStarred: false,
);

Future<AccountStorage> _accountStorage() async {
  final storage = AccountStorage(store: FakeKeyValueStore());
  await storage.saveAccounts([
    const ProviderAccount(
      id: 'a1',
      providerType: 'mobireg',
      slug: 'osm-wroclaw',
      login: 'login1',
      students: [AccountStudent(id: 1, name: 'Jan', surname: 'Kowalski')],
    ),
  ]);
  await storage.saveActiveSelection(
    const ActiveSelection(accountId: 'a1', studentId: 1),
  );
  return storage;
}

class _BackPressRecorder {
  bool appExited = false;

  void install(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') appExited = true;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  Future<void> press(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<(NotificationRouter, _BackPressRecorder)> pumpApp(
    WidgetTester tester,
  ) async {
    final accountStorage = await _accountStorage();
    final router = createRouter(authState: AuthState.authenticated);
    late NotificationRouter notificationRouter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          accountStorageProvider.overrideWithValue(accountStorage),
          inboxProvider.overrideWithBuild((ref, _) => [_message]),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            notificationRouter = NotificationRouter(
              ref: ref,
              routerProvider: () => router,
            );
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final backPress = _BackPressRecorder()..install(tester);
    return (notificationRouter, backPress);
  }

  void expectShowing(Type screen) {
    expect(find.byType(screen), findsOneWidget);
  }

  group('back from a screen a notification opened', () {
    testWidgets('a tab section returns to the dashboard before exiting', (
      tester,
    ) async {
      final (notificationRouter, backPress) = await pumpApp(tester);

      notificationRouter.handleNotificationTap(
        const NotificationPayload(category: ChangeCategory.grades),
      );
      await tester.pumpAndSettle();
      expectShowing(GradesScreen);

      await backPress.press(tester);
      expect(backPress.appExited, isFalse);
      expectShowing(DashboardScreen);

      await backPress.press(tester);
      expect(backPress.appExited, isTrue);
    });

    testWidgets('the message list returns to the dashboard before exiting', (
      tester,
    ) async {
      final (notificationRouter, backPress) = await pumpApp(tester);

      notificationRouter.handleNotificationTap(
        const NotificationPayload(category: ChangeCategory.messages),
      );
      await tester.pumpAndSettle();
      expectShowing(MessagesScreen);

      await backPress.press(tester);
      expect(backPress.appExited, isFalse);
      expectShowing(DashboardScreen);

      await backPress.press(tester);
      expect(backPress.appExited, isTrue);
    });

    testWidgets('a named message walks back through its list', (tester) async {
      final (notificationRouter, backPress) = await pumpApp(tester);

      notificationRouter.handleNotificationTap(
        const NotificationPayload(
          category: ChangeCategory.messages,
          itemId: 8,
        ),
      );
      await tester.pumpAndSettle();
      expectShowing(MessageDetailView);

      await backPress.press(tester);
      expect(backPress.appExited, isFalse);
      expectShowing(MessagesScreen);

      await backPress.press(tester);
      expect(backPress.appExited, isFalse);
      expectShowing(DashboardScreen);

      await backPress.press(tester);
      expect(backPress.appExited, isTrue);
    });
  });
}
