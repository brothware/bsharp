import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocaleNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    test('defaults to system locale when no stored preference', () {
      final locale = container.read(localeProvider);
      final supported = LocaleNotifier.supportedLocales.map(
        (l) => l.languageCode,
      );
      expect(supported, contains(locale.languageCode));
    });

    test('isSystemLocale is true when no stored preference', () {
      container.read(localeProvider);
      final notifier = container.read(localeProvider.notifier);
      expect(notifier.isSystemLocale, isTrue);
    });

    test('setLocale changes language and clears system mode', () async {
      final notifier = container.read(localeProvider.notifier);
      await notifier.setLocale(const Locale('en'));

      final locale = container.read(localeProvider);
      expect(locale.languageCode, 'en');
      expect(notifier.isSystemLocale, isFalse);
    });

    test('resetToSystem clears stored preference', () async {
      final notifier = container.read(localeProvider.notifier);
      await notifier.setLocale(const Locale('en'));
      expect(notifier.isSystemLocale, isFalse);

      await notifier.resetToSystem();
      expect(notifier.isSystemLocale, isTrue);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.containsKey('locale'), isFalse);
    });

    test('persists locale to SharedPreferences', () async {
      final notifier = container.read(localeProvider.notifier);
      await notifier.setLocale(const Locale('en'));

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString('locale'), 'en');
    });

    test('loads persisted locale', () async {
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final locale = c.read(localeProvider);
      expect(locale.languageCode, 'en');
    });

    test('supportedLocales contains pl and en', () {
      expect(LocaleNotifier.supportedLocales.length, greaterThanOrEqualTo(2));
      expect(
        LocaleNotifier.supportedLocales.map((l) => l.languageCode),
        containsAll(['pl', 'en']),
      );
    });
  });

  group('localeDisplayName', () {
    test('returns Polski for pl', () {
      expect(localeDisplayName(const Locale('pl')), 'Polski');
    });

    test('returns English for en', () {
      expect(localeDisplayName(const Locale('en')), 'English');
    });

    test('returns Deutsch for de', () {
      expect(localeDisplayName(const Locale('de')), 'Deutsch');
    });

    test('returns language code for unknown locale', () {
      expect(localeDisplayName(const Locale('xx')), 'xx');
    });
  });
}
