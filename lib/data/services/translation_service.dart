import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/database.dart';
import 'package:bsharp/data/data_sources/local/mlkit_translation_source.dart';
import 'package:bsharp/data/data_sources/remote/deepl_data_source.dart';

enum TranslationEngine { mlKit, deepL }

class TranslationService {
  TranslationService({
    AppDatabase? database,
    MlKitTranslationSource? mlKit,
    DeepLDataSource? deepL,
  })  : _database = database,
        _mlKit = mlKit,
        _deepL = deepL;

  final AppDatabase? _database;
  final MlKitTranslationSource? _mlKit;
  final DeepLDataSource? _deepL;

  bool get isAvailable => _mlKit != null || _deepL != null;

  TranslationEngine get preferredEngine =>
      _deepL != null ? TranslationEngine.deepL : TranslationEngine.mlKit;

  Future<Result<String>> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'pl',
    bool isHtml = false,
  }) async {
    final hash = _sourceHash(text, targetLang);
    final db = _database;

    if (db != null) {
      final cached = await (db.select(db.translationCacheEntries)
            ..where((t) =>
                t.sourceHash.equals(hash) & t.targetLang.equals(targetLang)))
          .getSingleOrNull();

      if (cached != null) {
        return Result.success(cached.translatedText);
      }
    }

    final result = _deepL != null
        ? await _translateWithDeepL(text, sourceLang, targetLang, isHtml)
        : await _translateWithMlKit(text, sourceLang, targetLang);

    return result.when(
      success: (translated) async {
        await db?.into(db.translationCacheEntries).insert(
              TranslationCacheEntriesCompanion.insert(
                sourceHash: hash,
                targetLang: targetLang,
                translatedText: translated,
              ),
            );
        return Result.success(translated);
      },
      failure: Result.failure,
    );
  }

  Future<Result<({int used, int limit})>> getDeeplUsage() async {
    if (_deepL == null) {
      return const Result.failure(
        TranslationFailed(message: 'DeepL not configured'),
      );
    }
    return _deepL.getUsage();
  }

  Future<bool> isMlKitModelDownloaded(String langCode) async {
    return _mlKit?.isModelDownloaded(langCode) ?? false;
  }

  Future<bool> downloadMlKitModel(String langCode) async {
    return _mlKit?.downloadModel(langCode) ?? false;
  }

  Future<void> deleteMlKitModel(String langCode) async {
    await _mlKit?.deleteModel(langCode);
  }

  Future<void> clearCache() async {
    final db = _database;
    if (db != null) {
      await db.delete(db.translationCacheEntries).go();
    }
  }

  Future<void> dispose() async {
    await _mlKit?.close();
    _deepL?.dispose();
  }

  Future<Result<String>> _translateWithDeepL(
    String text,
    String sourceLang,
    String targetLang,
    bool isHtml,
  ) async {
    final result = await _deepL!.translate(
      texts: [text],
      sourceLang: sourceLang,
      targetLang: targetLang,
      isHtml: isHtml,
    );
    return result.map((translations) => translations.first);
  }

  Future<Result<String>> _translateWithMlKit(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    if (_mlKit == null) {
      return const Result.failure(
        TranslationFailed(message: 'ML Kit not available'),
      );
    }
    return _mlKit.translate(
      text: text,
      sourceLang: sourceLang,
      targetLang: targetLang,
    );
  }

  static String _sourceHash(String text, String targetLang) {
    final bytes = utf8.encode('$text:$targetLang');
    return sha256.convert(bytes).toString();
  }
}
