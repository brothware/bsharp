import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/watch_link_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/watch_link.dart';
import 'package:bsharp/presentation/common/theme/app_theme.dart';
import 'package:bsharp/presentation/settings/screens/watch_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

class _FakeWatchLink implements WatchLink {
  _FakeWatchLink({
    this.isConnected = true,
    this.sendError,
    this.isAcknowledged = true,
  });

  final bool isConnected;
  final bool isAcknowledged;
  final Exception? sendError;
  final sent = <AccountHandoff>[];

  @override
  Future<bool> hasPairedWatch() async => true;

  @override
  Future<bool> hasConnectedCounterpart() async => isConnected;

  @override
  Future<bool> sendAccount(AccountHandoff account) async {
    if (sendError case final error?) {
      throw error;
    }
    sent.add(account);
    return isAcknowledged;
  }

  @override
  Stream<AccountHandoff> get receivedAccounts => const Stream.empty();
}

const _school = ProviderAccount(
  id: 'a1',
  providerType: 'mobireg',
  slug: 'osm-wroclaw',
  login: 'parent',
  password: 'secret',
  schoolName: 'OSM Wroclaw',
);

Future<void> _pump(
  WidgetTester tester,
  _FakeWatchLink link, {
  List<ProviderAccount> accounts = const [_school],
}) async {
  final storage = AccountStorage(store: FakeKeyValueStore());
  for (final account in accounts) {
    await tester.runAsync(() => storage.addAccount(account));
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountStorageProvider.overrideWithValue(storage),
        watchLinkProvider.overrideWithValue(link),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const WatchSetupScreen(),
      ),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sending an account hands its credentials to the watch', (
    tester,
  ) async {
    final link = _FakeWatchLink();
    await _pump(tester, link);

    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(link.sent, const [
      AccountHandoff(
        providerType: 'mobireg',
        school: 'osm-wroclaw',
        login: 'parent',
        password: 'secret',
      ),
    ]);
    expect(find.text('Sent. Finish on the watch.'), findsOneWidget);
  });

  testWidgets('with no watch connected nothing is sent', (tester) async {
    final link = _FakeWatchLink(isConnected: false);
    await _pump(tester, link);

    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(link.sent, isEmpty);
    expect(find.textContaining('No watch is connected'), findsOneWidget);
  });

  testWidgets('a watch that does not answer is not reported as signed in', (
    tester,
  ) async {
    await _pump(tester, _FakeWatchLink(isAcknowledged: false));

    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Sent. Finish on the watch.'), findsNothing);
    expect(find.textContaining('The watch did not answer'), findsOneWidget);
  });

  testWidgets('a failed send says so', (tester) async {
    final link = _FakeWatchLink(
      sendError: PlatformException(code: 'unavailable'),
    );
    await _pump(tester, link);

    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Could not send to the watch'), findsOneWidget);
  });

  testWidgets('demo and passwordless accounts are not offered', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeWatchLink(),
      accounts: [
        const ProviderAccount(
          id: 'd',
          providerType: 'demo',
          slug: 'demo',
          login: 'demo',
        ),
        _school.copyWith(id: 'a2', password: '', schoolName: 'Old account'),
      ],
    );

    expect(find.byTooltip('Send'), findsNothing);
    expect(find.text('Add a school account first'), findsOneWidget);
  });
}
