import 'dart:async';

import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/screens/wear_launch_screen.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

class _PendingAuthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  final _never = Completer<AuthState>();

  @override
  Future<AuthState> build() => _never.future;

  @override
  Future<void> completeSetup() async {}

  @override
  Future<void> logout() async {}
}

class _FailingAuthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  static int builds = 0;

  @override
  Future<AuthState> build() async {
    builds++;
    throw StateError('account storage unreadable');
  }

  @override
  Future<void> completeSetup() async {}

  @override
  Future<void> logout() async {}
}

class _SilentNotificationService extends NotificationService {
  @override
  Future<void> initialize({void Function(NotificationPayload)? onTap}) async {}

  @override
  Future<NotificationPayload?> getLaunchPayload() async => null;

  @override
  Future<bool> requestPermission() async => true;
}

Future<Widget> _buildApp(AuthNotifier Function() auth) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authStateProvider.overrideWith(auth),
      credentialStorageProvider.overrideWithValue(
        CredentialStorage(store: FakeKeyValueStore()),
      ),
      notificationServiceProvider.overrideWithValue(
        _SilentNotificationService(),
      ),
      wearScreenShapeProvider.overrideWith((_) => WearScreenShape.round),
    ],
    child: TranslationProvider(child: const BSharpWearApp()),
  );
}

void main() {
  testWidgets('carries the launch icon on while the account loads', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildApp(_PendingAuthNotifier.new));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(WearLaunchScreen), findsOneWidget);

    final logo = tester.widget<Image>(
      find.descendant(
        of: find.byType(WearLaunchScreen),
        matching: find.byType(Image),
      ),
    );
    expect(
      logo.width! * WearLaunchScreen.artworkFraction,
      moreOrLessEquals(WearLaunchScreen.iconSizeDp),
      reason:
          'the native splash shows the artwork at 48dp, and the Flutter '
          'screen after it has to show the same icon at the same size',
    );
  });

  testWidgets('shows a failed account load and lets it be retried', (
    tester,
  ) async {
    _FailingAuthNotifier.builds = 0;
    await tester.pumpWidget(await _buildApp(_FailingAuthNotifier.new));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(t.errors.unknownError), findsOneWidget);

    await tester.tap(find.text(t.common.retry));
    await tester.pump();

    expect(_FailingAuthNotifier.builds, 2);
  });
}
