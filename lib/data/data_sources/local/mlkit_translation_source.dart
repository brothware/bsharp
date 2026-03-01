import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:bsharp/core/error/result.dart';

class MlKitTranslationSource {
  OnDeviceTranslator? _translator;
  TranslateLanguage? _currentSourceLang;
  TranslateLanguage? _currentTargetLang;
  var _hasTranslated = false;

  Future<Result<String>> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      final source = _languageFromCode(sourceLang);
      final target = _languageFromCode(targetLang);
      if (source == null || target == null) {
        return const Result.failure(
          TranslationFailed(message: 'Unsupported language pair'),
        );
      }

      if (_translator == null ||
          _currentSourceLang != source ||
          _currentTargetLang != target) {
        if (_hasTranslated) {
          await _translator?.close();
        }
        _translator = OnDeviceTranslator(
          sourceLanguage: source,
          targetLanguage: target,
        );
        _currentSourceLang = source;
        _currentTargetLang = target;
      }

      final result = await _translator!.translateText(text);
      _hasTranslated = true;
      return Result.success(result);
    } on Exception catch (e) {
      return Result.failure(TranslationFailed(message: e.toString()));
    }
  }

  Future<bool> isModelDownloaded(String langCode) async {
    final lang = _languageFromCode(langCode);
    if (lang == null) return false;
    final manager = OnDeviceTranslatorModelManager();
    return manager.isModelDownloaded(lang.bcpCode);
  }

  Future<bool> downloadModel(String langCode) async {
    final lang = _languageFromCode(langCode);
    if (lang == null) return false;
    final manager = OnDeviceTranslatorModelManager();
    return manager.downloadModel(lang.bcpCode);
  }

  Future<void> deleteModel(String langCode) async {
    final lang = _languageFromCode(langCode);
    if (lang == null) return;
    final manager = OnDeviceTranslatorModelManager();
    await manager.deleteModel(lang.bcpCode);
  }

  Future<void> close() async {
    if (_hasTranslated) {
      await _translator?.close();
    }
    _translator = null;
    _currentSourceLang = null;
    _currentTargetLang = null;
    _hasTranslated = false;
  }

  static TranslateLanguage? _languageFromCode(String code) {
    final normalized = code.toLowerCase();
    for (final lang in TranslateLanguage.values) {
      if (lang.bcpCode.toLowerCase() == normalized) return lang;
    }
    return null;
  }
}
