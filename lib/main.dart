import 'package:bsharp/app/app.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/background_account_cache.dart';
import 'package:bsharp/data/services/background_sync_scheduler.dart';
import 'package:bsharp/data/services/background_sync_task.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (taskName == backgroundSyncTaskName ||
        taskName == Workmanager.iOSBackgroundTask) {
      return BackgroundSyncTask().execute();
    }
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (isMobile) {
    await Workmanager().initialize(callbackDispatcher);
  }

  final prefs = await SharedPreferences.getInstance();
  final cache = BackgroundAccountCache(prefs);

  if (isMobile && cache.getActiveSelection() == null) {
    try {
      await cache.syncFrom(AccountStorage());
    } on Object catch (e) {
      debugPrint('BackgroundAccountCache: initial sync failed: $e');
    }
  }

  if (isMobile && cache.getActiveSelection() != null) {
    WorkmanagerSyncScheduler.scheduleDelayedSync(
      delay: const Duration(seconds: 10),
    );
    debugPrint('main: scheduled expedited background sync');
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
