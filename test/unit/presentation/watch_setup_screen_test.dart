import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/watch_link_provider.dart';
import 'package:bsharp/app/watch_open_permission_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/watch_link.dart';
import 'package:bsharp/domain/watch_open_permission.dart';
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
    this.announceError,
  });

  final bool isConnected;
  final bool isAcknowledged;
  final Exception? sendError;
  final Exception? announceError;
  final sent = <AccountHandoff>[];
  int setupOpenAnnouncements = 0;

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
  Future<void> acknowledgeAccount() async {}

  @override
  Stream<AccountHandoff> get receivedAccounts => const Stream.empty();

  @override
  Future<void> announceSetupOpen() async {
    if (announceError case final error?) {
      throw error;
    }
    setupOpenAnnouncements++;
  }

  @override
  Stream<void> get setupOpenings => const Stream.empty();
}

class _FakeOpenPermission implements WatchOpenPermission {
  _FakeOpenPermission({this.watchName, this.nameError, this.openError});

  final String? watchName;
  final Exception? nameError;
  final Exception? openError;
  int appListOpenings = 0;

  @override
  Future<String?> connectedWatchName() async {
    if (nameError case final error?) {
      throw error;
    }
    return watchName;
  }

  @override
  Future<void> openAppList() async {
    if (openError case final error?) {
      throw error;
    }
    appListOpenings++;
  }
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
  _FakeOpenPermission? openPermission,
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
        watchOpenPermissionProvider.overrideWithValue(
          openPermission ?? _FakeOpenPermission(),
        ),
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
  testWidgets('the way to let the watch open BSharp names the watch', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeWatchLink(),
      openPermission: _FakeOpenPermission(watchName: 'Galaxy Watch6 Classic'),
    );

    expect(find.text('Watch did not open BSharp here?'), findsOneWidget);
    expect(
      find.text('Let the app for Galaxy Watch6 Classic open BSharp'),
      findsOneWidget,
    );
  });

  testWidgets('with no watch connected the way is still explained', (
    tester,
  ) async {
    await _pump(tester, _FakeWatchLink());

    expect(find.text("Let your watch's app open BSharp"), findsOneWidget);
  });

  testWidgets('a watch name that cannot be read falls back to the plain way', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeWatchLink(),
      openPermission: _FakeOpenPermission(
        nameError: PlatformException(code: 'watch_unavailable'),
      ),
    );

    expect(find.text("Let your watch's app open BSharp"), findsOneWidget);
  });

  testWidgets('tapping it opens the list of apps', (tester) async {
    final openPermission = _FakeOpenPermission();
    await _pump(tester, _FakeWatchLink(), openPermission: openPermission);

    await tester.tap(find.text("Let your watch's app open BSharp"));
    await tester.pumpAndSettle();

    expect(openPermission.appListOpenings, 1);
  });

  testWidgets('an app list that cannot be opened is named', (tester) async {
    await _pump(
      tester,
      _FakeWatchLink(),
      openPermission: _FakeOpenPermission(
        openError: PlatformException(code: 'no_settings'),
      ),
    );

    await tester.tap(find.text("Let your watch's app open BSharp"));
    await tester.pumpAndSettle();

    expect(find.text('Could not open the app list'), findsOneWidget);
  });

  testWidgets('opening Set up watch tells a waiting watch it opened', (
    tester,
  ) async {
    final link = _FakeWatchLink();
    await _pump(tester, link);

    expect(link.setupOpenAnnouncements, 1);
  });

  testWidgets('a watch that cannot be told still leaves the screen usable', (
    tester,
  ) async {
    final link = _FakeWatchLink(
      announceError: PlatformException(code: 'unreachable'),
    );
    await _pump(tester, link);

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Send'), findsOneWidget);
  });

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
