import 'dart:async';

import 'package:bsharp/app/account_providers.dart';
import 'package:bsharp/app/auth_provider.dart';
import 'package:bsharp/app/data_provider_registry.dart';
import 'package:bsharp/core/error/result.dart';
import 'package:bsharp/data/data_sources/local/account_storage.dart';
import 'package:bsharp/data/data_sources/local/credential_storage.dart';
import 'package:bsharp/data/providers/demo/demo_data_provider.dart';
import 'package:bsharp/domain/entities/provider_account.dart';
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
  Future<Result<String?>> validateCredentials({
    required String school,
    required String login,
    required String passwordHash,
  }) async => const Result.failure(SchoolNotFound());
}

class _RejectingDataProvider extends DemoDataProvider {
  @override
  String get id => 'mobireg';

  @override
  bool get requiresCredentials => true;

  @override
  Future<Result<String?>> validateCredentials({
    required String school,
    required String login,
    required String passwordHash,
  }) async => const Result.failure(InvalidCredentials());
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
}) {
  final storage = CredentialStorage(store: FakeKeyValueStore());
  return ProviderScope(
    overrides: [
      credentialStorageProvider.overrideWithValue(storage),
      accountStorageProvider.overrideWithValue(
        accountStorage ?? AccountStorage(store: FakeKeyValueStore()),
      ),
      wearScreenShapeProvider.overrideWith((_) => shape),
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

/// Setup now opens on the provider step, so a test about the credential
/// steps has to choose a backend that wants credentials first.
Future<void> _chooseMobireg(WidgetTester tester) async {
  // The screen waits to learn whether an account is already saved before it
  // offers to add one, and the provider list is a step past that.
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add account'));
  await tester.pumpAndSettle();
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
            login: 'dsliwa',
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

      testWidgets('first run asks to add an account before naming one', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pumpAndSettle();

        expect(find.text('No accounts yet'), findsOneWidget);
        expect(
          find.text('Mobireg'),
          findsNothing,
          reason:
              'the phone asks to add an account first and only then which '
              'provider it is with',
        );

        await tester.tap(find.text('Add account'));
        await tester.pumpAndSettle();

        expect(find.text('Mobireg'), findsOneWidget);
        expect(find.text('Demo'), findsOneWidget);
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
        await tester.tap(find.text('Add account'));
        await tester.pumpAndSettle();

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

      testWidgets('the provider step lists every backend', (tester) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add account'));
        await tester.pumpAndSettle();

        expect(find.text('Mobireg'), findsOneWidget);
        expect(find.text('Demo'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('choosing a backend that needs credentials asks for them', (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(shape: shape));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add account'));
        await tester.pumpAndSettle();

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
}
