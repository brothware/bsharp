abstract final class AppConstants {
  static const connectTimeoutMs = 10000;
  static const receiveTimeoutMs = 30000;
  static const appUserAgent = 'MobiReg/3.1.3 (296c220)';
  static const appApiProtocolVersion = 1;
  static const appApiTimeoutMs = 15000;
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
