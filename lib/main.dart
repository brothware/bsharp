import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/app.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final stored = prefs.getString('locale');
  final initialLocale =
      stored ?? LocaleNotifier.resolveSystemLocale().languageCode;
  LocaleSettings.setLocaleRaw(initialLocale);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: TranslationProvider(child: const BSharpApp()),
    ),
  );
}
