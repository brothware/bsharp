import 'package:bsharp/l10n/strings.g.dart';
import 'package:flutter/material.dart';

IconData themeModeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.light_mode,
    ThemeMode.dark => Icons.dark_mode,
  };
}

String themeModeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => t.settings.themeSystem,
    ThemeMode.light => t.settings.themeLight,
    ThemeMode.dark => t.settings.themeDark,
  };
}
