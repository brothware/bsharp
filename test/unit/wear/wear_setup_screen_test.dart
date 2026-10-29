import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/app/router.dart';
import 'package:bsharp/app/saved_passwords_provider.dart';
import 'package:bsharp/app/watch_link_provider.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/data/services/data_layer_watch_link.dart';
import 'package:bsharp/domain/entities/account_handoff.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
import 'package:bsharp/domain/entities/saved_login.dart';
import 'package:bsharp/domain/entities/student.dart';
import 'package:bsharp/domain/saved_passwords.dart';
import 'package:bsharp/domain/school_data_provider.dart';
import 'package:bsharp/domain/watch_link.dart';
import 'package:bsharp/wear/screens/wear_setup_screen.dart';
import 'package:bsharp/wear/wear_screen_shape_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/credential_storage_test.dart';

/// The longest failure the setup step can show: four lines on a 432px watch.
class _SchoolNotFoundDataProvider extends DemoDataProvider {
  @override
  String get id => 'mobireg';

  @override
  bool get requiresCredentials => true;

  @override
  Future<Result<AccountProbe>> probeAccount({
    required String school,
    required String login,
    required String password,
  }) async => const Result.failure(SchoolNotFound());
}

class _RejectingDataProvider extends DemoDataProvider {
  @override
  String get id => 'mobireg';

  @override
  bool get requiresCredentials => true;

  @override
  Future<Result<AccountProbe>> probeAccount({
    required String school,
    required String login,
    required String password,
  }) async => const Result.failure(InvalidCredentials());
}

class _CountingProbeDataProvider extends DemoDataProvider {
  int probes = 0;

  @override
  String get id => 'mobireg';

  @override
  bool get requiresCredentials => true;

  @override
  Future<Result<AccountProbe>> probeAccount({
    required String school,
    required String login,
    required String password,
  }) {
    probes++;
    return super.probeAccount(school: school, login: login, password: password);
  }
}

class _RecordingProbeDataProvider extends DemoDataProvider {
  final probed = <(String, String, String)>[];

  @override
  String get id => 'mobireg';

  @override
  bool get requiresCredentials => true;

  @override
  Future<Result<AccountProbe>> probeAccount({
    required String school,
    required String login,
    required String password,
  }) {
    probed.add((school, login, password));
    return super.probeAccount(school: school, login: login, password: password);
  }
}

class _SavedPasswords implements SavedPasswords {
  _SavedPasswords([this.pickResult = const NoSavedLogin()]) : fails = false;

  _SavedPasswords.failing() : pickResult = const NoSavedLogin(), fails = true;

  final SavedLoginPick pickResult;
  final bool fails;

  @override
  Future<void> offerToSave(SavedLogin login) async {}

  @override
  Future<SavedLoginPick> pick() async {
    if (fails) {
      throw const SavedPasswordsException('pick failed');
    }
    return pickResult;
  }
}

class _GatedProbeDataProvider extends DemoDataProvider {
  final probes = <Completer<Result<AccountProbe>>>[];

  @override
  String get id => 'mobireg';

  @override
  bool get requiresCredentials => true;

  @override
  Future<Result<AccountProbe>> probeAccount({
    required String school,
    required String login,
    required String password,
  }) {
    final probe = Completer<Result<AccountProbe>>();
    probes.add(probe);
    return probe.future;
  }

  void answerWithTwoStudents() => probes.last.complete(
    const Result.success(
      AccountProbe(
        schoolName: 'S',
        students: [
          Student(id: 1, name: 'Ada', surname: 'Nowak'),
          Student(id: 2, name: 'Jan', surname: 'Nowak'),
        ],
      ),
    ),
  );
}

class _PhoneLink implements WatchLink {
  final accounts = StreamController<AccountHandoff>.broadcast();

  @override
  Future<bool> hasPairedWatch() async => true;

  @override
  Future<bool> hasConnectedCounterpart() async => true;

  @override
  Future<bool> sendAccount(AccountHandoff account) async => true;

  @override
  Stream<AccountHandoff> get receivedAccounts => accounts.stream;
}

/// The school and login steps hand typing to the watch's own input screen, so
/// a test answers the channel instead of typing into the field. The password
/// step keeps a real field, and takes text directly.
Future<void> _typeIntoStep(WidgetTester tester, String text) async {
  final field = tester.widget<TextField>(find.byType(TextField));
  if (!field.readOnly) {
    await tester.enterText(find.byType(TextField), text);
    return;
  }

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('pl.brothware.bsharp/wear'),
    (call) async => call.method == 'requestTextInput' ? text : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('pl.brothware.bsharp/wear'),
      null,
    ),
  );

  await tester.tap(find.byType(TextField));
  await tester.pumpAndSettle();
}

Widget _buildApp({
  List<Object> extraOverrides = const [],
  WearScreenShape shape = WearScreenShape.rectangular,
  AccountStorage? accountStorage,
  bool addingAnother = false,
  WatchLink? watchLink,
  SavedPasswords? savedPasswords,
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      accountStorageProvider.overrideWithValue(
        accountStorage ?? AccountStorage(store: FakeKeyValueStore()),
      ),
      wearScreenShapeProvider.overrideWith((_) => shape),
      watchLinkProvider.overrideWithValue(watchLink ?? _PhoneLink()),
      savedPasswordsProvider.overrideWithValue(
        savedPasswords ?? _SavedPasswords(),
      ),
      ...extraOverrides.cast(),
    ],
    child: MaterialApp(
      home: WearSetupScreen(addingAnother: addingAnother),
    ),
  );
}

/// Reading the saved accounts is a real round trip on a watch, so the screen
/// has a frame or two to draw before it knows whether an account exists.
class _SlowAccountStorage extends AccountStorage {
  _SlowAccountStorage(this._accounts) : super(store: FakeKeyValueStore());

  final List<ProviderAccount> _accounts;
  final _read = Completer<void>();

  void reveal() => _read.complete();

  @override
  Future<List<ProviderAccount>> getAccounts() async {
    await _read.future;
    return _accounts;
  }
}

/// "Use phone" asks the watch host to open the phone app; a reachable phone
/// answers at once.
void _answerPhoneOpen(WidgetTester tester) {
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

/// Typing the account on the watch is the last resort, a link at the foot
/// of the welcome; a test reaches it through its handler, not a tap at the
/// rim of a round screen.
Future<void> _openTypedSetup(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Type it on the watch'), 40);
  tester
      .widget<TextButton>(
        find.ancestor(
          of: find.text('Type it on the watch'),
          matching: find.byType(TextButton),
        ),
      )
      .onPressed!();
  await tester.pumpAndSettle();
}

/// Setup now opens on the provider step, so a test about the credential
/// steps has to choose a backend that wants credentials first.
Future<void> _chooseMobireg(WidgetTester tester) async {
  // The screen waits to learn whether an account is already saved before it
  // offers to add one, and the provider list is a step past that.
  await _openTypedSetup(tester);
  await tester.tap(find.text('Mobireg'));
  await tester.pump();
}

void main() {
  for (final shape in WearScreenShape.values) {
    group('WearSetupScreen (${shape.name})', () {
      testWidgets('an account already saved never sees the provider step', (
        tester,
      ) async {
        final accountStorage = _SlowAccountStorage([
          const ProviderAccount(
            id: 'a',
            providerType: 'mobireg',
            slug: 'osm-wroclaw',
            login: 'parent.login',
            schoolName: 'School',
            students: [AccountStudent(id: 1, name: 'A', surname: 'B')],
          ),
        ]);

        await tester.pumpWidget(
          _buildApp(shape: shape, accountStorage: accountStorage),
        );
        await tester.pump();

        expect(
          find.text('Mobireg'),
          findsNothing,
          reason:
              'the backend is already chosen, so asking again is a step '
              'backwards - and it flashes up before the check finishes',
        );

        accountStorage.reveal();
        await tester.pumpAndSettle();

        expect(find.text('Mobireg'), findsNothing);
        expect(find.text('School'), findsWidgets);
      });

      testWidgets('an account saved without a password makes no login', (
        tester,
      ) async {
        final provider = _CountingProbeDataProvider();
        final accountStorage = _SlowAccountStorage([
          const ProviderAccount(
            id: 'a',
            providerType: 'mobireg',
            slug: 'osm-wroclaw',
            login: 'parent.login',
            schoolName: 'School',
          ),
        ]);

        await tester.pumpWidget(
          _buildApp(
            shape: shape,
            accountStorage: accountStorage,
            extraOverrides: [
              activeDataProviderProvider.overrideWithBuild(
                (ref, _) => provider,
              ),
            ],
          ),
        );
        accountStorage.reveal();
        await tester.pumpAndSettle();

        expect(provider.probes, 0);
      });

      testWidgets('first run asks to add an account before naming one', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pumpAndSettle();

        expect(find.text('No accounts yet'), findsOneWidget);
        expect(find.text('Demo mode'), findsOneWidget);
        expect(
          find.text('Mobireg'),
          findsNothing,
          reason:
              'the phone asks to add an account first and only then which '
              'provider it is with',
        );

        await _openTypedSetup(tester);

        expect(find.text('Mobireg'), findsOneWidget);
        expect(
          find.text('Demo mode'),
          findsNothing,
          reason:
              'demo is not a school you hold an account with, so it sits '
              'with the other way in rather than among the providers',
        );
      });

      testWidgets('adding another account starts at the provider list', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(shape: shape, addingAnother: true),
        );
        await tester.pumpAndSettle();

        expect(find.text('No accounts yet'), findsNothing);
        expect(find.text('Mobireg'), findsOneWidget);
      });

      testWidgets('the provider step spells out its own heading', (
        tester,
      ) async {
        // A real watch is 227dp across; the default test surface is far wider
        // and hides anything that only fails for want of room.
        tester.view.physicalSize = const Size(227, 227);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pumpAndSettle();
        await _openTypedSetup(tester);

        final heading = tester.renderObject<RenderParagraph>(
          find.text('Add account'),
        );

        expect(
          heading.didExceedMaxLines,
          isFalse,
          reason:
              'the header gives a label one line, and this one does not '
              'fit in it - it came out as "Choo..."',
        );
      });

      testWidgets('the provider step lists the backends with accounts', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pumpAndSettle();
        await _openTypedSetup(tester);

        expect(find.text('Mobireg'), findsOneWidget);
        expect(
          find.text('Demo'),
          findsNothing,
          reason:
              'demo needs no account, so it is offered beside Add account '
              'rather than among the schools you could have one with',
        );
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('choosing a backend that needs credentials asks for them', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pumpAndSettle();
        await _openTypedSetup(tester);

        await tester.tap(find.text('Mobireg'));
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('School'), findsWidgets);
      });

      testWidgets('the school step shows exactly one input', (tester) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('School'), findsWidgets);
      });

      testWidgets(
        'advancing from school to username carries the school value',
        (tester) async {
          await tester.pumpWidget(_buildApp(shape: shape));
          await tester.pump();
          await _chooseMobireg(tester);

          await _typeIntoStep(tester, 'osm-wroclaw');
          await tester.tap(find.byType(FilledButton));
          await tester.pump();

          expect(find.byType(TextField), findsOneWidget);
          expect(find.text('Username'), findsWidgets);

          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pump();

          expect(find.text('osm-wroclaw'), findsOneWidget);
        },
      );

      testWidgets('an empty field shows the fill-in-fields error', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(find.text('Fill in all fields'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('back from username returns to school without loss', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        await _typeIntoStep(tester, 'my-school');
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        await _typeIntoStep(tester, 'my-login');
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump();

        expect(find.text('my-school'), findsOneWidget);
      });

      testWidgets('the primary action is visible and at least 48dp', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        final size = tester.getSize(find.byType(FilledButton));
        expect(size.height, greaterThanOrEqualTo(48));
      });

      testWidgets('a login failure renders the mapped credentials message', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            shape: shape,
            extraOverrides: [
              activeDataProviderProvider.overrideWithBuild(
                (ref, _) => _RejectingDataProvider(),
              ),
            ],
          ),
        );
        await tester.pump();
        await _chooseMobireg(tester);

        await _typeIntoStep(tester, 'osm-wroclaw');
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        await _typeIntoStep(tester, 'baduser');
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        await _typeIntoStep(tester, 'badpass');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(find.text('Invalid credentials'), findsOneWidget);
      });

      testWidgets('the step title stays on one line', (tester) async {
        tester.view.physicalSize = const Size(454, 454);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        await _typeIntoStep(tester, 'osm-wroclaw');
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        final title = tester.widget<Text>(find.text('Username').first);
        expect(title.maxLines, 1);

        final painted = tester.renderObject<RenderBox>(
          find.text('Username').first,
        );
        expect(
          painted.size.height,
          lessThan(32),
          reason: 'the step title wrapped onto a second line',
        );
      });

      testWidgets('the back button clears the step indicator', (tester) async {
        tester.view.physicalSize = const Size(454, 454);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        await _typeIntoStep(tester, 'osm-wroclaw');
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        final back = tester.getRect(find.byIcon(Icons.arrow_back));
        final indicator = tester.getRect(find.text('2/3'));
        expect(
          back.overlaps(indicator),
          isFalse,
          reason: 'the back button is drawn over the step indicator',
        );
      });

      testWidgets('the field does not steal focus on open', (tester) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.autofocus, isFalse);
      });
      testWidgets('revealing the password closes the keyboard first', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        await _typeIntoStep(tester, 'osm-wroclaw');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await _typeIntoStep(tester, 'parent');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        final hidden = tester.widget<TextField>(find.byType(TextField));
        expect(hidden.obscureText, isTrue);
        expect(hidden.focusNode!.hasFocus, isTrue);

        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pumpAndSettle();

        final revealed = tester.widget<TextField>(find.byType(TextField));
        expect(revealed.obscureText, isFalse);
        expect(
          revealed.focusNode!.hasFocus,
          isFalse,
          reason:
              'the watch keyboard fills the screen and prints what it is '
              'given above the keys, so revealing while it is open puts the '
              'password on the whole display',
        );
      });
      testWidgets('a long failure never pushes the button off the step', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(432, 432);
        tester.view.devicePixelRatio = 2.125;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildApp(
            shape: shape,
            extraOverrides: [
              activeDataProviderProvider.overrideWithBuild(
                (ref, _) => _SchoolNotFoundDataProvider(),
              ),
            ],
          ),
        );
        await tester.pump();
        await _chooseMobireg(tester);

        await _typeIntoStep(tester, 'osm-wroclaw');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await _typeIntoStep(tester, 'parent');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await _typeIntoStep(tester, 'wrong');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final button = tester.getRect(find.byType(FilledButton));
        expect(
          button.bottom,
          lessThanOrEqualTo(tester.view.physicalSize.height / 2.125),
          reason:
              'the failure text grew the step until the button fell off the '
              'bottom of the watch, with no way to dismiss it',
        );
      });
      testWidgets('the school step takes text from the watch input screen', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(
          field.readOnly,
          isTrue,
          reason:
              'the watch keyboard stops refreshing its copy of the text after '
              'the first letter, so the wearer would be typing blind',
        );

        await _typeIntoStep(tester, 'osm-wroclaw');

        expect(find.text('osm-wroclaw'), findsOneWidget);
      });

      testWidgets('the password step keeps its own masked field', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pump();
        await _chooseMobireg(tester);

        await _typeIntoStep(tester, 'osm-wroclaw');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
        await _typeIntoStep(tester, 'parent');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.obscureText, isTrue);
        expect(
          field.readOnly,
          isFalse,
          reason:
              'the watch input screen shows what it is given, and on a watch '
              'that is the whole display',
        );
      });
    });
  }

  group('leaving setup (WO-V3)', () {
    Future<void> swipeRight(WidgetTester tester) async {
      await tester.dragFrom(const Offset(5, 200), const Offset(300, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('a swipe on a credential step goes back one step', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await _chooseMobireg(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await swipeRight(tester);

      expect(find.text('Mobireg'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a swipe on the provider list returns to the welcome', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      await _openTypedSetup(tester);

      await swipeRight(tester);

      expect(find.text('No accounts yet'), findsOneWidget);
    });

    testWidgets('back on a credential step goes back one step', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await _chooseMobireg(tester);
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        find.text('Mobireg'),
        findsOneWidget,
        reason: 'back on the first credential step closed the whole app',
      );
    });

    testWidgets('a swipe on the welcome closes the app', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await swipeRight(tester);

      expect(calls, contains('SystemNavigator.pop'));
    });

    testWidgets('a swipe on adding another account closes setup', (
      tester,
    ) async {
      final storage = CredentialStorage(store: FakeKeyValueStore());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            credentialStorageProvider.overrideWithValue(storage),
            accountStorageProvider.overrideWithValue(
              AccountStorage(store: FakeKeyValueStore()),
            ),
            wearScreenShapeProvider.overrideWith(
              (_) => WearScreenShape.rectangular,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WearSetupScreen(addingAnother: true),
                  ),
                ),
                child: const Text('settings'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('settings'));
      await tester.pumpAndSettle();
      expect(find.text('Mobireg'), findsOneWidget);

      await swipeRight(tester);

      expect(find.text('settings'), findsOneWidget);
      expect(find.byType(WearSetupScreen), findsNothing);
    });
  });

  group('signing in from the phone', () {
    late _PhoneLink link;
    late _RecordingProbeDataProvider provider;

    setUp(() {
      link = _PhoneLink();
      provider = _RecordingProbeDataProvider();
    });

    tearDown(() => link.accounts.close());

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> openUsePhone(WidgetTester tester) async {
      if (tester.binding.defaultBinaryMessenger.checkMockMessageHandler(
        'pl.brothware.bsharp/wear',
        null,
      )) {
        _answerPhoneOpen(tester);
      }
      await tester.pumpWidget(
        _buildApp(
          watchLink: link,
          extraOverrides: [
            activeDataProviderProvider.overrideWithBuild((ref, _) => provider),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use phone'));
      await settle(tester);
    }

    testWidgets('Use phone opens Set up watch on the phone', (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('pl.brothware.bsharp/wear'),
        (call) async {
          calls.add(call);
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('pl.brothware.bsharp/wear'),
          null,
        ),
      );

      await openUsePhone(tester);

      expect(calls.single.method, 'openOnPhone');
      expect(calls.single.arguments, {'url': watchSetupLink});
    });

    testWidgets('a phone that cannot be reached is named, not waited on', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('pl.brothware.bsharp/wear'),
        (call) async => throw PlatformException(code: 'phone_unreachable'),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('pl.brothware.bsharp/wear'),
          null,
        ),
      );

      await openUsePhone(tester);
      await settle(tester);

      expect(
        find.text(
          'Your phone did not answer. Keep it near, or use Saved password.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a phone that never answers is named after a while', (
      tester,
    ) async {
      final never = Completer<Object?>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('pl.brothware.bsharp/wear'),
        (call) => never.future,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('pl.brothware.bsharp/wear'),
          null,
        ),
      );

      await openUsePhone(tester);
      await tester.pump(const Duration(seconds: 11));
      await settle(tester);

      expect(
        find.text(
          'Your phone did not answer. Keep it near, or use Saved password.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the watch says where to go on the phone', (tester) async {
      await openUsePhone(tester);

      expect(
        find.text(
          'On the phone, open BSharp, then Settings, then Set up watch',
        ),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('an account sent from the phone signs the watch in', (
      tester,
    ) async {
      await openUsePhone(tester);

      link.accounts.add(
        const AccountHandoff(
          providerType: 'mobireg',
          school: 'osm-wroclaw',
          login: 'parent',
          password: 'secret',
        ),
      );
      await settle(tester);

      expect(provider.probed, [('osm-wroclaw', 'parent', 'secret')]);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('an account from a newer phone app asks for an update', (
      tester,
    ) async {
      await openUsePhone(tester);

      link.accounts.addError(const UnsupportedHandoffVersion(2));
      await settle(tester);

      expect(
        find.text('Update BSharp on both devices to use this account'),
        findsOneWidget,
      );
      expect(provider.probed, isEmpty);
    });

    testWidgets('an unreadable account says so and keeps waiting', (
      tester,
    ) async {
      await openUsePhone(tester);

      link.accounts.addError(const FormatException('no "password"'));
      await settle(tester);

      expect(
        find.text('Could not read the account from the phone'),
        findsOneWidget,
      );
      link.accounts.add(
        const AccountHandoff(
          providerType: 'mobireg',
          school: 'osm-wroclaw',
          login: 'parent',
          password: 'secret',
        ),
      );
      await settle(tester);

      expect(provider.probed, hasLength(1));
    });

    testWidgets('a swipe leaves the phone step for the welcome', (
      tester,
    ) async {
      await openUsePhone(tester);

      await tester.dragFrom(const Offset(5, 200), const Offset(300, 0));
      await settle(tester);

      expect(find.text('No accounts yet'), findsOneWidget);
    });
  });

  group('signing in with a saved password', () {
    Future<_RecordingProbeDataProvider> openWelcome(
      WidgetTester tester,
      SavedPasswords passwords,
    ) async {
      final provider = _RecordingProbeDataProvider();
      await tester.pumpWidget(
        _buildApp(
          savedPasswords: passwords,
          extraOverrides: [
            activeDataProviderProvider.overrideWithBuild((ref, _) => provider),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return provider;
    }

    Future<void> tapSavedPassword(WidgetTester tester) async {
      await tester.scrollUntilVisible(find.text('Saved password'), 40);
      await tester.tap(find.text('Saved password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('the welcome offers no keyboard but a last-resort link', (
      tester,
    ) async {
      await openWelcome(tester, _SavedPasswords());

      expect(find.text('Use phone'), findsOneWidget);
      expect(find.text('Saved password'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(
        find.ancestor(
          of: find.text('Type it on the watch'),
          matching: find.byType(TextButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a saved password signs the watch in', (tester) async {
      final provider = await openWelcome(
        tester,
        _SavedPasswords(
          const SavedLoginPicked(
            SavedLogin(
              school: 'osm-wroclaw',
              login: 'parent',
              password: 'secret',
            ),
          ),
        ),
      );

      await tapSavedPassword(tester);

      expect(provider.probed, [('osm-wroclaw', 'parent', 'secret')]);
    });

    testWidgets('with nothing saved the watch says so', (tester) async {
      final provider = await openWelcome(tester, _SavedPasswords());

      await tapSavedPassword(tester);

      expect(
        find.text('No BSharp password is saved in your Google account'),
        findsOneWidget,
      );
      expect(provider.probed, isEmpty);
    });

    testWidgets('a cancelled pick leaves the welcome as it was', (
      tester,
    ) async {
      final provider = await openWelcome(
        tester,
        _SavedPasswords(const SavedLoginCancelled()),
      );

      await tapSavedPassword(tester);

      expect(find.text('No accounts yet'), findsOneWidget);
      expect(provider.probed, isEmpty);
    });

    testWidgets('a failed pick says so', (tester) async {
      await openWelcome(tester, _SavedPasswords.failing());

      await tapSavedPassword(tester);

      expect(find.text('Could not use the saved password'), findsOneWidget);
    });
  });

  group('one sign-in at a time', () {
    late _PhoneLink link;
    late _GatedProbeDataProvider provider;
    const account = AccountHandoff(
      providerType: 'mobireg',
      school: 'osm-wroclaw',
      login: 'parent',
      password: 'secret',
    );

    setUp(() {
      link = _PhoneLink();
      provider = _GatedProbeDataProvider();
    });

    tearDown(() => link.accounts.close());

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> waitForPhone(WidgetTester tester) async {
      _answerPhoneOpen(tester);
      await tester.pumpWidget(
        _buildApp(
          watchLink: link,
          extraOverrides: [
            activeDataProviderProvider.overrideWithBuild((ref, _) => provider),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use phone'));
      await settle(tester);
    }

    testWidgets('back from the student list returns to the phone step', (
      tester,
    ) async {
      await waitForPhone(tester);
      link.accounts.add(account);
      await settle(tester);
      provider.answerWithTwoStudents();
      await settle(tester);
      expect(find.text('Ada Nowak'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester);

      expect(
        find.text('Use your phone'),
        findsOneWidget,
        reason: 'the arrow went to the password step of a typed login',
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a probe that answers after backing out is dropped', (
      tester,
    ) async {
      await waitForPhone(tester);
      link.accounts.add(account);
      await settle(tester);

      await tester.dragFrom(const Offset(5, 200), const Offset(300, 0));
      await settle(tester);
      provider.answerWithTwoStudents();
      await settle(tester);

      expect(find.text('No accounts yet'), findsOneWidget);
      expect(find.text('Ada Nowak'), findsNothing);
    });

    testWidgets('a second send while signing in is ignored', (tester) async {
      await waitForPhone(tester);
      link.accounts.add(account);
      await settle(tester);
      provider.answerWithTwoStudents();
      await settle(tester);

      link.accounts.add(account);
      await settle(tester);

      expect(provider.probes, hasLength(1));
      expect(find.text('Ada Nowak'), findsOneWidget);
    });
  });
}
