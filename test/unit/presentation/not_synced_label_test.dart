import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/app/sync_health_provider.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/presentation/grades/screens/grades_screen.dart';
import 'package:bsharp/presentation/messages/screens/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StaleHealth extends SyncHealthNotifier {
  _StaleHealth(this.initial);

  final SyncHealth initial;

  @override
  SyncHealth build() => initial;
}

class _ExplodingMailProvider extends DemoDataProvider {
  @override
  Future<bool> loadMessages(Ref ref, {DateTime? now}) async =>
      throw StateError('mail exploded');
}

class _CountingMailProvider extends DemoDataProvider {
  int loads = 0;
  int refreshes = 0;

  @override
  Future<bool> loadMessages(Ref ref, {DateTime? now}) async {
    loads++;
    return true;
  }

  @override
  Future<void> refreshMessages(Ref ref) async => refreshes++;
}

SyncHealth _staleIn(DataProviderCapability area, {DateTime? lastSyncedAt}) {
  return SyncHealth(
    staleAreas: {area},
    lastSyncedAt: {area: ?lastSyncedAt},
  );
}

late SharedPreferences _prefs;

Widget _app(
  Widget home, {
  SyncHealth health = const SyncHealth(),
  SchoolDataProvider? provider,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      inboxProvider.overrideWithBuild((ref, _) => const []),
      sentProvider.overrideWithBuild((ref, _) => const []),
      trashProvider.overrideWithBuild((ref, _) => const []),
      syncHealthProvider.overrideWith(() => _StaleHealth(health)),
      activeDataProviderProvider.overrideWithBuild(
        (ref, _) => provider ?? DemoDataProvider(),
      ),
    ],
    child: MaterialApp(home: home),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('SyncHealth', () {
    test('marking an area synced clears it and records the time', () {
      final at = DateTime(2026, 10, 5, 8);
      final health = const SyncHealth()
          .markStale({DataProviderCapability.messages})
          .markSynced({DataProviderCapability.messages}, at);

      expect(health.isStale(DataProviderCapability.messages), isFalse);
      expect(health.lastSyncedAt[DataProviderCapability.messages], at);
    });

    test('marking an area stale keeps its last good time', () {
      final at = DateTime(2026, 10, 5, 8);
      final health = const SyncHealth()
          .markSynced({DataProviderCapability.grades}, at)
          .markStale({DataProviderCapability.grades});

      expect(health.isStale(DataProviderCapability.grades), isTrue);
      expect(health.lastSyncedAt[DataProviderCapability.grades], at);
    });
  });

  testWidgets('the messages page shows no label when mail is fresh', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Scaffold(body: MessagesScreen())));

    expect(find.text('Not synced'), findsNothing);
  });

  testWidgets('the messages page shows the label when mail is stale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(body: MessagesScreen()),
        health: _staleIn(DataProviderCapability.messages),
      ),
    );

    expect(find.text('Not synced'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('the label says when the area was last updated', (tester) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(body: MessagesScreen()),
        health: _staleIn(
          DataProviderCapability.messages,
          lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ),
    );

    expect(find.textContaining('Not synced, last updated'), findsOneWidget);
  });

  testWidgets('retry on a stale mailbox reloads mail', (tester) async {
    final provider = _CountingMailProvider();
    await tester.pumpWidget(
      _app(
        const Scaffold(body: MessagesScreen()),
        health: _staleIn(DataProviderCapability.messages),
        provider: provider,
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(provider.loads, 1);
  });

  testWidgets('a retry that throws is reported instead of escaping', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(body: MessagesScreen()),
        health: _staleIn(DataProviderCapability.messages),
        provider: _ExplodingMailProvider(),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load messages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the grades page shows the label when grades are stale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(body: GradesScreen()),
        health: _staleIn(DataProviderCapability.grades),
      ),
    );

    expect(find.text('Not synced'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('the grades page shows no label when only mail is stale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(body: GradesScreen()),
        health: _staleIn(DataProviderCapability.messages),
      ),
    );

    expect(find.text('Not synced'), findsNothing);
  });
}
