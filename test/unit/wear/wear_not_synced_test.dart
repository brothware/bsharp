import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/sync_health_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/wear/screens/wear_messages_list_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:bsharp/wear/widgets/wear_fitted_text.dart';
import 'package:bsharp/wear/widgets/wear_status_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

class _FixedHealth extends SyncHealthNotifier {
  _FixedHealth(this.initial);

  final SyncHealth initial;

  @override
  SyncHealth build() => initial;
}

class _FixedStatus extends SyncStatusNotifier {
  _FixedStatus(this.initial);

  final SyncStatus initial;

  @override
  SyncStatus build() => initial;
}

const _staleMail = SyncHealth(staleAreas: {DataProviderCapability.messages});

Widget _app(
  Widget home, {
  SyncHealth health = const SyncHealth(),
  SyncStatus status = SyncStatus.completed,
}) {
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(
        CredentialStorage(store: FakeKeyValueStore()),
      ),
      wearScreenShapeProvider.overrideWith(
        (_) => WearScreenShape.rectangular,
      ),
      inboxProvider.overrideWithBuild((ref, _) => const []),
      syncHealthProvider.overrideWith(() => _FixedHealth(health)),
      syncStatusProvider.overrideWith(() => _FixedStatus(status)),
    ],
    child: MaterialApp(home: Scaffold(body: home)),
  );
}

void main() {
  group('WearStatusLine', () {
    testWidgets('shows nothing when everything is synced', (tester) async {
      await tester.pumpWidget(_app(const WearStatusLine()));

      expect(find.text('Not synced'), findsNothing);
    });

    testWidgets('shows not synced when any area is stale', (tester) async {
      await tester.pumpWidget(_app(const WearStatusLine(), health: _staleMail));

      expect(find.text('Not synced'), findsOneWidget);
    });

    testWidgets('a failed sync still shows the failure', (tester) async {
      await tester.pumpWidget(
        _app(
          const WearStatusLine(),
          health: _staleMail,
          status: SyncStatus.failed,
        ),
      );

      expect(find.text('Sync failed'), findsOneWidget);
      expect(find.text('Not synced'), findsNothing);
    });
  });

  group('WearMessagesListScreen', () {
    testWidgets('shows no label when mail is fresh', (tester) async {
      await tester.pumpWidget(_app(const WearMessagesListScreen()));
      await tester.pump();

      expect(find.text('Not synced'), findsNothing);
    });

    testWidgets('labels the list when mail is stale at the wear floor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const WearMessagesListScreen(), health: _staleMail),
      );
      await tester.pump();

      expect(find.text('Not synced'), findsOneWidget);
      final fitted = tester.widget<WearFittedText>(
        find.widgetWithText(WearFittedText, 'Not synced'),
      );
      expect(fitted.minFontSize, greaterThanOrEqualTo(wearMinFontSizeSp));
    });
  });
}
