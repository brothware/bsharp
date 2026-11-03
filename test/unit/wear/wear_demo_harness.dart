import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/app/translation_provider.dart';
import 'package:bsharp/app/watch_link_provider.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/services/notification_service.dart';
import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/watch_link.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/common/theme/theme_provider.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Future<void> showUnexcusedAbsenceAlert(int count) async {}
}

class _NoPhone implements WatchLink {
  @override
  Future<void> acknowledgeAccount() async {}

  @override
  Future<bool> hasPairedWatch() async => true;

  @override
  Future<bool> hasConnectedCounterpart() async => false;

  @override
  Future<bool> sendAccount(AccountHandoff account) async => true;

  @override
  Stream<AccountHandoff> get receivedAccounts => const Stream.empty();
}

Future<void> pumpWearApp(WidgetTester tester, Size watchSizeDp) async {
  tester.binding.defaultBinaryMessenger.setMockStreamHandler(
    const EventChannel('wear_os_scrollbar/rotary'),
    MockStreamHandler.inline(onListen: (_, _) {}),
  );
  tester.view.physicalSize = watchSizeDp * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        credentialStorageProvider.overrideWithValue(
          CredentialStorage(store: FakeKeyValueStore()),
        ),
        accountStorageProvider.overrideWithValue(
          AccountStorage(store: FakeKeyValueStore()),
        ),
        notificationServiceProvider.overrideWithValue(
          _SilentNotificationService(),
        ),
        watchLinkProvider.overrideWithValue(_NoPhone()),
        isTranslationAvailableProvider.overrideWithValue(true),
        wearScreenShapeProvider.overrideWith((_) => WearScreenShape.round),
      ],
      child: TranslationProvider(child: const BSharpWearApp()),
    ),
  );
  await pumpWearUntil(tester, find.text('Use phone'));
}

Future<void> openWearDemo(WidgetTester tester, Size watchSizeDp) async {
  await pumpWearApp(tester, watchSizeDp);
  await tester.scrollUntilVisible(find.text('Demo mode'), 40);
  tester
      .widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Demo mode'),
          matching: find.byType(OutlinedButton),
        ),
      )
      .onPressed!();
  await pumpWearUntil(tester, find.text('Use phone'), isGone: true);
  await tester.pumpAndSettle();
}

Future<void> pumpWearUntil(
  WidgetTester tester,
  Finder finder, {
  bool isGone = false,
}) async {
  const attempts = 50;
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isEmpty == isGone) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  final shown = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .toList();
  fail('$finder never appeared; showing $shown');
}

void answerPhoneOpen(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('pl.brothware.bsharp/wear'),
    (call) async => true,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('pl.brothware.bsharp/wear'),
      null,
    ),
  );
}
