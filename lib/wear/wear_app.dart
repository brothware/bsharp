import 'dart:async';

import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:bsharp/wear/screens/wear_home.dart';
import 'package:bsharp/wear/screens/wear_reauth_screen.dart';
import 'package:bsharp/wear/screens/wear_setup_screen.dart';
import 'package:bsharp/wear/wear_notification_router.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _wearSurface = Color(0xFF000000);
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

ThemeData wearTheme() {
  final base = AppTheme.dark();
  final wearText = base.textTheme.copyWith(
    displaySmall: base.textTheme.displaySmall?.copyWith(fontSize: 22),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 16),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 14),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 13),
    labelMedium: base.textTheme.labelMedium?.copyWith(fontSize: 12),
    labelSmall: base.textTheme.labelSmall?.copyWith(fontSize: 12),
  );
  final wearColorScheme = base.colorScheme.copyWith(
    surface: _wearSurface,
    surfaceContainerLowest: _wearSurface,
    surfaceContainerLow: _wearSurface,
    surfaceContainer: _wearSurface,
    surfaceContainerHigh: _wearSurface,
    surfaceContainerHighest: _wearSurface,
  );
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
    await service.requestPermission();
    final launchPayload = await service.getLaunchPayload();
    if (launchPayload != null) router.handleNotificationTap(launchPayload);
  }

  @override
  Widget build(BuildContext context) {
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
          AuthState.authenticated => const WearReauthPrompt(child: WearHome()),
          AuthState.unauthenticated => const WearSetupScreen(),
        };
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) {
        debugPrint('BSharpWearApp: start failed: $error\n$stackTrace');
        return const _WearStartupError();
      },
    );

    return MaterialApp(
      navigatorKey: BSharpWearApp.navigatorKey,
      title: 'BSharp',
      debugShowCheckedModeBanner: false,
      scrollBehavior: WearScrollBehavior(),
      theme: wearTheme(),
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    );
  }
}

/// Reading the saved accounts failed. A spinner here would never end and
/// offer no way out, so the watch says so, can try again, and can be left.
class _WearStartupError extends ConsumerWidget {
  const _WearStartupError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return WearSwipeDismiss(
      onDismiss: () => unawaited(SystemNavigator.pop()),
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.errors.unknownError,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: Text(t.common.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
