import 'package:bsharp/core/error/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const _pageSize = 20;
const _unauthorized = 401;
const _forbidden = 403;
const _serverErrorFloor = 500;
const _clientErrorFloor = 400;
const _successFloor = 200;
const _redirectFloor = 300;

class _CookieChannel {
  const _CookieChannel({required this.isWeb});

  final bool isWeb;

  String get requestHeader => isWeb ? 'X-Cookie-Jar' : 'Cookie';

  String fromResponse(Headers headers) {
    if (isWeb) {
      return headers.value('x-cookie-jar') ?? '';
    }
    return (headers['set-cookie'] ?? const <String>[])
        .map((value) => value.split(';').first.trim())
        .where((value) => value.isNotEmpty)
        .join('; ');
  }
}

class PocztaDataSource {
  PocztaDataSource({required this._client, bool isWeb = kIsWeb})
    : _cookieChannel = _CookieChannel(isWeb: isWeb);

  final Dio _client;
  final _CookieChannel _cookieChannel;
  String? _cookie;
  String? _school;
  String? _messagesToken;

  bool get hasSession => _cookie != null;

  Future<Result<void>> establishSession({
    required String school,
    required String messagesToken,
  }) async {
    _school = school;
    _messagesToken = messagesToken;
    return _signIn();
  }

  Future<Result<void>> _signIn() async {
    final school = _school;
    final messagesToken = _messagesToken;
    if (school == null || messagesToken == null) {
      return const Result.failure(
        SessionExpired(message: 'Poczta session was never established'),
      );
    }
    try {
      final response = await _client.get<String>(
        '/sso/$school/${Uri.encodeComponent(messagesToken)}',
        options: Options(
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status < _serverErrorFloor,
          headers: {'Accept': 'text/html'},
        ),
      );
      final cookie = _cookieChannel.fromResponse(response.headers);
      if (cookie.isEmpty) {
        _cookie = null;
        return const Result.failure(
          SessionExpired(message: 'Poczta SSO returned no cookie'),
        );
      }
      _cookie = cookie;
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.failure(_failureOf(e));
    }
  }

  Future<Result<List<dynamic>>> getInbox({int skip = 0, String query = ''}) {
    return _folder('inbox', skip, query);
  }

  Future<Result<List<dynamic>>> getSent({int skip = 0, String query = ''}) {
    return _folder('sent', skip, query);
  }

  Future<Result<List<dynamic>>> getTrash({int skip = 0, String query = ''}) {
    return _folder('trash', skip, query);
  }

  Future<Result<List<dynamic>>> _folder(String folder, int skip, String query) {
    return _postMessages('/api/messages/$folder', {
      'limit': _pageSize,
      'skip': skip,
      if (query.isNotEmpty) 'query': query,
    });
  }

  Future<Result<Map<String, dynamic>>> readMessage(int messageId) async {
    final result = await _call(
      (options) => _client.get<dynamic>(
        '/api/messages/read/$messageId',
        options: options,
      ),
    );
    return result.when(
      success: (response) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return Result.success(data);
        }
        return const Result.failure(NoData());
      },
      failure: Result.failure,
    );
  }

  Future<Result<void>> sendMessage({
    required String title,
    required String content,
    required List<String> recipients,
    List<String>? copyTo,
    int? previousMessageId,
  }) async {
    final result = await _call(
      (options) => _client.put<dynamic>(
        '/api/messages',
        data: {
          'title': title,
          'content': content,
          'odbiorcy': recipients,
          'kopiaDo': copyTo ?? [],
          'previousMessageId': ?previousMessageId,
        },
        options: options,
      ),
    );
    return result.when(
      success: (_) => const Result.success(null),
      failure: Result.failure,
    );
  }

  Future<Result<void>> deleteMessage(int messageId) async {
    final result = await _call(
      (options) => _client.delete<dynamic>(
        '/api/messages/$messageId',
        options: options,
      ),
    );
    return result.when(
      success: (_) => const Result.success(null),
      failure: Result.failure,
    );
  }

  Future<Result<void>> toggleStar(int messageId) {
    return _postEmpty('/api/messages/$messageId/stared');
  }

  Future<Result<void>> restoreMessage(int messageId) {
    return _postEmpty('/api/messages/$messageId/restore');
  }

  Future<Result<void>> _postEmpty(String path) async {
    final result = await _call(
      (options) => _client.post<dynamic>(
        path,
        data: <String, dynamic>{},
        options: options,
      ),
    );
    return result.when(
      success: (_) => const Result.success(null),
      failure: Result.failure,
    );
  }

  Future<Result<List<dynamic>>> searchReceivers(String query) {
    return _postMessages('/api/messages/receivers/search', {
      'query': query,
      'ids': <Object>[],
    });
  }

  Future<Result<List<dynamic>>> _postMessages(
    String path,
    Map<String, dynamic> body,
  ) async {
    final result = await _call(
      (options) => _client.post<dynamic>(path, data: body, options: options),
    );
    return result.when(
      success: (response) {
        final data = response.data;
        if (data is List) {
          return Result.success(data);
        }
        if (data is Map) {
          if (data.containsKey('items')) {
            return Result.success((data['items'] as List?) ?? []);
          }
          if (data.containsKey('users')) {
            return Result.success((data['users'] as List?) ?? []);
          }
          if (data.containsKey('data')) {
            return Result.success((data['data'] as List?) ?? []);
          }
        }
        return const Result.success([]);
      },
      failure: Result.failure,
    );
  }

  Future<Result<void>> downloadFile(String url, String savePath) async {
    final baseUri = Uri.parse(_client.options.baseUrl);
    if (baseUri.resolve(url).authority != baseUri.authority) {
      return Result.failure(
        UnknownFailure(message: 'Refusing to download from foreign host: $url'),
      );
    }
    final result = await _call((options) async {
      try {
        return await _client.download(
          url,
          savePath,
          options: options.copyWith(
            validateStatus: (status) =>
                status != null &&
                status >= _successFloor &&
                status < _redirectFloor,
          ),
        );
      } on DioException catch (e) {
        final response = e.response;
        if (response != null && _isRejected(response)) {
          return response;
        }
        rethrow;
      }
    });
    return result.when(
      success: (_) => const Result.success(null),
      failure: Result.failure,
    );
  }

  Future<Result<Response<dynamic>>> _call(
    Future<Response<dynamic>> Function(Options options) send,
  ) async {
    try {
      var response = await send(_authorizedOptions());
      if (_isRejected(response)) {
        final signIn = await _signIn();
        if (signIn case Failure(:final failure)) {
          return Result.failure(failure);
        }
        response = await send(_authorizedOptions());
      }
      if (_isRejected(response)) {
        return const Result.failure(
          SessionExpired(message: 'Poczta rejected the session'),
        );
      }
      final status = response.statusCode ?? _clientErrorFloor;
      if (status >= _clientErrorFloor) {
        return Result.failure(UnknownFailure(message: 'Poczta HTTP $status'));
      }
      return Result.success(response);
    } on DioException catch (e) {
      return Result.failure(_failureOf(e));
    }
  }

  bool _isRejected(Response<dynamic> response) {
    final status = response.statusCode;
    return status == _unauthorized || status == _forbidden;
  }

  AppFailure _failureOf(DioException e) {
    final error = e.error;
    return error is AppFailure ? error : UnknownFailure(message: e.message);
  }

  Map<String, String> _baseHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Options _authorizedOptions() {
    final cookie = _cookie;
    return Options(
      validateStatus: (status) => status != null && status < _serverErrorFloor,
      headers: {
        ..._baseHeaders(),
        _cookieChannel.requestHeader: ?cookie,
      },
    );
  }
}
