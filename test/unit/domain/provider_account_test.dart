import 'package:bsharp/data/data_sources/remote/auth_service.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:flutter_test/flutter_test.dart';

String njsonPassHashFor(ProviderAccount account) => account.password.isNotEmpty
    ? AuthService.hashPassword(account.password)
    : account.legacyPasswordHash!;

void main() {
  group('ProviderAccount credentials', () {
    test('fresh account stores plaintext and does not need reauth', () {
      const account = ProviderAccount(
        id: '1',
        providerType: 'mobireg',
        slug: 'sp1',
        login: 'user',
        password: 'PlainPass123',
      );

      expect(account.needsReauth, isFalse);
      expect(
        njsonPassHashFor(account),
        AuthService.hashPassword('PlainPass123'),
      );
    });

    test('legacy json migrates passwordHash and needs reauth', () {
      final account = ProviderAccount.fromJson({
        'id': '1',
        'providerType': 'mobireg',
        'slug': 'sp1',
        'login': 'user',
        'passwordHash': 'legacyhash',
        'students': <dynamic>[],
      });

      expect(account.password, isEmpty);
      expect(account.legacyPasswordHash, 'legacyhash');
      expect(account.needsReauth, isTrue);
      expect(njsonPassHashFor(account), 'legacyhash');
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
      expect(account.legacyPasswordHash, isNull);
      expect(account.needsReauth, isFalse);
    });
  });
}
