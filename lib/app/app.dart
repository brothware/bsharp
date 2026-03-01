import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';

class BSharpApp extends ConsumerStatefulWidget {
  const BSharpApp({super.key});

  @override
  ConsumerState<BSharpApp> createState() => _BSharpAppState();
}

class _BSharpAppState extends ConsumerState<BSharpApp> {
  bool _initialSyncTriggered = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
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
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) {
        _initialSyncTriggered = false;
        final router = createRouter(authState: AuthState.unauthenticated);
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
          Future.microtask(
            () => ref.read(syncStatusProvider.notifier).sync(),
          );
        }
        if (authState != AuthState.authenticated) {
          _initialSyncTriggered = false;
        }
        final router = createRouter(authState: authState);
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
