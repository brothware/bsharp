import 'package:dio/dio.dart';
import 'package:bsharp/core/error/result.dart';

class DeepLDataSource {
  DeepLDataSource({required String apiKey})
    : _client = Dio(
        BaseOptions(
          baseUrl: 'https://api-free.deepl.com',
          headers: {'Authorization': 'DeepL-Auth-Key $apiKey'},
        ),
      );

  final Dio _client;

  Future<Result<List<String>>> translate({
    required List<String> texts,
    required String targetLang,
    String sourceLang = 'PL',
    bool isHtml = false,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/v2/translate',
        data: {
          'text': texts,
          'source_lang': sourceLang.toUpperCase(),
          'target_lang': targetLang.toUpperCase(),
          if (isHtml) 'tag_handling': 'html',
        },
      );

      final translations = response.data?['translations'] as List<dynamic>?;
      if (translations == null) {
        return const Result.failure(
          TranslationFailed(message: 'Invalid DeepL response'),
        );
      }

      final results = translations
          .map((t) => (t as Map<String, dynamic>)['text'] as String)
          .toList();
      return Result.success(results);
    } on DioException catch (e) {
      if (e.response?.statusCode == 456) {
        return const Result.failure(TranslationQuotaExceeded());
      }
      return Result.failure(
        TranslationFailed(message: e.message ?? 'DeepL request failed'),
      );
    }
  }

  Future<Result<({int used, int limit})>> getUsage() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/v2/usage');
      final data = response.data;
      if (data == null) {
        return const Result.failure(
          TranslationFailed(message: 'Invalid usage response'),
        );
      }
      return Result.success((
        used: data['character_count'] as int,
        limit: data['character_limit'] as int,
      ));
    } on DioException catch (e) {
      return Result.failure(
        TranslationFailed(message: e.message ?? 'Failed to get DeepL usage'),
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
