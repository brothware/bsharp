import 'dart:convert';

import 'package:bsharp/core/error/result.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService({required Dio webLoginClient}) : _client = webLoginClient;

  final Dio _client;

  String _portalToken = '';
  DateTime _tokenObtainedAt = DateTime(1970);

  String get portalToken => _portalToken;

  bool get isTokenValid =>
      _portalToken.isNotEmpty &&
      DateTime.now().difference(_tokenObtainedAt).inSeconds < 20;

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return md5.convert(bytes).toString();
  }

  Future<Result<String>> obtainPortalToken({
    required String login,
    required String passwordHash,
  }) async {
    try {
      final response = await _client.post<dynamic>(
        '/index.php?action=login',
        data: {
          'queryString': '',
          'edlogin': login,
          'edpass': passwordHash,
          'resolutions': '1920',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final isRedirect = response.statusCode == 302 ||
          (kIsWeb && response.headers['x-original-status']?.first == '302');
      final location = kIsWeb
          ? response.headers['x-redirect-location']?.first
          : response.headers['location']?.first;

      if (isRedirect && location != null) {
        final token = _extractToken(location);
        if (token != null) {
          _portalToken = token;
          _tokenObtainedAt = DateTime.now();
          return Result.success(token);
        }
      }

      return const Result.failure(
        InvalidCredentials(message: 'Login failed: no redirect'),
      );
    } on DioException catch (e) {
      if (e.error is AppFailure) {
        return Result.failure(e.error! as AppFailure);
      }
      return Result.failure(
        UnknownFailure(message: e.message),
      );
    }
  }

  Future<Result<String>> ensureValidToken({
    required String login,
    required String passwordHash,
  }) async {
    if (isTokenValid) {
      return Result.success(_portalToken);
    }
    return obtainPortalToken(login: login, passwordHash: passwordHash);
  }

  void clearToken() {
    _portalToken = '';
    _tokenObtainedAt = DateTime(1970);
  }

  String? _extractToken(String locationUrl) {
    final uri = Uri.tryParse(locationUrl);
    if (uri == null) return null;

    final segments = uri.pathSegments;
    if (segments.length >= 2) {
      final token = segments.last;
      if (token.length == 32 && RegExp(r'^[a-f0-9]+$').hasMatch(token)) {
        return token;
      }
    }
    return null;
  }
}
