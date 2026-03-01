import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/locale_provider.dart';
import 'package:bsharp/data/data_sources/local/connection/connection.dart';
import 'package:bsharp/data/data_sources/local/database.dart';
import 'package:bsharp/data/data_sources/local/mlkit_translation_source.dart';
import 'package:bsharp/data/data_sources/remote/deepl_data_source.dart';
import 'package:bsharp/data/services/translation_service.dart';

final _isMobileProvider = Provider<bool>((ref) {
  return !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
});

final translationDatabaseProvider = Provider<AppDatabase?>((ref) {
  final db = createTranslationDatabase();
  if (db != null) ref.onDispose(db.close);
  return db;
});

final translationServiceProvider = Provider<TranslationService>((ref) {
  final db = ref.watch(translationDatabaseProvider);
  final isMobile = ref.watch(_isMobileProvider);
  final mlKit = isMobile ? MlKitTranslationSource() : null;
  final deeplKey = ref.watch(deeplApiKeyProvider).valueOrNull;

  final deepL = deeplKey != null ? DeepLDataSource(apiKey: deeplKey) : null;

  final service = TranslationService(
    database: db,
    mlKit: mlKit,
    deepL: deepL,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final isTranslationAvailableProvider = Provider<bool>((ref) {
  final locale = ref.watch(localeProvider);
  if (locale.languageCode == 'pl') return false;
  final service = ref.watch(translationServiceProvider);
  return service.isAvailable;
});

final deeplApiKeyProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(credentialStorageProvider);
  return storage.getDeeplApiKey();
});
