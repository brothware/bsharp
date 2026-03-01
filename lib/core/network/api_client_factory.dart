import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/network/interceptors/error_mapping_interceptor.dart';
import 'package:bsharp/core/network/interceptors/mobile_auth_interceptor.dart';

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

  Dio createMobileSyncClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://mobireg.pl/$_school/modules/api',
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {'User-Agent': AppConstants.userAgent},
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
    return Dio(
      BaseOptions(
        baseUrl: 'https://rodzic.mobireg.pl',
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      ),
    );
  }

  Dio createPocztaClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://poczta.mobireg.pl',
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
    dio.interceptors.add(CookieManager(CookieJar()));
    return dio;
  }

  Dio createWebLoginClient() {
    return Dio(
      BaseOptions(
        baseUrl: 'https://mobireg.pl/$_school',
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        followRedirects: false,
        validateStatus: (status) =>
            status != null && (status < 400 || status == 302),
      ),
    );
  }
}
