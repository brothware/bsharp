import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Pins the desktop branch of isTranslationAvailable so the assertions turn
    // on the language rule rather than on whether ML Kit happens to be there.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<ProviderContainer> containerFor(String locale) async {
    SharedPreferences.setMockInitialValues({'locale': locale});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('contentLanguageProvider', () {
    test('reports the language the active provider writes in', () async {
      final container = await containerFor('en');

      container.read(activeDataProviderProvider.notifier).value =
          MobiregDataProvider();
      expect(container.read(contentLanguageProvider), 'pl');

      container.read(activeDataProviderProvider.notifier).value =
          DemoDataProvider();
      expect(container.read(contentLanguageProvider), 'en');
    });
  });

  group('isTranslationAvailable', () {
    test(
      'is off when the reader already speaks the provider language',
      () async {
        final container = await containerFor('en');
        container.read(activeDataProviderProvider.notifier).value =
            DemoDataProvider();

        expect(container.read(isTranslationAvailableProvider), isFalse);
      },
    );

    test('is on when the provider writes in another language', () async {
      final container = await containerFor('en');
      container.read(activeDataProviderProvider.notifier).value =
          MobiregDataProvider();

      expect(container.read(isTranslationAvailableProvider), isTrue);
    });

    test('is off for a Polish reader on a Polish provider', () async {
      final container = await containerFor('pl');
      container.read(activeDataProviderProvider.notifier).value =
          MobiregDataProvider();

      expect(container.read(isTranslationAvailableProvider), isFalse);
    });
  });
}
