import 'package:bsharp/core/constants/app_constants.dart';
import 'package:dio/dio.dart';

class MobileAuthInterceptor extends Interceptor {
  MobileAuthInterceptor({
    required this.parentLogin,
    required this.parentPassHash,
  });

  final String parentLogin;
  final String parentPassHash;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data is Map<String, dynamic>) {
      options.data = <String, dynamic>{
        'login': AppConstants.fixedLogin,
        'pass': AppConstants.fixedPassword,
        'device_id': AppConstants.deviceId,
        'app_version': AppConstants.appVersionCode.toString(),
        'parent_login': parentLogin,
        'parent_pass': parentPassHash,
        ...options.data as Map<String, dynamic>,
      };
    }
    handler.next(options);
  }
}
