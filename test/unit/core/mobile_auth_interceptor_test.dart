import 'package:bsharp/core/constants/app_constants.dart';
import 'package:bsharp/core/network/interceptors/mobile_auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> runInterceptor(
  MobileAuthInterceptor interceptor,
  Map<String, dynamic> data,
) {
  final options = RequestOptions(path: '/njson.php', data: data);
  interceptor.onRequest(options, RequestInterceptorHandler());
  return options.data as Map<String, dynamic>;
}

void main() {
  group('MobileAuthInterceptor', () {
    test('injects the fixed and parent credentials', () {
      final interceptor = MobileAuthInterceptor(
        parentLogin: 'dsliwa',
        parentPassHash: 'deadbeef',
      );

      final data = runInterceptor(interceptor, {'view': 'Marks'});

      expect(data['login'], AppConstants.fixedLogin);
      expect(data['pass'], AppConstants.fixedPassword);
      expect(data['parent_login'], 'dsliwa');
      expect(data['parent_pass'], 'deadbeef');
    });

    test('reports the device id and app version the portal expects', () {
      final interceptor = MobileAuthInterceptor(
        parentLogin: 'dsliwa',
        parentPassHash: 'deadbeef',
      );

      final data = runInterceptor(interceptor, {'view': 'Marks'});

      expect(data['device_id'], AppConstants.deviceId);
      expect(data['app_version'], AppConstants.appVersionCode.toString());
    });

    test('leaves a non-map body untouched', () {
      final interceptor = MobileAuthInterceptor(
        parentLogin: 'dsliwa',
        parentPassHash: 'deadbeef',
      );
      final options = RequestOptions(path: '/njson.php', data: 'raw');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.data, 'raw');
    });
  });
}
