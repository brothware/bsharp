import 'dart:async';
import 'dart:ui';

import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'locale';

  static final List<Locale> supportedLocales = AppLocale.values
      .map((l) => l.flutterLocale)
      .toList();

  bool get isSystemLocale {
    final prefs = ref.read(sharedPreferencesProvider);
    return !prefs.containsKey(_key);
  }

  @override
  Locale build() {
    listenSelf((prev, next) {
      if (prev != null) {
        unawaited(LocaleSettings.setLocaleRaw(next.languageCode));
      }
    });

    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_key);
    if (stored != null) {
      final parts = stored.split('_');
      if (parts.length == 2) return Locale(parts[0], parts[1]);
      return Locale(stored);
    }
    return resolveSystemLocale();
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await prefs.setString(_key, key);
    state = locale;
  }

  Future<void> resetToSystem() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_key);
    state = resolveSystemLocale();
  }

  static Locale resolveSystemLocale() {
    final platform = PlatformDispatcher.instance.locale;
    final match = supportedLocales.any(
      (l) =>
          l.languageCode == platform.languageCode &&
          (l.countryCode == null || l.countryCode == platform.countryCode),
    );
    if (match) {
      return Locale(platform.languageCode, platform.countryCode);
    }
    final langOnly = supportedLocales.any(
      (l) => l.languageCode == platform.languageCode,
    );
    if (langOnly) return Locale(platform.languageCode);
    return const Locale('en');
  }
}

const _nativeNames = {
  'be': 'Беларуская',
  'bg': 'Български',
  'bs': 'Bosanski',
  'cs': 'Čeština',
  'da': 'Dansk',
  'de': 'Deutsch',
  'el': 'Ελληνικά',
  'en': 'English',
  'es': 'Español',
  'et': 'Eesti',
  'fi': 'Suomi',
  'fr': 'Français',
  'ga': 'Gaeilge',
  'hi': 'हिन्दी',
  'hr': 'Hrvatski',
  'hu': 'Magyar',
  'it': 'Italiano',
  'ja': '日本語',
  'ko': '한국어',
  'lt': 'Lietuvių',
  'lv': 'Latviešu',
  'mk': 'Македонски',
  'mt': 'Malti',
  'nb': 'Norsk bokmål',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'pt': 'Português',
  'ro': 'Română',
  'sk': 'Slovenčina',
  'sl': 'Slovenščina',
  'sq': 'Shqip',
  'sr': 'Srpski',
  'sv': 'Svenska',
  'tr': 'Türkçe',
  'uk': 'Українська',
  'zh_CN': '简体中文',
  'zh_TW': '繁體中文',
};

String localeDisplayName(Locale locale) {
  if (locale.countryCode != null) {
    final full = '${locale.languageCode}_${locale.countryCode}';
    final name = _nativeNames[full];
    if (name != null) return name;
  }
  return _nativeNames[locale.languageCode] ?? locale.languageCode;
}
