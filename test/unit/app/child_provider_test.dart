import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/key_value_store.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const jan = Student(
    id: 1,
    usersEduId: 100,
    name: 'Jan',
    surname: 'Kowalski',
    sex: Sex.male,
  );
  const anna = Student(
    id: 2,
    usersEduId: 200,
    name: 'Anna',
    surname: 'Kowalska',
    sex: Sex.female,
  );

  group('ActiveStudentNotifier', () {
    test('returns null when no students', () {
      final container = ProviderContainer(
        overrides: [studentsProvider.overrideWithBuild((ref, _) => [])],
      );
      expect(container.read(activeStudentProvider), isNull);
    });

    test('returns first student when no selection saved', () {
      final fakeStore = FakeKeyValueStore();
      final accountStore = AccountStorage(store: fakeStore);

      final container = ProviderContainer(
        overrides: [
          studentsProvider.overrideWithBuild((ref, _) => [jan, anna]),
          accountStorageProvider.overrideWithValue(accountStore),
        ],
      );
      expect(container.read(activeStudentProvider), jan);
    });

    test('returns selected student when id matches', () async {
      final fakeStore = FakeKeyValueStore();
      final accountStore = AccountStorage(store: fakeStore);
      await accountStore.saveActiveSelection(
        const ActiveSelection(accountId: 'acc1', studentId: 2),
      );

      final container = ProviderContainer(
        overrides: [
          studentsProvider.overrideWithBuild((ref, _) => [jan, anna]),
          accountStorageProvider.overrideWithValue(accountStore),
        ],
      );

      await container.read(selectedStudentIdProvider.future);
      expect(container.read(activeStudentProvider), anna);
    });
  });

  group('placeholderStudent', () {
    test('has zero id and empty name', () {
      final s = placeholderStudent();
      expect(s.id, 0);
      expect(s.name, isEmpty);
    });
  });
}

class FakeKeyValueStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read({required String key}) async => data[key];

  @override
  Future<void> write({required String key, required String value}) async {
    data[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    data.clear();
  }
}
