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
    testWidgets('the scaffold behind a screen is black too', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(
        app.theme!.scaffoldBackgroundColor,
        const Color(0xFF000000),
        reason:
            'the theme flattens every surface to black but left the '
            'scaffold on the base colour, so it showed at the foot of any '
            'screen whose content did not reach the bottom',
      );
    });

    testWidgets('wear theme paints every surface true black', (tester) async {
      await tester.pumpWidget(await _buildApp());
      await tester.pump();

      final scheme = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme!
          .colorScheme;
      for (final surface in [
        scheme.surface,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest,
      ]) {
        expect(surface, const Color(0xFF000000));
      }
    });

    for (final mode in ThemeMode.values) {
      testWidgets('a stored $mode still renders black (WO-V13)', (
        tester,
      ) async {
        await tester.pumpWidget(await _buildApp());
        await tester.pump();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(BSharpWearApp)),
        );
        await container.read(themeModeProvider.notifier).setThemeMode(mode);
        await tester.pump();

        final context = tester.element(find.byType(Scaffold).first);
        expect(Theme.of(context).colorScheme.surface, const Color(0xFF000000));
        expect(Theme.of(context).brightness, Brightness.dark);
      });
    }
  });
}
