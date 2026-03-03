import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bsharp/app/app.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'unit/data/credential_storage_test.dart';

CredentialStorage _fakeStorage() =>
    CredentialStorage(store: FakeKeyValueStore());

void main() {
  testWidgets('BSharpApp renders MaterialApp', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          credentialStorageProvider.overrideWithValue(_fakeStorage()),
        ],
        child: TranslationProvider(child: const BSharpApp()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('BSharpApp shows Dashboard tab when authenticated', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authStateProvider.overrideWith(() => _FakeAuthNotifier()),
          credentialStorageProvider.overrideWithValue(_fakeStorage()),
        ],
        child: TranslationProvider(child: const BSharpApp()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('BSharpApp shows Login when unauthenticated', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authStateProvider.overrideWith(
            () => _FakeAuthNotifier(AuthState.unauthenticated),
          ),
          credentialStorageProvider.overrideWithValue(_fakeStorage()),
        ],
        child: TranslationProvider(child: const BSharpApp()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BSharp'), findsOneWidget);
  });
}

class _FakeAuthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier([this._initialState = AuthState.authenticated]);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;

  @override
  Future<void> completeSetup() async {
    state = const AsyncData(AuthState.authenticated);
  }

  @override
  Future<void> logout() async {
    state = const AsyncData(AuthState.unauthenticated);
  }
}
