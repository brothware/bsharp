import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/child_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';

import '../data/credential_storage_test.dart';

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
        overrides: [studentsProvider.overrideWith((ref) => [])],
      );
      expect(container.read(activeStudentProvider), isNull);
    });

    test('returns first student when no selection saved', () {
      final fakeStorage = FakeFlutterSecureStorage();
      final storage = CredentialStorage(storage: fakeStorage);

      final container = ProviderContainer(
        overrides: [
          studentsProvider.overrideWith((ref) => [jan, anna]),
          credentialStorageProvider.overrideWithValue(storage),
        ],
      );
      expect(container.read(activeStudentProvider), jan);
    });

    test('returns selected student when id matches', () async {
      final fakeStorage = FakeFlutterSecureStorage();
      final storage = CredentialStorage(storage: fakeStorage);
      await storage.saveSelectedStudentId(2);

      final container = ProviderContainer(
        overrides: [
          studentsProvider.overrideWith((ref) => [jan, anna]),
          credentialStorageProvider.overrideWithValue(storage),
        ],
      );

      await container.read(selectedStudentIdProvider.future);
      expect(container.read(activeStudentProvider), anna);
    });

    test('switchTo persists and changes student', () async {
      final fakeStorage = FakeFlutterSecureStorage();
      final storage = CredentialStorage(storage: fakeStorage);

      final container = ProviderContainer(
        overrides: [
          studentsProvider.overrideWith((ref) => [jan, anna]),
          credentialStorageProvider.overrideWithValue(storage),
        ],
      );

      expect(container.read(activeStudentProvider), jan);

      await container
          .read(activeStudentProvider.notifier)
          .switchTo(anna);

      final savedId = await storage.getSelectedStudentId();
      expect(savedId, 2);
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
