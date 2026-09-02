@TestOn('vm')
@Tags(['integration'])
library;

import 'dart:convert';

import 'package:bsharp/core/network/api_client_factory.dart';
import 'package:bsharp/data/data_sources/remote/mobile_sync_data_source.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const school = 'osm-wroclaw';
  const login = 'dsliwa';
  final passwordHash = md5.convert(utf8.encode('bVPtF@Z365mUZen')).toString();

  group('FCM token registration via njson.php', () {
    test('registerFcmToken succeeds with fake token', () async {
      final factory = ApiClientFactory(
        school: school,
        parentLogin: login,
        parentPassHash: passwordHash,
      );
      final ds = MobileSyncDataSource(client: factory.createMobileSyncClient());

      final result = await ds.registerFcmToken(
        token: 'test-fcm-token-dart-${DateTime.now().millisecondsSinceEpoch}',
      );

      result.when(
        success: (data) {
          expect(data, contains('ParentStudents'));
          final students = data['ParentStudents'] as List<dynamic>;
          expect(students, isNotEmpty);
        },
        failure: (error) => fail('Token registration failed: $error'),
      );
    });

    test('response includes student data alongside token upload', () async {
      final factory = ApiClientFactory(
        school: school,
        parentLogin: login,
        parentPassHash: passwordHash,
      );
      final ds = MobileSyncDataSource(client: factory.createMobileSyncClient());

      final result = await ds.registerFcmToken(
        token: 'bsharp-fcm-integration-test',
      );

      final data = result.when(
        success: (d) => d,
        failure: (e) => fail('Failed: $e'),
      );

      final students = data['ParentStudents'] as List<dynamic>;
      final first = students.first as Map<String, dynamic>;
      expect(first['id'], 6541);
      expect(first['name'], 'Maria');
    });
  });
}
