import 'package:dio/dio.dart';
import 'package:bsharp/core/error/result.dart';

class PocztaDataSource {
  PocztaDataSource({required Dio client}) : _client = client;

  final Dio _client;
  String _csrfToken = '';

  Future<Result<void>> establishSession({
    required String school,
    required String messagesToken,
  }) async {
    try {
      final ssoResponse = await _client.get<String>(
        '/sso/$school/$messagesToken',
        options: Options(
          followRedirects: false,
          validateStatus: (status) =>
              status != null && (status < 400 || status == 302),
        ),
      );

      if (ssoResponse.statusCode == 302) {
        final location = ssoResponse.headers['location']?.first;
        if (location != null) {
          await _client.get<String>(location);
        }
      }

      final pageResponse = await _client.get<String>(
        '/',
        options: Options(headers: {'Accept': 'text/html'}),
      );
      final pageHtml = pageResponse.data ?? '';
      final csrfMatch =
          RegExp(r'"csrfToken":"([^"]+)"').firstMatch(pageHtml);
      if (csrfMatch != null) {
        _csrfToken = csrfMatch.group(1)!;
        return const Result.success(null);
      }

      return const Result.failure(
        UnknownFailure(message: 'Could not extract CSRF token'),
      );
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  bool get hasSession => _csrfToken.isNotEmpty;

  Future<Result<List<dynamic>>> getInbox({
    int limit = 25,
    int skip = 0,
  }) async {
    return _postMessages(
      '/api/messages/inbox',
      {'limit': limit, 'skip': skip},
    );
  }

  Future<Result<List<dynamic>>> getSent({
    int limit = 25,
    int skip = 0,
  }) async {
    return _postMessages(
      '/api/messages/sent',
      {'limit': limit, 'skip': skip},
    );
  }

  Future<Result<List<dynamic>>> getImportant() async {
    return _postMessages('/api/messages/important', {});
  }

  Future<Result<List<dynamic>>> getTrash() async {
    return _postMessages('/api/messages/trash', {});
  }

  Future<Result<Map<String, dynamic>>> readMessage(int messageId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/api/messages/read/$messageId',
        options: _authOptions(),
      );

      if (response.data == null) {
        return const Result.failure(NoData());
      }

      return Result.success(response.data!);
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  Future<Result<void>> sendMessage({
    required String title,
    required String content,
    required List<String> recipients,
    List<String>? copyTo,
    int? previousMessageId,
  }) async {
    try {
      await _client.put<dynamic>(
        '/api/messages',
        data: {
          'title': title,
          'content': content,
          'odbiorcy': recipients,
          'kopiaDo': copyTo ?? [],
          if (previousMessageId != null)
            'previousMessageId': previousMessageId,
        },
        options: _authOptions(),
      );
      return const Result.success(null);
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  Future<Result<void>> deleteMessage(int messageId) async {
    try {
      await _client.delete<dynamic>(
        '/api/messages/$messageId',
        options: _authOptions(),
      );
      return const Result.success(null);
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  Future<Result<void>> toggleStar(int messageId) async {
    try {
      await _client.post<dynamic>(
        '/api/messages/$messageId/stared',
        options: _authOptions(),
      );
      return const Result.success(null);
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  Future<Result<void>> restoreMessage(int messageId) async {
    try {
      await _client.post<dynamic>(
        '/api/messages/$messageId/restore',
        options: _authOptions(),
      );
      return const Result.success(null);
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  Future<Result<Map<String, dynamic>>> getReceiverTypes() async {
    try {
      final response = await _client.post<dynamic>(
        '/api/messages/receivers',
        data: <String, dynamic>{},
        options: _authOptions(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return Result.success(data);
      return const Result.success({'types': {}, 'users': []});
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  Future<Result<List<dynamic>>> getReceiversByType(String type) async {
    return _postMessages('/api/messages/receivers', {'type': type});
  }

  Future<Result<List<dynamic>>> searchReceivers(String query) async {
    return _postMessages(
      '/api/messages/receivers/search',
      {'query': query},
    );
  }

  Future<Result<List<dynamic>>> _postMessages(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post<dynamic>(
        path,
        data: body,
        options: _authOptions(),
      );
      final data = response.data;
      if (data is List) return Result.success(data);
      if (data is Map) {
        if (data.containsKey('items')) {
          return Result.success((data['items'] as List?) ?? []);
        }
        if (data.containsKey('data')) {
          return Result.success((data['data'] as List?) ?? []);
        }
      }
      return const Result.success([]);
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  Options _authOptions() {
    return Options(
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-TOKEN': _csrfToken,
        'X-Requested-With': 'XMLHttpRequest',
      },
    );
  }
}
