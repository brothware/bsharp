import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses Material 3', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('light theme has correct color scheme brightness', () {
      final theme = AppTheme.light();
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark theme has correct color scheme brightness', () {
      final theme = AppTheme.dark();
      expect(theme.colorScheme.brightness, Brightness.dark);
    });
  });

  group('ThemeModeNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to system theme', () {
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('setThemeMode persists light', () async {
      await container.read(themeModeProvider.notifier).setThemeMode(
            ThemeMode.light,
          );
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('setThemeMode persists dark', () async {
      await container.read(themeModeProvider.notifier).setThemeMode(
            ThemeMode.dark,
          );
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('toggle cycles system -> light -> dark -> system', () async {
      final notifier = container.read(themeModeProvider.notifier);

      expect(container.read(themeModeProvider), ThemeMode.system);

      await notifier.toggle();
      expect(container.read(themeModeProvider), ThemeMode.light);

      await notifier.toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      await notifier.toggle();
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('restores persisted value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final newContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(newContainer.dispose);

      expect(newContainer.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
