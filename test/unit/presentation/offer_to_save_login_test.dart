import 'package:bsharp/app/saved_passwords_provider.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/saved_login.dart';
import 'package:bsharp/domain/saved_passwords.dart';
import 'package:bsharp/presentation/auth/reauthenticate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingSavedPasswords implements SavedPasswords {
  _RecordingSavedPasswords({this.fails = false});

  final bool fails;
  final offered = <SavedLogin>[];

  @override
  Future<void> offerToSave(SavedLogin login) async {
    if (fails) {
      throw const SavedPasswordsException('save failed');
    }
    offered.add(login);
  }

  @override
  Future<SavedLoginPick> pick() async => const NoSavedLogin();
}

const _account = ProviderAccount(
  id: 'a',
  providerType: 'mobireg',
  slug: 'osm-wroclaw',
  login: 'parent',
  password: 'secret',
);

Future<void> _offer(WidgetTester tester, SavedPasswords passwords) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [savedPasswordsProvider.overrideWithValue(passwords)],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => offerToSaveLogin(ref, _account),
            child: const Text('save'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a verified login is offered to the password manager', (
    tester,
  ) async {
    final passwords = _RecordingSavedPasswords();

    await _offer(tester, passwords);

    expect(passwords.offered, const [
      SavedLogin(school: 'osm-wroclaw', login: 'parent', password: 'secret'),
    ]);
  });

  testWidgets('a failed offer is logged and the sign-in goes on', (
    tester,
  ) async {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');

    await _offer(tester, _RecordingSavedPasswords(fails: true));
    debugPrint = original;

    expect(logs.single, contains('save failed'));
    expect(logs.single, isNot(contains('secret')));
  });
}
