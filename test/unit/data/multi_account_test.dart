import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:flutter_test/flutter_test.dart';

import 'credential_storage_test.dart';

ProviderAccount _account({
  required String id,
  String providerType = 'mobireg',
  String slug = 'osm-wroclaw',
  String login = 'dsliwa',
}) {
  return ProviderAccount(
    id: id,
    providerType: providerType,
    slug: slug,
    login: login,
    schoolName: 'School $id',
    students: const [AccountStudent(id: 1, name: 'A', surname: 'B')],
  );
}

void main() {
  test('a second account does not replace the first', () async {
    final storage = AccountStorage(store: FakeKeyValueStore());

    await storage.addAccount(_account(id: 'a'));
    await storage.addAccount(_account(id: 'b', slug: 'other-school'));

    expect((await storage.getAccounts()).map((a) => a.id), ['a', 'b']);
  });

  test('two accounts may share a provider', () async {
    final storage = AccountStorage(store: FakeKeyValueStore());

    await storage.addAccount(_account(id: 'a', login: 'parent-one'));
    await storage.addAccount(_account(id: 'b', login: 'parent-two'));

    final saved = await storage.getAccounts();
    expect(saved.map((a) => a.providerType), ['mobireg', 'mobireg']);
    expect(saved.map((a) => a.login), ['parent-one', 'parent-two']);
  });
}
