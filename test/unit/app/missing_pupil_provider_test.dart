import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/reauth_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

const _first = ActiveSelection(accountId: 'a1', studentId: 6339);
const _otherStudent = ActiveSelection(accountId: 'a1', studentId: 6541);
const _otherAccount = ActiveSelection(accountId: 'a2', studentId: 6339);

Future<ProviderContainer> _containerSelecting(ActiveSelection selection) async {
  final storage = AccountStorage(store: FakeKeyValueStore());
  await storage.saveActiveSelection(selection);
  final container = ProviderContainer(
    overrides: [accountStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  await container.read(activeSelectionProvider.future);
  container.read(missingPupilProvider.notifier).value = true;
  return container;
}

void main() {
  test('switching to another student clears the missing pupil', () async {
    final container = await _containerSelecting(_first);

    await container
        .read(activeSelectionProvider.notifier)
        .select(_otherStudent);

    expect(container.read(missingPupilProvider), isFalse);
  });

  test('switching to another account clears the missing pupil', () async {
    final container = await _containerSelecting(_first);

    await container
        .read(activeSelectionProvider.notifier)
        .select(_otherAccount);

    expect(container.read(missingPupilProvider), isFalse);
  });

  test('selecting the same student keeps the missing pupil', () async {
    final container = await _containerSelecting(_first);

    await container.read(activeSelectionProvider.notifier).select(_first);

    expect(container.read(missingPupilProvider), isTrue);
  });
}
