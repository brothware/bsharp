@TestOn('vm')
@Tags(['integration'])
library;

import 'package:bsharp/data/providers/mobireg/mobireg_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const school = 'osm-wroclaw';
  const login = 'parent.login';
  const password = 'REDACTED';

  group('FCM token registration via app.php', () {
    test('register-fcm accepts a fake token', () async {
      final ok = await MobiregDataProvider().registerPushToken(
        school: school,
        login: login,
        password: password,
        token: 'test-fcm-token-dart-${DateTime.now().millisecondsSinceEpoch}',
      );

      expect(ok, isTrue);
    });
  });
}
