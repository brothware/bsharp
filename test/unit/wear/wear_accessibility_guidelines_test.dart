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
import 'package:bsharp/wear/screens/wear_home.dart';
import 'package:bsharp/wear/wear_app.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/credential_storage_test.dart';

const _watchSizeDp = Size(227, 227);
const _sections = [
  'Schedule',
  'Grades',
  'Attendance',
  'Tests',
  'Homework',
  'Messages',
  'Announcements',
  'Settings',
];

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
  Future<bool> hasPairedWatch() async => true;

  @override
  Future<bool> hasConnectedCounterpart() async => false;

  @override
  Future<void> sendAccount(AccountHandoff account) async {}

  @override
  Stream<AccountHandoff> get receivedAccounts => const Stream.empty();
}

Future<void> _openDemo(WidgetTester tester) async {
  tester.binding.defaultBinaryMessenger.setMockStreamHandler(
    const EventChannel('wear_os_scrollbar/rotary'),
    MockStreamHandler.inline(onListen: (_, _) {}),
  );
  tester.view.physicalSize = _watchSizeDp * 2;
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
  await _pumpUntil(tester, find.text('Use phone'));
  await tester.scrollUntilVisible(find.text('Demo mode'), 40);
  tester
      .widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Demo mode'),
          matching: find.byType(OutlinedButton),
        ),
      )
      .onPressed!();
  await _pumpUntil(tester, find.text('Use phone'), isGone: true);
  await tester.pumpAndSettle();
}

Future<void> _pumpUntil(
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

Future<void> _expectGuidelines(WidgetTester tester, String where) async {
  for (final (name, guideline) in [
    ('labelled tap targets', labeledTapTargetGuideline),
    ('text contrast', textContrastGuideline),
  ]) {
    await expectLater(
      tester,
      meetsGuideline(guideline),
      reason: '$where: $name',
    );
  }
  _expectTapTargetsAtLeast48dp(tester, where);
}

/// androidTapTargetGuideline measures what is on screen, after the clip of
/// the list and the shrink Wear's scaling lists give rows near the rim. A
/// target's own laid-out size is what WO-V2 asks about, so this measures that.
void _expectTapTargetsAtLeast48dp(WidgetTester tester, String where) {
  const minTargetDp = 48.0;
  final targets = find.byWidgetPredicate(
    (widget) => switch (widget) {
      InkResponse(:final onTap) => onTap != null,
      GestureDetector(:final onTap) => onTap != null,
      ButtonStyleButton(:final onPressed) => onPressed != null,
      IconButton(:final onPressed) => onPressed != null,
      _ => false,
    },
  );
  final tooSmall = [
    for (final element in targets.evaluate())
      if (tester.getSize(find.byElementPredicate((e) => e == element))
          case final size
          when size.width < minTargetDp || size.height < minTargetDp)
        '${element.widget.runtimeType} $size',
  ];
  expect(tooSmall, isEmpty, reason: '$where: targets under 48dp');
}

void main() {
  testWidgets('the dashboard meets the Android accessibility guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _openDemo(tester);

    await _expectGuidelines(tester, 'dashboard');
    handle.dispose();
  });

  for (final section in _sections) {
    testWidgets('$section meets the Android accessibility guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _openDemo(tester);
      final row = find.text(section);
      await tester.scrollUntilVisible(row, 60);
      tester
          .widget<InkWell>(
            find.ancestor(of: row.first, matching: find.byType(InkWell)).first,
          )
          .onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(WearHome), findsNothing, reason: '$section opened');

      await _expectGuidelines(tester, section);
      handle.dispose();
    });
  }
}
