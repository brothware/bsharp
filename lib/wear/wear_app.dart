import 'dart:async';

import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_home.dart';
import 'package:bsharp/wear/screens/wear_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _wearDarkSurface = Color(0xFF000000);
const _wearLightSurface = Color(0xFFFAFAFA);

ThemeData wearTheme(ThemeData base) {
  final wearText = base.textTheme.copyWith(
    titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 15),
    titleSmall: base.textTheme.titleSmall?.copyWith(fontSize: 13),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 13),
    bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12),
    labelMedium: base.textTheme.labelMedium?.copyWith(fontSize: 11),
    labelSmall: base.textTheme.labelSmall?.copyWith(fontSize: 10),
  );
  final wearColorScheme = base.brightness == Brightness.dark
      ? base.colorScheme.copyWith(
          surface: _wearDarkSurface,
          surfaceContainerLowest: _wearDarkSurface,
          surfaceContainerLow: _wearDarkSurface,
          surfaceContainer: _wearDarkSurface,
          surfaceContainerHigh: _wearDarkSurface,
          surfaceContainerHighest: _wearDarkSurface,
        )
      : base.colorScheme.copyWith(surface: _wearLightSurface);
  return base.copyWith(
    colorScheme: wearColorScheme,
    textTheme: wearText,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    ),
    scrollbarTheme: const ScrollbarThemeData(
      thickness: WidgetStatePropertyAll(3),
      radius: Radius.circular(2),
      thumbVisibility: WidgetStatePropertyAll(true),
      minThumbLength: 24,
    ),
  );
}

class BSharpWearApp extends ConsumerStatefulWidget {
  const BSharpWearApp({super.key});

  @override
  ConsumerState<BSharpWearApp> createState() => _BSharpWearAppState();
}

class _BSharpWearAppState extends ConsumerState<BSharpWearApp> {
  bool _initialSyncTriggered = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(localeProvider);
    final authAsync = ref.watch(authStateProvider);

    final home = authAsync.when(
      data: (authState) {
        if (authState == AuthState.authenticated && !_initialSyncTriggered) {
          _initialSyncTriggered = true;
          unawaited(
            Future.microtask(
              () => ref.read(syncStatusProvider.notifier).sync(),
            ),
          );
        }
        if (authState != AuthState.authenticated) {
          _initialSyncTriggered = false;
        }
        return switch (authState) {
          AuthState.authenticated => const WearHome(),
          AuthState.unauthenticated => const WearSetupScreen(),
        };
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );

    return MaterialApp(
      title: 'BSharp',
      debugShowCheckedModeBanner: false,
      theme: wearTheme(AppTheme.light()),
      darkTheme: wearTheme(AppTheme.dark()),
      themeMode: themeMode,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );
  }
}
