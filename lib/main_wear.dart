import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final shape = await container.read(wearScreenShapeProvider.future);
  container.dispose();

  final prefs = await SharedPreferences.getInstance();

  final stored = prefs.getString('locale');
  final initialLocale =
      stored ?? LocaleNotifier.resolveSystemLocale().languageCode;
  await LocaleSettings.setLocaleRaw(initialLocale);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        wearScreenShapeProvider.overrideWith((_) => shape),
      ],
      child: TranslationProvider(child: const BSharpWearApp()),
    ),
  );
}
