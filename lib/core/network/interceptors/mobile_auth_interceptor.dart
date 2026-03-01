import 'package:dio/dio.dart';
import 'package:bsharp/core/constants/app_constants.dart';

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
      final data = Map<String, dynamic>.of(options.data as Map<String, dynamic>);
      data['login'] = AppConstants.fixedLogin;
      data['pass'] = AppConstants.fixedPassword;
      data['device_id'] = '12345';
      data['app_version'] = '42';
      data['parent_login'] = parentLogin;
      data['parent_pass'] = parentPassHash;
      options.data = data;
    }
    handler.next(options);
  }
}
