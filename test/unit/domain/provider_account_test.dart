import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProviderAccount credentials', () {
    test('fresh account stores plaintext and keeps it', () {
      const account = ProviderAccount(
        id: '1',
        providerType: 'mobireg',
        slug: 'sp1',
        login: 'user',
        password: 'PlainPass123',
      );

      expect(account.password, 'PlainPass123');
    });

    test('legacy json migrates passwordHash to an empty password', () {
      final account = ProviderAccount.fromJson({
        'id': '1',
        'providerType': 'mobireg',
        'slug': 'sp1',
        'login': 'user',
        'passwordHash': 'legacyhash',
        'students': <dynamic>[],
      });

      expect(account.password, isEmpty);
      expect(ProviderAccount.migrateLegacyJson({'passwordHash': 'x'}), {
        'password': '',
      });
    });

    test('new json with plaintext password does not migrate', () {
      final account = ProviderAccount.fromJson({
        'id': '1',
        'providerType': 'mobireg',
        'slug': 'sp1',
        'login': 'user',
        'password': 'PlainPass123',
        'students': <dynamic>[],
      });

      expect(account.password, 'PlainPass123');
    });
  });
}
