import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Wear OS has no user-facing light/dark switch and reports night mode off,
/// so [ThemeMode.system] resolves to a white watch. The watch picks one.
const List<ThemeMode> wearThemeModes = [ThemeMode.light, ThemeMode.dark];

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const preferenceKey = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(preferenceKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(preferenceKey, value);
    state = mode;
  }

  Future<void> toggle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }
}
