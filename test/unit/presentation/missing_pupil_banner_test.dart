import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

const _account = ProviderAccount(
  id: 'a1',
  providerType: 'mobireg',
  slug: 'sp1',
  login: 'p',
  password: 's',
  students: [AccountStudent(id: 6339, name: 'Maria', surname: 'Kowalska')],
);

class _QuietDemoProvider extends DemoDataProvider {
  @override
  bool get requiresCredentials => true;
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = AccountStorage(store: FakeKeyValueStore());
  await storage.saveAccounts([_account]);
  await storage.saveActiveSelection(
    const ActiveSelection(accountId: 'a1', studentId: 6541),
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      accountStorageProvider.overrideWithValue(storage),
      activeDataProviderProvider.overrideWithBuild(
        (ref, _) => _QuietDemoProvider(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(providerAccountsProvider.future);
  await container.read(activeSelectionProvider.future);
  return container;
}

Widget _dashboard(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
  );
}

void main() {
  testWidgets('a pupil gone from the account is shown after a sync', (
    tester,
  ) async {
    final container = await tester.runAsync(_container);
    container!.read(lastSyncTimeProvider.notifier).value = DateTime(2026, 10);
    container.read(missingPupilProvider.notifier).value = true;

    await tester.pumpWidget(_dashboard(container));
    await tester.pump();

    expect(
      find.text(
        'This student is no longer on the account. Choose the student again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('choosing a student again selects them', (tester) async {
    final container = await tester.runAsync(_container);
    container!.read(missingPupilProvider.notifier).value = true;

    await tester.pumpWidget(_dashboard(container));
    await tester.pump();
    await tester.tap(find.text('Switch student'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maria Kowalska'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(minutes: 1));

    expect(container.read(activeSelectionProvider).value!.studentId, 6339);
    expect(container.read(missingPupilProvider), isFalse);
  });
}
