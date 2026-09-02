abstract final class AppConstants {
  static const protocolVersion = '1.6.0';
  static const fixedLogin = 'eparent';
  static const fixedPassword = 'eparent';
  static const deviceId = '1';
  static const userAgent = 'Andreg $deviceId';
  static const appVersionCode = 95;
  static const syncAcceptEncoding = 'gzip,deflate';
  static const syncContentType =
      'application/x-www-form-urlencoded; charset=UTF-8';
  static const tokenUploadUserAgent = 'okhttp/4.9.3';
  static const tokenUploadAcceptEncoding = 'gzip';
  static const tokenUploadContentType = 'application/x-www-form-urlencoded';
  static const syncWindowDays = 100;
  static const connectTimeoutMs = 10000;
  static const receiveTimeoutMs = 30000;
  static const portalTokenTtlMs = 30000;
  static const portalTokenRefreshMs = 20000;
  static const maxRetryCount = 1;
  static const proxyBaseUrl = 'https://bsharp-proxy.dawid-sliwa.workers.dev';

  static const mobiregBaseUrl = String.fromEnvironment('MOBIREG_BASE_URL');
  static bool get hasMobiregBaseUrlOverride => mobiregBaseUrl.isNotEmpty;

  static const _syncIntervalSecsRaw = String.fromEnvironment(
    'SYNC_INTERVAL_SECS',
  );
  static int? get syncIntervalSecsOverride {
    if (_syncIntervalSecsRaw.isEmpty) return null;
    return int.tryParse(_syncIntervalSecsRaw);
  }
}
