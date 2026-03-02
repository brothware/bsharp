import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/wear/screens/wear_setup_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';

import '../data/credential_storage_test.dart';

Widget _buildApp({List<Override> overrides = const []}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.rectangular),
      ...overrides,
    ],
    child: const MaterialApp(home: WearSetupScreen()),
  );
}

void main() {
  group('WearSetupScreen', () {
    testWidgets('renders credential fields when unauthenticated',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows error when fields are empty and login tapped',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Fill in all fields'), findsOneWidget);
    });

    testWidgets('shows error when only some fields filled', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'school1');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Fill in all fields'), findsOneWidget);
    });

    testWidgets('unauthenticated state shows credential fields',
        (tester) async {
      final fakeSecure = FakeKeyValueStore();
      final storage = CredentialStorage(store: fakeSecure);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            wearScreenShapeProvider
                .overrideWith((_) => WearScreenShape.rectangular),
            authStateProvider.overrideWith(
              () => _FakeAuthNotifier(AuthState.unauthenticated),
            ),
          ],
          child: const MaterialApp(home: WearSetupScreen()),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initial);

  final AuthState _initial;

  @override
  Future<AuthState> build() async => _initial;
}
