import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

class _SilentNotificationService extends NotificationService {
  @override
  Future<void> initialize({void Function(NotificationPayload)? onTap}) async {}

  @override
  Future<NotificationPayload?> getLaunchPayload() async => null;

  @override
  Future<bool> requestPermission() async => true;
}

class _FailingThenWorkingAuth extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  static int builds = 0;

  @override
  Future<AuthState> build() async {
    builds++;
    if (builds == 1) {
      throw StateError('account storage unreadable');
    }
    return AuthState.unauthenticated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('a failed start says so and can be retried', (tester) async {
    _FailingThenWorkingAuth.builds = 0;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          credentialStorageProvider.overrideWithValue(
            CredentialStorage(store: FakeKeyValueStore()),
          ),
          notificationServiceProvider.overrideWithValue(
            _SilentNotificationService(),
          ),
          authStateProvider.overrideWith(_FailingThenWorkingAuth.new),
          wearScreenShapeProvider.overrideWith(
            (_) => WearScreenShape.rectangular,
          ),
        ],
        child: TranslationProvider(child: const BSharpWearApp()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('An unknown error occurred'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(_FailingThenWorkingAuth.builds, 2);
  });
}
