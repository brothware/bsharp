import 'dart:async';

import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/notification_router.dart';
import 'package:bsharp/app/providers/attendance_providers.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/core/platform_capabilities.dart';
import 'package:bsharp/data/services/fcm_message_handler.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BSharpApp extends ConsumerStatefulWidget {
  const BSharpApp({super.key});

  @override
  ConsumerState<BSharpApp> createState() => _BSharpAppState();
}

class _BSharpAppState extends ConsumerState<BSharpApp> {
  bool _initialSyncTriggered = false;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  GoRouter? _router;
  AuthState? _routerAuthState;
  NotificationRouter? _notificationRouter;
  NotificationPayload? _pendingNotificationPayload;

  @override
  void initState() {
    super.initState();
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (isPushSupported) {
      _fcmSubscription = FirebaseMessaging.onMessage.listen((message) async {
        final spec = parseFcmMessageWithKnownProviders(message);
        final shouldSync = await ref
            .read(notificationServiceProvider)
            .handleForegroundFcmMessage(spec);
        if (shouldSync && _initialSyncTriggered) {
          final changes = await ref.read(syncStatusProvider.notifier).sync();
          _notificationRouter?.handleSyncCompleted(changes);
        }
      });
    }

    if (isMobile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_setUpNotifications());
      });

      ref.listenManual<List<UnexcusedAbsence>>(
        staleUnexcusedAbsencesProvider,
        (prev, next) async {
          if (prev?.length == next.length) return;
          final service = ref.read(notificationServiceProvider);
          await service.initialize();
          await service.showUnexcusedAbsenceAlert(next.length);
        },
      );
    }
  }

  Future<void> _setUpNotifications() async {
    final service = ref.read(notificationServiceProvider);
    _notificationRouter = NotificationRouter(
      ref: ref,
      routerProvider: () => _router,
    );
    await service.initialize(onTap: _handleNotificationTap);
    await service.requestPermission();
    final launchPayload = await service.getLaunchPayload();
    if (launchPayload != null) _handleNotificationTap(launchPayload);
  }

  void _handleNotificationTap(NotificationPayload payload) {
    if (_router == null) {
      _pendingNotificationPayload = payload;
      return;
    }
    _notificationRouter?.handleNotificationTap(payload);
  }

  void _flushPendingNotificationPayload() {
    final payload = _pendingNotificationPayload;
    if (payload == null) return;
    _pendingNotificationPayload = null;
    _notificationRouter?.handleNotificationTap(payload);
  }

  GoRouter _routerFor(AuthState authState) {
    if (_router == null || _routerAuthState != authState) {
      _router?.dispose();
      _router = createRouter(authState: authState);
      _routerAuthState = authState;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _flushPendingNotificationPayload();
      });
    }
    return _router!;
  }

  @override
  void dispose() {
    unawaited(_fcmSubscription?.cancel());
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(localeProvider);
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => MaterialApp(
        title: 'BSharp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) {
        _initialSyncTriggered = false;
        final router = _routerFor(AuthState.unauthenticated);
        return MaterialApp.router(
          title: 'BSharp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        );
      },
      data: (authState) {
        if (authState == AuthState.authenticated && !_initialSyncTriggered) {
          _initialSyncTriggered = true;
          final isDemo = ref.read(demoModeProvider);
          if (!isDemo) {
            // A notification tapped from a cold start waits on this sync to
            // bring in the item it was about.
            unawaited(
              Future.microtask(() async {
                final changes = await ref
                    .read(syncStatusProvider.notifier)
                    .sync();
                _notificationRouter?.handleSyncCompleted(changes);
              }),
            );
          } else {
            unawaited(
              Future.microtask(
                () => ref.read(syncStatusProvider.notifier).markCompleted(),
              ),
            );
          }
        }
        if (authState != AuthState.authenticated) {
          _initialSyncTriggered = false;
        }
        final router = _routerFor(authState);
        return MaterialApp.router(
          title: 'BSharp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        );
      },
    );
  }
}
