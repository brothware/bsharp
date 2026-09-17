import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<ProviderContainer> containerWithAccount(String providerType) async {
    final storage = AccountStorage(store: FakeKeyValueStore());
    await storage.saveAccounts([
      ProviderAccount(
        id: 'a1',
        providerType: providerType,
        slug: 'demo-school-a',
        login: 'demo',
        schoolName: 'Demo School A',
        students: const [
          AccountStudent(id: 1, name: 'Jan', surname: 'Kowalski'),
        ],
      ),
    ]);
    await storage.saveActiveSelection(
      const ActiveSelection(accountId: 'a1', studentId: 1),
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        accountStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    await container.read(activeSelectionProvider.future);
    await container.read(providerAccountsProvider.future);
    return container;
  }

  test('a saved demo account comes back as the demo backend', () async {
    final container = await containerWithAccount('demo');

    restoreProviderForActiveAccount(container.read(Provider((ref) => ref)));

    expect(container.read(activeDataProviderProvider).id, 'demo');
  });

  test('a saved mobireg account keeps the mobireg backend', () async {
    final container = await containerWithAccount('mobireg');
    final before = container.read(activeDataProviderProvider);

    restoreProviderForActiveAccount(container.read(Provider((ref) => ref)));

    expect(container.read(activeDataProviderProvider).id, 'mobireg');
    expect(
      identical(container.read(activeDataProviderProvider), before),
      isTrue,
      reason: 'swapping in an identical backend would throw away its session',
    );
  });
}
