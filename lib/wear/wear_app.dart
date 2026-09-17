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
import 'package:bsharp/wear/wear_notification_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _wearDarkSurface = Color(0xFF000000);
const _wearLightSurface = Color(0xFFFAFAFA);
const _trackAlpha = 0.24;

/// The wear theme flattens every surface container onto the background for
/// WO-V13, so a track painted in one of those is invisible. Tracks take this.
Color wearTrackColor(ColorScheme scheme) =>
    scheme.onSurface.withValues(alpha: _trackAlpha);

class WearScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

ThemeData wearTheme(ThemeData base) {
  final wearText = base.textTheme.copyWith(
    displaySmall: base.textTheme.displaySmall?.copyWith(fontSize: 22),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 16),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 14),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 13),
    labelMedium: base.textTheme.labelMedium?.copyWith(fontSize: 12),
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
    // ThemeData fixes the scaffold colour when it is built, so swapping the
    // scheme afterwards leaves it on the seeded surface. It showed at the
    // foot of any screen whose content stopped short of the bottom.
    scaffoldBackgroundColor: wearColorScheme.surface,
    textTheme: wearText,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    ),
  );
}

class BSharpWearApp extends ConsumerStatefulWidget {
  const BSharpWearApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  ConsumerState<BSharpWearApp> createState() => _BSharpWearAppState();
}

class _BSharpWearAppState extends ConsumerState<BSharpWearApp> {
  bool _initialSyncTriggered = false;
  WearNotificationRouter? _notificationRouter;

  @override
  void initState() {
    super.initState();
    unawaited(_initNotifications());
  }

  Future<void> _initNotifications() async {
    final router = _notificationRouter = WearNotificationRouter(
      ref: ref,
      navigatorKey: BSharpWearApp.navigatorKey,
    );
    final service = ref.read(notificationServiceProvider);
    await service.initialize(onTap: router.handleNotificationTap);
    final launchPayload = await service.getLaunchPayload();
    if (launchPayload != null) router.handleNotificationTap(launchPayload);
  }

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
            Future.microtask(() async {
              final changes = await ref
                  .read(syncStatusProvider.notifier)
                  .sync();
              _notificationRouter?.handleSyncCompleted(changes);
            }),
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
      navigatorKey: BSharpWearApp.navigatorKey,
      title: 'BSharp',
      debugShowCheckedModeBanner: false,
      scrollBehavior: WearScrollBehavior(),
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
