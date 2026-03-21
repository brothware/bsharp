import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/app.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({required String key}) async => _data[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

class MockNotificationPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

Future<void> setupMockApp(
  WidgetTester tester, {
  MockNotificationPlugin? notificationPlugin,
}) async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  registerFallbackValue(const InitializationSettings());
  registerFallbackValue(const NotificationDetails());

  final mockPlugin = notificationPlugin ?? MockNotificationPlugin();
  when(
    () => mockPlugin.initialize(
      settings: any(named: 'settings'),
      onDidReceiveNotificationResponse: any(
        named: 'onDidReceiveNotificationResponse',
      ),
      onDidReceiveBackgroundNotificationResponse: any(
        named: 'onDidReceiveBackgroundNotificationResponse',
      ),
    ),
  ).thenAnswer((_) async => true);
  when(
    () => mockPlugin.show(
      id: any(named: 'id'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      notificationDetails: any(named: 'notificationDetails'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => mockPlugin.cancel(
      id: any(named: 'id'),
      tag: any(named: 'tag'),
    ),
  ).thenAnswer((_) async {});
  when(mockPlugin.cancelAll).thenAnswer((_) async {});

  await LocaleSettings.setLocale(AppLocale.en);

  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(
            NotificationService(plugin: mockPlugin),
          ),
          accountStorageProvider.overrideWithValue(
            AccountStorage(store: _InMemoryKeyValueStore()),
          ),
          credentialStorageProvider.overrideWithValue(
            CredentialStorage(store: _InMemoryKeyValueStore()),
          ),
        ],
        child: const BSharpApp(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}
