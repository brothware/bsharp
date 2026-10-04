import 'dart:convert';

import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

@immutable
class ViewPayload {
  const ViewPayload({
    required this.data,
    required this.serverTime,
    required this.freshFor,
  });

  final Object data;
  final DateTime serverTime;
  final Duration freshFor;
}

class AppApiDataSource {
  AppApiDataSource({required this._client, bool isWeb = kIsWeb})
    : _appHeaders = isWeb
          ? const {}
          : const {'User-Agent': AppConstants.appUserAgent};

  final Dio _client;
  final Map<String, String> _appHeaders;

  Future<Result<String>> login({
    required String login,
    required String password,
  }) async {
    final response = await _send(
      endpoint: 'auth.php',
      request: () => _client.post<String>(
        '/auth.php',
        data: {'login': login, 'password': password},
        options: Options(
          contentType: 'application/json; charset=UTF-8',
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      ),
    );
    return switch (response) {
      Failure(:final failure) => Result.failure(failure),
      Success(:final value) => _tokenFrom(value),
    };
  }

  Future<Result<ViewPayload>> getView({
    required String jwt,
    required String view,
    Map<String, String> params = const {},
  }) async {
    final response = await _send(
      endpoint: 'View $view',
      request: () => _client.post<String>(
        '/app.php',
        data: {
          'view': view,
          'format': 'json',
          'token': jwt,
          'JWTToken': jwt,
          ...params,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
          headers: _appHeaders,
        ),
      ),
    );
    return switch (response) {
      Failure(:final failure) => Result.failure(failure),
      Success(:final value) => _unwrap(view, value),
    };
  }

  Future<Result<Map<String, dynamic>>> _send({
    required String endpoint,
    required Future<Response<String>> Function() request,
  }) async {
    const unauthorized = 401;
    try {
      final response = await request();
      final raw = response.data;
      if (response.statusCode == unauthorized) {
        return Result.failure(
          SessionExpired(message: _decodeObject(raw)?['message'] as String?),
        );
      }
      if (raw == null || raw.isEmpty) {
        return const Result.failure(NoData(message: 'Empty response'));
      }
      final body = _decodeObject(raw);
      if (body == null) {
        throw FormatException('$endpoint answered non-JSON', raw.length);
      }
      return Result.success(body);
    } on DioException catch (e) {
      final failure = e.error;
      if (failure is AppFailure) {
        return Result.failure(failure);
      }
      return Result.failure(UnknownFailure(message: e.message));
    }
  }

  Map<String, dynamic>? _decodeObject(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Result<String> _tokenFrom(Map<String, dynamic> body) {
    final token = body['token'];
    if (body['status'] != 'OK' || token is! String || token.isEmpty) {
      return Result.failure(
        InvalidCredentials(message: body['message'] as String?),
      );
    }
    return Result.success(token);
  }

  Result<ViewPayload> _unwrap(String view, Map<String, dynamic> body) {
    final version = body['v'];
    final Object? data = body['data'];
    final serverTime = body['serverTime'];
    final ttlFresh = body['ttlFresh'];
    if (version is! int ||
        data == null ||
        serverTime is! String ||
        ttlFresh is! int) {
      throw FormatException(
        'View $view answered without an envelope',
        body.keys.toList(),
      );
    }
    if (version != AppConstants.appApiProtocolVersion) {
      return Result.failure(
        ProtocolMismatch(message: 'View $view answered protocol v$version'),
      );
    }
    if (data is Map<String, dynamic> && data['errno'] is int) {
      return Result.failure(
        AppFailure.fromErrno(data['errno'] as int, data['message'] as String?),
      );
    }
    return Result.success(
      ViewPayload(
        data: data,
        serverTime: DateTime.parse(serverTime),
        freshFor: Duration(seconds: ttlFresh),
      ),
    );
  }
}
