import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/presentation/auth/widgets/add_account_form.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:flutter/material.dart';
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

  Widget wrap() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        accountStorageProvider.overrideWithValue(
          AccountStorage(store: FakeKeyValueStore()),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: AddAccountForm())),
    );
  }

  testWidgets('the picker lists the backends you can hold an account with', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Mobireg'), findsOneWidget);
    expect(
      find.text('Demo'),
      findsNothing,
      reason:
          'demo is reached from the screen before this one, and listing '
          'it here as well offered it twice',
    );
  });

  testWidgets('a provider that needs credentials asks for them', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Mobireg'));
    await tester.pump();

    expect(find.byType(TextField), findsWidgets);
  });
}
