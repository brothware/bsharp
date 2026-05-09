import 'dart:async';

import 'package:bsharp/app/app.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/services/fcm_message_handler.dart';
import 'package:bsharp/data/services/fcm_token_manager.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  if (isMobile) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  }

  final prefs = await SharedPreferences.getInstance();

  if (isMobile) {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermission();

    FcmTokenManager(accountStorage: AccountStorage(), prefs: prefs)
      ..listenForTokenRefresh()
      ..registerTokenForAllAccounts().ignore();
  }

  final stored = prefs.getString('locale');
  final initialLocale =
      stored ?? LocaleNotifier.resolveSystemLocale().languageCode;
  await LocaleSettings.setLocaleRaw(initialLocale);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: TranslationProvider(child: const BSharpApp()),
    ),
  );
}
