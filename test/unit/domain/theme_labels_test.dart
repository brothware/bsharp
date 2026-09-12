import 'package:bsharp/domain/theme_labels.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('themeModeIcon', () {
    test('maps system to brightness auto', () {
      expect(themeModeIcon(ThemeMode.system), Icons.brightness_auto);
    });

    test('maps light to light mode', () {
      expect(themeModeIcon(ThemeMode.light), Icons.light_mode);
    });

    test('maps dark to dark mode', () {
      expect(themeModeIcon(ThemeMode.dark), Icons.dark_mode);
    });
  });

  group('themeModeLabel', () {
    test('maps system to the system label', () {
      expect(themeModeLabel(ThemeMode.system), t.settings.themeSystem);
    });

    test('maps light to the light label', () {
      expect(themeModeLabel(ThemeMode.light), t.settings.themeLight);
    });

    test('maps dark to the dark label', () {
      expect(themeModeLabel(ThemeMode.dark), t.settings.themeDark);
    });
  });
}
