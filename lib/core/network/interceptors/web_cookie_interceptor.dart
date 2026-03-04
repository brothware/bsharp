import 'package:dio/dio.dart';

class WebCookieInterceptor extends Interceptor {
  String _cookies = '';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_cookies.isNotEmpty) {
      options.headers['X-Cookie-Jar'] = _cookies;
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final jar = response.headers['x-cookie-jar']?.first;
    if (jar != null && jar.isNotEmpty) {
      _cookies = _mergeCookies(_cookies, jar);
    }
    handler.next(response);
  }

  static String _mergeCookies(String existing, String incoming) {
    final map = <String, String>{};
    for (final pair in existing.split('; ')) {
      final eq = pair.indexOf('=');
      if (eq > 0) map[pair.substring(0, eq)] = pair;
    }
    for (final pair in incoming.split('; ')) {
      final eq = pair.indexOf('=');
      if (eq > 0) map[pair.substring(0, eq)] = pair;
    }
    return map.values.join('; ');
  }
}
