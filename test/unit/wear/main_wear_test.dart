import 'package:bsharp/main_wear.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('seedDefaultWearThemeMode', () {
    test('a fresh wear start resolves to dark', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await seedDefaultWearThemeMode(prefs);

      expect(prefs.getString(ThemeModeNotifier.preferenceKey), 'dark');
    });

    test('a watch left on system moves to dark', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeNotifier.preferenceKey: 'system',
      });
      final prefs = await SharedPreferences.getInstance();

      await seedDefaultWearThemeMode(prefs);

      expect(
        prefs.getString(ThemeModeNotifier.preferenceKey),
        'dark',
        reason:
            'the watch no longer offers system, and leaving it stored would '
            'resolve to a white screen with no row to change it from',
      );
    });

    test('an explicitly stored dark choice is still honoured', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeNotifier.preferenceKey: 'dark',
      });
      final prefs = await SharedPreferences.getInstance();

      await seedDefaultWearThemeMode(prefs);

      expect(prefs.getString(ThemeModeNotifier.preferenceKey), 'dark');
    });

    test('an explicitly stored light choice is still honoured', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeNotifier.preferenceKey: 'light',
      });
      final prefs = await SharedPreferences.getInstance();

      await seedDefaultWearThemeMode(prefs);

      expect(prefs.getString(ThemeModeNotifier.preferenceKey), 'light');
    });
  });
}
