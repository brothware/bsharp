import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/entities/sync_action.dart';
import 'package:bsharp/wear/screens/wear_setup_screen.dart';
import 'package:bsharp/wear/screens/wear_student_picker.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

class _TwoStudentsDataProvider extends DemoDataProvider {
  @override
  Future<Result<List<Student>>> fetchStudents({
    required String school,
    required String login,
    required String passwordHash,
  }) async => const Result.success([
    Student(
      id: 1,
      usersEduId: 1,
      name: 'Jan',
      surname: 'Kowalski',
      sex: Sex.male,
    ),
    Student(
      id: 2,
      usersEduId: 2,
      name: 'Anna',
      surname: 'Kowalska',
      sex: Sex.female,
    ),
  ]);
}

AccountStorage _newAccountStorage() =>
    AccountStorage(store: FakeKeyValueStore());

Widget _buildSetupApp(AccountStorage accountStorage) {
  final credentialStorage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(credentialStorage),
      accountStorageProvider.overrideWithValue(accountStorage),
      wearScreenShapeProvider.overrideWith(
        (_) => WearScreenShape.rectangular,
      ),
      activeDataProviderProvider.overrideWithBuild(
        (ref, _) => _TwoStudentsDataProvider(),
      ),
    ],
    child: const MaterialApp(home: WearSetupScreen()),
  );
}

Widget _buildPickerApp(AccountStorage accountStorage) {
  return ProviderScope(
    overrides: [
      accountStorageProvider.overrideWithValue(accountStorage),
      wearScreenShapeProvider.overrideWith(
        (_) => WearScreenShape.rectangular,
      ),
    ],
    child: const MaterialApp(home: WearStudentPicker()),
  );
}

/// The school and login steps hand typing to the watch's own input screen.
Future<void> _typeIntoStep(WidgetTester tester, String text) async {
  final field = tester.widget<TextField>(find.byType(TextField));
  if (!field.readOnly) {
    await tester.enterText(find.byType(TextField), text);
    return;
  }

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('pl.brothware.bsharp/wear'),
    (call) async => call.method == 'requestTextInput' ? text : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('pl.brothware.bsharp/wear'),
      null,
    ),
  );

  await tester.tap(find.byType(TextField));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('setup with two students persists both', (tester) async {
    final accountStorage = _newAccountStorage();
    await tester.pumpWidget(_buildSetupApp(accountStorage));
    await tester.pump();

    await _typeIntoStep(tester, 'osm-wroclaw');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    await _typeIntoStep(tester, 'login');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    await _typeIntoStep(tester, 'pass');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();

    expect(find.text('Jan Kowalski'), findsOneWidget);
    expect(find.text('Anna Kowalska'), findsOneWidget);

    await tester.tap(find.text('Anna Kowalska'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();

    final accounts = await accountStorage.getAccounts();
    expect(accounts, hasLength(1));
    expect(accounts.first.students, hasLength(2));

    final selection = await accountStorage.getActiveSelection();
    expect(selection?.studentId, 2);
  });

  testWidgets('the picker lists both students', (tester) async {
    final accountStorage = _newAccountStorage();
    await accountStorage.saveAccounts([
      const ProviderAccount(
        id: 'a1',
        providerType: 'mobireg',
        slug: 'osm-wroclaw',
        login: 'login',
        students: [
          AccountStudent(id: 1, name: 'Jan', surname: 'Kowalski'),
          AccountStudent(id: 2, name: 'Anna', surname: 'Kowalska'),
        ],
      ),
    ]);
    await accountStorage.saveActiveSelection(
      const ActiveSelection(accountId: 'a1', studentId: 1),
    );

    await tester.pumpWidget(_buildPickerApp(accountStorage));
    await tester.pump();

    expect(find.text('Jan Kowalski'), findsOneWidget);
    expect(find.text('Anna Kowalska'), findsOneWidget);
  });

  testWidgets('selecting a student updates the active selection', (
    tester,
  ) async {
    final accountStorage = _newAccountStorage();
    await accountStorage.saveAccounts([
      const ProviderAccount(
        id: 'a1',
        providerType: 'mobireg',
        slug: 'osm-wroclaw',
        login: 'login',
        students: [
          AccountStudent(id: 1, name: 'Jan', surname: 'Kowalski'),
          AccountStudent(id: 2, name: 'Anna', surname: 'Kowalska'),
        ],
      ),
    ]);
    await accountStorage.saveActiveSelection(
      const ActiveSelection(accountId: 'a1', studentId: 1),
    );

    await tester.pumpWidget(_buildPickerApp(accountStorage));
    await tester.pump();

    await tester.tap(find.text('Anna Kowalska'));
    await tester.pump();
    await tester.pump();

    final selection = await accountStorage.getActiveSelection();
    expect(selection?.studentId, 2);
  });
}
