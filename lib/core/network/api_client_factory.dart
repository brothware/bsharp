import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:bsharp/core/network/interceptors/mobile_auth_interceptor.dart';
import 'package:bsharp/core/network/interceptors/web_cookie_interceptor.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

class ApiClientFactory {
  ApiClientFactory({
    required String school,
    required String parentLogin,
    required String parentPassHash,
  })  : _school = school,
        _parentLogin = parentLogin,
        _parentPassHash = parentPassHash;

  final String _school;
  final String _parentLogin;
  final String _parentPassHash;

  static const _proxy = AppConstants.proxyBaseUrl;
  static const _webExtra = kIsWeb ? {'withCredentials': true} : <String, dynamic>{};

  Dio createMobileSyncClient() {
    final baseUrl = kIsWeb
        ? '$_proxy/sync/$_school'
        : 'https://mobireg.pl/$_school/modules/api';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: kIsWeb ? null : {'User-Agent': AppConstants.userAgent},
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
    const baseUrl =
        kIsWeb ? '$_proxy/portal' : 'https://rodzic.mobireg.pl';

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        extra: _webExtra,
      ),
    );
  }

  Dio createPocztaClient() {
    const baseUrl =
        kIsWeb ? '$_proxy/poczta' : 'https://poczta.mobireg.pl';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
        },
        extra: _webExtra,
      ),
    );
    dio.interceptors.add(
      kIsWeb ? WebCookieInterceptor() : CookieManager(CookieJar()),
    );
    return dio;
  }

  Dio createWebLoginClient() {
    final baseUrl =
        kIsWeb ? '$_proxy/login/$_school' : 'https://mobireg.pl/$_school';

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        followRedirects: false,
        validateStatus: (status) =>
            status != null && (status < 400 || status == 302),
        extra: _webExtra,
      ),
    );
  }
}
