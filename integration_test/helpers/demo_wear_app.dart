import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:bsharp/data/providers/demo_data_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/wear_crown_input.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _frozenDate = DateTime(2026, 3, 4, 10, 30);

final _setupRefProvider = Provider<Ref>((ref) => ref);

Future<ProviderContainer> pumpDemoWearApp(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.light,
  String locale = 'en',
}) async {
  final themeModeValue = themeMode == ThemeMode.dark ? 'dark' : 'light';
  SharedPreferences.setMockInitialValues({
    'locale': locale,
    'theme_mode': themeModeValue,
  });
  final prefs = await SharedPreferences.getInstance();

  await LocaleSettings.setLocaleRaw(locale);

  final demoProvider = DemoDataProvider();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(
        CredentialStorage(store: _InMemoryKeyValueStore()),
      ),
      activeDataProviderProvider.overrideWithBuild((ref, _) => demoProvider),
      demoModeProvider.overrideWithBuild((ref, _) => true),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.round),
      wearCrownEventsProvider.overrideWith((_) => const Stream.empty()),
    ],
  );

  final ref = container.read(_setupRefProvider);
  await demoProvider.loadSchoolData(ref, studentId: 1, now: _frozenDate);
  await demoProvider.loadMessages(ref, now: _frozenDate);
  await container.read(authStateProvider.future);
  await container.read(authStateProvider.notifier).completeSetup();
  container.read(syncStatusProvider.notifier).markCompleted();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(child: const BSharpWearApp()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

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
