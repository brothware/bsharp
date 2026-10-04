@TestOn('vm')
@Tags(['integration'])
library;

import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/app_api_session_registry.dart';
import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

const _mockBaseUrl = 'http://localhost:8090';
const _school = 'osm-wroclaw';
const _mockLogin = 'user';
const _mockPassword = 'pass';

class _MockServerClients extends ApiClientFactory {
  _MockServerClients(this._mockSchool) : super(school: _mockSchool);

  final String _mockSchool;

  @override
  Dio createAppApiClient() =>
      super.createAppApiClient()
        ..options.baseUrl = '$_mockBaseUrl/$_mockSchool/modules/api';
}

void main() {
  group('FCM token registration via app.php', () {
    test('register-fcm accepts a fake token', () async {
      final provider = MobiregDataProvider(
        clientFactory: _MockServerClients.new,
        sessions: AppApiSessionRegistry(),
      );

      final ok = await provider.registerPushToken(
        school: _school,
        login: _mockLogin,
        password: _mockPassword,
        token: 'test-fcm-token-dart-${DateTime.now().millisecondsSinceEpoch}',
      );

      expect(ok, isTrue);
    });
  });
}
