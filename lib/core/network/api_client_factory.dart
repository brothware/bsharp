import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClientFactory {
  ApiClientFactory({required this._school});

  final String _school;

  static const String _proxy = AppConstants.proxyBaseUrl;
  static const Map<String, dynamic> _webExtra = kIsWeb
      ? {'withCredentials': true}
      : <String, dynamic>{};

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
}
