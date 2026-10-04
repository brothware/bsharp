import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:bsharp/core/network/interceptors/mobile_auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClientFactory {
  ApiClientFactory({
    required this._school,
    required this._parentLogin,
    required this._parentPassHash,
  });

  final String _school;
  final String _parentLogin;
  final String _parentPassHash;

  static const String _proxy = AppConstants.proxyBaseUrl;
  static const Map<String, dynamic> _webExtra = kIsWeb
      ? {'withCredentials': true}
      : <String, dynamic>{};

  Dio createMobileSyncClient() => _createNjsonClient(
    userAgent: AppConstants.userAgent,
    acceptEncoding: AppConstants.syncAcceptEncoding,
    contentType: AppConstants.syncContentType,
  );

  Dio createTokenUploadClient() => _createNjsonClient(
    userAgent: AppConstants.tokenUploadUserAgent,
    acceptEncoding: AppConstants.tokenUploadAcceptEncoding,
    contentType: AppConstants.tokenUploadContentType,
  );

  Dio createAppApiClient() {
    final baseUrl = AppConstants.hasMobiregBaseUrlOverride
        ? '${AppConstants.mobiregBaseUrl}/$_school/modules/api'
        : kIsWeb
        ? '$_proxy/sync/$_school'
        : 'https://mobireg.pl/$_school/modules/api';
    const unauthorized = 401;
    const timeout = Duration(milliseconds: AppConstants.appApiTimeoutMs);
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        validateStatus: (status) =>
            status != null &&
            ((status >= 200 && status < 300) || status == unauthorized),
        extra: _webExtra,
      ),
    )..interceptors.add(ErrorMappingInterceptor());
  }

  Dio _createNjsonClient({
    required String userAgent,
    required String acceptEncoding,
    required String contentType,
  }) {
    final baseUrl = AppConstants.hasMobiregBaseUrlOverride
        ? '${AppConstants.mobiregBaseUrl}/$_school/modules/api'
        : kIsWeb
        ? '$_proxy/sync/$_school'
        : 'https://mobireg.pl/$_school/modules/api';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeoutMs,
        ),
        contentType: contentType,
        headers: kIsWeb
            ? null
            : {
                'User-Agent': userAgent,
                'Accept-Encoding': acceptEncoding,
              },
        extra: _webExtra,
      ),
    );

    dio.interceptors.addAll([
      MobileAuthInterceptor(
        parentLogin: _parentLogin,
        parentPassHash: _parentPassHash,
      ),
      ErrorMappingInterceptor(),
    ]);

    return dio;
  }

  Dio createPortalClient() {
    final baseUrl = AppConstants.hasMobiregBaseUrlOverride
        ? AppConstants.mobiregBaseUrl
        : kIsWeb
        ? '$_proxy/portal'
        : 'https://rodzic.mobireg.pl';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeoutMs,
        ),
        extra: _webExtra,
      ),
    );
    dio.interceptors.add(ErrorMappingInterceptor());
    return dio;
  }

  Dio createPocztaClient(String messagingUrl) {
    const ssoSuffix = '/sso';
    final officialBaseUrl = messagingUrl.endsWith(ssoSuffix)
        ? messagingUrl.substring(0, messagingUrl.length - ssoSuffix.length)
        : messagingUrl;
    final baseUrl = AppConstants.hasMobiregBaseUrlOverride
        ? AppConstants.mobiregBaseUrl
        : kIsWeb
        ? '$_proxy/poczta'
        : officialBaseUrl;

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeoutMs,
        ),
        headers: kIsWeb ? null : {'User-Agent': AppConstants.appUserAgent},
        extra: _webExtra,
      ),
    );
  }

  Dio createWebLoginClient() {
    final baseUrl = AppConstants.hasMobiregBaseUrlOverride
        ? '${AppConstants.mobiregBaseUrl}/$_school'
        : kIsWeb
        ? '$_proxy/login/$_school'
        : 'https://mobireg.pl/$_school';

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeoutMs,
        ),
        followRedirects: false,
        validateStatus: (status) =>
            status != null && (status < 400 || status == 302),
        extra: _webExtra,
      ),
    );
  }
}
