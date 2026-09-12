import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/wear_app.dart';
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
}

Future<Widget> _buildApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      credentialStorageProvider.overrideWithValue(storage),
      notificationServiceProvider.overrideWithValue(
        _SilentNotificationService(),
      ),
    ],
    child: TranslationProvider(child: const BSharpWearApp()),
  );
}

void main() {
  group('BSharpWearApp theme', () {
    testWidgets('dark wear theme paints surface true black', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.darkTheme!.colorScheme.surface, const Color(0xFF000000));
      expect(
        app.darkTheme!.colorScheme.surfaceContainerLowest,
        const Color(0xFF000000),
      );
      expect(
        app.darkTheme!.colorScheme.surfaceContainerLow,
        const Color(0xFF000000),
      );
      expect(
        app.darkTheme!.colorScheme.surfaceContainer,
        const Color(0xFF000000),
      );
      expect(
        app.darkTheme!.colorScheme.surfaceContainerHigh,
        const Color(0xFF000000),
      );
      expect(
        app.darkTheme!.colorScheme.surfaceContainerHighest,
        const Color(0xFF000000),
      );
    });

    testWidgets('light wear theme surface is a clean near-white', (
      tester,
    ) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        app.theme!.colorScheme.surface.computeLuminance(),
        greaterThan(0.8),
      );
    });

    testWidgets('ThemeMode.system is passed through, not rewritten', (
      tester,
    ) async {
      final widget = await _buildApp();
      await tester.pumpWidget(widget);
      await tester.pump();

      final element = tester.element(find.byType(BSharpWearApp));
      final container = ProviderScope.containerOf(element);
      final providerValue = container.read(themeModeProvider);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(providerValue, ThemeMode.system);
      expect(app.themeMode, ThemeMode.system);
    });
  });
}
